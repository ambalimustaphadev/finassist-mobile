import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/app/theme/app_theme.dart';
import 'package:finassist/shared/widgets/user_avatar.dart';

void main() {
  testWidgets(
    'a profile image that fails to load (e.g. an expired signed URL) shows '
    'the fallback icon and reports the failure via onImageError, rather '
    'than crashing or showing a broken-image state',
    (tester) async {
      var errorCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: UserAvatar(
            imageUrl: 'https://pub-test.r2.dev/signed/expired.jpg',
            onImageError: () => errorCalls++,
          ),
        ),
      );

      // The test binding blocks real network access, so this exercises the
      // real failure path — same technique already used for
      // `DocumentViewerScreen`'s network-failure test.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(errorCalls, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'UserAvatar keys its Image.network by the URL itself, so a new '
    'profile_picture_url (e.g. right after an upload) always forces a '
    'fresh image element instead of reusing whatever the previous URL '
    'had already resolved/cached',
    (tester) async {
      const urlA = 'https://pub-test.r2.dev/signed/a.jpg';
      const urlB = 'https://pub-test.r2.dev/signed/b.jpg';

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const UserAvatar(imageUrl: urlA)),
      );
      await tester.pump();

      final imageFinderA = find.byType(Image);
      expect(imageFinderA, findsOneWidget);
      expect(
        tester.widget<Image>(imageFinderA).key,
        const ValueKey<String?>(urlA),
      );

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const UserAvatar(imageUrl: urlB)),
      );
      await tester.pump();

      final imageFinderB = find.byType(Image);
      expect(imageFinderB, findsOneWidget);
      expect(
        tester.widget<Image>(imageFinderB).key,
        const ValueKey<String?>(urlB),
      );
    },
  );

  testWidgets(
    'no profile_picture_url and no local imagePath falls back to the '
    'plain person icon, never a broken-image state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const UserAvatar()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );
}
