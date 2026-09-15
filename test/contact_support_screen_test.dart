import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'support/pump_app.dart';

/// A [UrlLauncherPlatform] test double — there's no real email app to
/// launch in a widget test, so this stands in for whatever the OS would
/// normally do, either succeeding or failing on command.
class _FakeUrlLauncher extends UrlLauncherPlatform {
  _FakeUrlLauncher({required this.shouldSucceed});

  final bool shouldSucceed;
  String? lastLaunchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return shouldSucceed;
  }
}

void main() {
  Future<void> openContactSupport(WidgetTester tester) async {
    await pumpApp(tester);
    await loginWithDemoAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Contact support'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();
  }

  testWidgets('requires a description before it will do anything', (
    tester,
  ) async {
    await openContactSupport(tester);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tell us a bit more about what happened.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a successful send opens the email app with the real category and '
    "description, never claiming the message was actually delivered",
    (tester) async {
      final fake = _FakeUrlLauncher(shouldSucceed: true);
      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = original);

      await openContactSupport(tester);

      await tester.enterText(
        find.byType(TextField),
        'My statement upload keeps failing.',
      );
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(fake.lastLaunchedUrl, contains('mailto:support@finassist.com'));
      expect(
        fake.lastLaunchedUrl,
        contains('statement%20upload%20keeps%20failing'),
      );
      expect(
        find.text('Opening your email app so you can send this to us.'),
        findsOneWidget,
      );
      // Never the language of an actually-delivered message.
      expect(find.text('Your message has been sent.'), findsNothing);
    },
  );

  testWidgets("when the device can't open an email app, this says so honestly "
      'instead of showing a false success', (tester) async {
    final fake = _FakeUrlLauncher(shouldSucceed: false);
    final original = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = fake;
    addTearDown(() => UrlLauncherPlatform.instance = original);

    await openContactSupport(tester);

    await tester.enterText(find.byType(TextField), 'Need some help.');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't open your email app. Please try again."),
      findsOneWidget,
    );
  });
}
