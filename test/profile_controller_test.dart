import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/features/profile/data/models/profile.dart';
import 'package:finassist/features/profile/data/repositories/profile_repository.dart';
import 'package:finassist/features/profile/presentation/providers/profile_controller.dart';

/// A controllable [ProfileRepository] test double — [getProfile] and
/// [uploadProfilePicture] both return whatever [profile] currently holds
/// (settable mid-test via [setProfile]), so a test can simulate the
/// backend handing back a fresh signed URL on a later call without
/// pretending to touch a real network or a real file.
class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  Profile profile;
  int getProfileCallCount = 0;
  int uploadCallCount = 0;
  Object? uploadError;

  /// The next N calls to [getProfile] throw this instead of returning
  /// [profile] — lets a test simulate a transient failure (or a run of
  /// them) on the initial load without touching real HTTP.
  Object? getProfileError;
  int remainingGetProfileFailures = 0;

  void setProfile(Profile next) => profile = next;

  @override
  Future<Profile> getProfile() async {
    getProfileCallCount++;
    if (remainingGetProfileFailures > 0) {
      remainingGetProfileFailures--;
      throw getProfileError!;
    }
    return profile;
  }

  @override
  Future<Profile> updateProfile(Map<String, dynamic> changes) async => profile;

  @override
  Future<Profile> uploadProfilePicture(File file) async {
    uploadCallCount++;
    if (uploadError != null) throw uploadError!;
    return profile;
  }
}

Profile _profile({String? pictureUrl}) {
  final now = DateTime(2026, 1, 1);
  return Profile(
    id: 1,
    username: 'mustapha',
    firstName: 'Mustapha',
    lastName: 'Ambali',
    email: 'demo@finassist.com',
    currency: 'NGN',
    onboardingCompleted: true,
    createdAt: now,
    updatedAt: now,
    profilePictureUrl: pictureUrl,
  );
}

Future<void> _waitUntil(bool Function() condition, {int maxTries = 100}) async {
  for (var i = 0; i < maxTries; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test(
    'a successful profile-picture upload updates profile state from the '
    "backend's own response — never a URL Flutter constructs itself",
    () async {
      final repo = _FakeProfileRepository(
        _profile(pictureUrl: 'https://signed.example/old.jpg'),
      );
      final controller = ProfileController(repo, 'user-1');
      await _waitUntil(
        () => controller.state.status == ProfileLoadStatus.loaded,
      );

      repo.setProfile(_profile(pictureUrl: 'https://signed.example/new.jpg'));
      final ok = await controller.uploadProfilePicture(
        File('/tmp/does-not-need-to-exist.jpg'),
      );

      expect(ok, isTrue);
      expect(
        controller.state.profile?.profilePictureUrl,
        'https://signed.example/new.jpg',
      );
      expect(controller.state.isUploadingPicture, isFalse);
      expect(controller.state.pictureError, isNull);
    },
  );

  test('refresh() replaces an old temporary signed URL with a freshly fetched '
      'one', () async {
    final repo = _FakeProfileRepository(
      _profile(pictureUrl: 'https://signed.example/v1.jpg'),
    );
    final controller = ProfileController(repo, 'user-1');
    await _waitUntil(() => controller.state.status == ProfileLoadStatus.loaded);
    expect(
      controller.state.profile?.profilePictureUrl,
      'https://signed.example/v1.jpg',
    );

    repo.setProfile(_profile(pictureUrl: 'https://signed.example/v2.jpg'));
    await controller.refresh();

    expect(
      controller.state.profile?.profilePictureUrl,
      'https://signed.example/v2.jpg',
    );
  });

  test('refreshIfPictureUrlStale refreshes exactly once for a given expired '
      'URL, never a second time for that same URL — no retry loop', () async {
    final repo = _FakeProfileRepository(
      _profile(pictureUrl: 'https://signed.example/expired.jpg'),
    );
    final controller = ProfileController(repo, 'user-1');
    await _waitUntil(() => controller.state.status == ProfileLoadStatus.loaded);
    expect(repo.getProfileCallCount, 1);

    repo.setProfile(_profile(pictureUrl: 'https://signed.example/fresh.jpg'));
    await controller.refreshIfPictureUrlStale(
      'https://signed.example/expired.jpg',
    );

    expect(
      controller.state.profile?.profilePictureUrl,
      'https://signed.example/fresh.jpg',
    );
    expect(repo.getProfileCallCount, 2);

    // Reporting the exact same failing URL again must not trigger
    // another refresh.
    await controller.refreshIfPictureUrlStale(
      'https://signed.example/expired.jpg',
    );
    expect(repo.getProfileCallCount, 2);
  });

  test(
    'refreshIfPictureUrlStale is a no-op when the reported URL no longer '
    "matches the profile's current picture (already superseded elsewhere)",
    () async {
      final repo = _FakeProfileRepository(
        _profile(pictureUrl: 'https://signed.example/current.jpg'),
      );
      final controller = ProfileController(repo, 'user-1');
      await _waitUntil(
        () => controller.state.status == ProfileLoadStatus.loaded,
      );

      await controller.refreshIfPictureUrlStale(
        'https://signed.example/some-other-stale-url.jpg',
      );

      // Only the initial load happened — nothing extra.
      expect(repo.getProfileCallCount, 1);
    },
  );

  test('a null profile_picture_url is a normal, supported state', () async {
    final repo = _FakeProfileRepository(_profile());
    final controller = ProfileController(repo, 'user-1');
    await _waitUntil(() => controller.state.status == ProfileLoadStatus.loaded);

    expect(controller.state.profile?.profilePictureUrl, isNull);
  });

  test('a failed upload surfaces pictureError and leaves the previous profile '
      'picture in place — the failed attempt is never assumed to have '
      'succeeded', () async {
    final repo = _FakeProfileRepository(
      _profile(pictureUrl: 'https://signed.example/current.jpg'),
    )..uploadError = const ApiException('upload failed');
    final controller = ProfileController(repo, 'user-1');
    await _waitUntil(() => controller.state.status == ProfileLoadStatus.loaded);

    final ok = await controller.uploadProfilePicture(
      File('/tmp/does-not-need-to-exist.jpg'),
    );

    expect(ok, isFalse);
    expect(controller.state.pictureError, isNotNull);
    expect(
      controller.state.profile?.profilePictureUrl,
      'https://signed.example/current.jpg',
    );
  });

  test('first name, last name, username and email are all available '
      'immediately after the initial load succeeds — no profile-picture '
      'upload required', () async {
    final repo = _FakeProfileRepository(_profile());
    final controller = ProfileController(repo, 'user-1');
    await _waitUntil(() => controller.state.status == ProfileLoadStatus.loaded);

    expect(repo.uploadCallCount, 0);
    final profile = controller.state.profile;
    expect(profile, isNotNull);
    expect(profile!.firstName, 'Mustapha');
    expect(profile.lastName, 'Ambali');
    expect(profile.username, 'mustapha');
    expect(profile.email, 'demo@finassist.com');
  });

  test(
    'a transient failure on the very first load is recovered by exactly '
    'one automatic, immediate retry — identity data still loads '
    'deterministically rather than staying stuck missing until an '
    'unrelated action (like a picture upload) happens to refresh it',
    () async {
      final repo = _FakeProfileRepository(_profile())
        ..getProfileError = const ApiException('temporary hiccup')
        ..remainingGetProfileFailures = 1;
      final controller = ProfileController(repo, 'user-1');

      await _waitUntil(
        () => controller.state.status == ProfileLoadStatus.loaded,
      );

      expect(repo.getProfileCallCount, 2);
      expect(controller.state.profile?.firstName, 'Mustapha');
      expect(controller.state.loadError, isNull);
    },
  );

  test('a failure that persists through the one automatic retry resolves to '
      'a terminal error state — never stuck at "loading" forever, and never '
      'retried a third time (bounded, not a loop)', () async {
    final repo = _FakeProfileRepository(_profile())
      ..getProfileError = const ApiException("Couldn't connect.")
      ..remainingGetProfileFailures = 10;
    final controller = ProfileController(repo, 'user-1');

    await _waitUntil(() => controller.state.status == ProfileLoadStatus.error);

    // Exactly initial + one retry — not more.
    expect(repo.getProfileCallCount, 2);
    expect(controller.state.status, ProfileLoadStatus.error);
    expect(controller.state.loadError, "Couldn't connect.");
    expect(controller.state.profile, isNull);
  });

  test('a non-ApiException failure (e.g. a malformed response) also resolves '
      'deterministically to the error state instead of leaving status stuck '
      'at "loading" forever', () async {
    final repo = _FakeProfileRepository(_profile())
      ..getProfileError = FormatException('unexpected field shape')
      ..remainingGetProfileFailures = 10;
    final controller = ProfileController(repo, 'user-1');

    await _waitUntil(() => controller.state.status == ProfileLoadStatus.error);

    expect(repo.getProfileCallCount, 2);
    expect(controller.state.status, ProfileLoadStatus.error);
    expect(controller.state.loadError, isNotNull);
  });

  test(
    'a later, genuinely new failure (after an earlier successful load) '
    'still gets its own single retry — the retry guard resets on success, '
    'it does not permanently disable retries for the whole session',
    () async {
      final repo = _FakeProfileRepository(_profile());
      final controller = ProfileController(repo, 'user-1');
      await _waitUntil(
        () => controller.state.status == ProfileLoadStatus.loaded,
      );
      expect(repo.getProfileCallCount, 1);

      repo.getProfileError = const ApiException('a later transient hiccup');
      repo.remainingGetProfileFailures = 1;
      await controller.refresh();

      expect(controller.state.status, ProfileLoadStatus.loaded);
      expect(repo.getProfileCallCount, 3);
    },
  );
}
