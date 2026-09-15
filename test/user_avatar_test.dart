import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
