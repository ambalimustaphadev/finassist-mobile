import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/features/chat/data/models/chat_message.dart';
import 'package:finassist/shared/models/uploaded_file_attachment.dart';

void main() {
  test('a message with a file attachment round-trips through toJson/fromJson '
      'so an offline-restored conversation keeps a tappable document '
      'reference', () {
    final original = ChatMessage(
      id: 'user-1',
      role: ChatMessageRole.user,
      text: 'Summarize this statement.',
      timestamp: DateTime(2026, 1, 1, 10, 30),
      conversationId: '1',
      fileAttachment: UploadedFileAttachment(
        fileName: 'August Statement.pdf',
        extension: 'pdf',
        fileUrl: 'https://pub-test.r2.dev/statement/4/uuid.pdf',
        contentType: 'application/pdf',
      ),
    );

    final restored = ChatMessage.fromJson(original.toJson());

    expect(restored.text, 'Summarize this statement.');
    expect(restored.fileAttachment, isNotNull);
    expect(restored.fileAttachment!.fileName, 'August Statement.pdf');
    expect(
      restored.fileAttachment!.fileUrl,
      'https://pub-test.r2.dev/statement/4/uuid.pdf',
    );
    expect(restored.fileAttachment!.contentType, 'application/pdf');
  });

  test('a plain text message has no fileAttachment after round-tripping', () {
    final original = ChatMessage(
      id: 'user-2',
      role: ChatMessageRole.user,
      text: 'How much did I spend on food?',
      timestamp: DateTime(2026, 1, 1),
    );

    final restored = ChatMessage.fromJson(original.toJson());

    expect(restored.fileAttachment, isNull);
    expect(restored.text, 'How much did I spend on food?');
  });
}
