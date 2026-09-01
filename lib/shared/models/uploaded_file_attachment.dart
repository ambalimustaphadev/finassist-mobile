import '../../core/extensions/formatting_extensions.dart';

/// A file the user attached to the chat (e.g. a bank statement). Display
/// fields are precomputed once here rather than re-derived in widgets.
class UploadedFileAttachment {
  UploadedFileAttachment({
    required this.fileName,
    String? extension,
    int? sizeBytes,
    this.fileUrl,
    this.contentType,
  }) : extensionLabel = (extension ?? _inferExtension(fileName)).toUpperCase(),
       sizeLabel = formatFileSize(sizeBytes);

  final String fileName;
  final String extensionLabel;
  final String sizeLabel;

  /// The R2-accessible URL of the actual uploaded document, once it's
  /// been sent to the backend — null only for the legacy "picked but not
  /// yet uploaded" attachment message, which predates this field and
  /// isn't tappable. Present, this is what the shared in-app document
  /// viewer opens.
  final String? fileUrl;

  /// The backend's reported MIME type, when known — lets the document
  /// viewer choose a PDF/image renderer without guessing from the
  /// filename alone.
  final String? contentType;

  static String _inferExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1);
  }
}
