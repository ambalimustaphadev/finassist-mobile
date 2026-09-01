import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/shared/widgets/document_viewer_screen.dart';

void main() {
  Future<void> pumpViewer(
    WidgetTester tester, {
    String? fileUrl,
    String filename = 'statement.pdf',
    String? contentType,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: DocumentViewerScreen(
          fileUrl: fileUrl,
          filename: filename,
          contentType: contentType,
        ),
      ),
    );
  }

  testWidgets('a missing file_url shows a friendly error, not a crash', (
    tester,
  ) async {
    await pumpViewer(tester, fileUrl: null);
    await tester.pump();

    expect(find.text("This document can't be opened"), findsOneWidget);
    expect(find.text('Its link is missing or invalid.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an invalid (empty) file_url shows the same friendly error', (
    tester,
  ) async {
    await pumpViewer(tester, fileUrl: '');
    await tester.pump();

    expect(find.text("This document can't be opened"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an unsupported file type offers "Open externally" instead of a crash',
    (tester) async {
      await pumpViewer(
        tester,
        fileUrl: 'https://pub-test.r2.dev/statement/1/report.csv',
        filename: 'report.csv',
      );
      await tester.pump();

      expect(find.text("Can't preview this file type"), findsOneWidget);
      expect(find.text('Open externally'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The "Open externally" affordance is the visible secondary action
      // in the AppBar too, but never the automatic behavior.
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    },
  );

  testWidgets('a PDF stays inside the app (no external launch) and shows the '
      'filename as its title', (tester) async {
    await pumpViewer(
      tester,
      fileUrl: 'https://pub-test.r2.dev/statement/1/GTBank_Statement.pdf',
      filename: 'GTBank_Statement.pdf',
      contentType: 'application/pdf',
    );
    await tester.pump();

    // Still inside FinAssist's own Scaffold/AppBar — never navigated
    // away to a browser.
    expect(find.byType(DocumentViewerScreen), findsOneWidget);
    expect(find.text('GTBank_Statement.pdf'), findsOneWidget);
    // The secondary "open externally" action is available but distinct
    // from the default in-app behavior.
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
  });

  testWidgets(
    'a network failure while loading a PDF shows a useful error, not a '
    'crash — test binding blocks real HTTP, so this exercises the real '
    'failure path',
    (tester) async {
      await pumpViewer(
        tester,
        fileUrl: 'https://pub-test.r2.dev/statement/1/GTBank_Statement.pdf',
        filename: 'GTBank_Statement.pdf',
        contentType: 'application/pdf',
      );
      // Let the (blocked-by-the-test-binding) network request resolve to
      // its failure state.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text("Couldn't open this document"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an image stays inside the app and shows its filename', (
    tester,
  ) async {
    await pumpViewer(
      tester,
      fileUrl: 'https://pub-test.r2.dev/statement/1/receipt.png',
      filename: 'receipt.png',
      contentType: 'image/png',
    );
    await tester.pump();

    expect(find.byType(DocumentViewerScreen), findsOneWidget);
    expect(find.text('receipt.png'), findsOneWidget);
  });
}
