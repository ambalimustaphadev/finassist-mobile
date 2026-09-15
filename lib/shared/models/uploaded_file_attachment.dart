import '../../core/extensions/formatting_extensions.dart';

/// A file the user attached to the chat (e.g. a bank statement). Display
/// fields are precomputed once here rather than re-derived in widgets.
class UploadedFileAttachment {
  UploadedFileAttachment({
    required this.fileName,
    String? extension,
    int? sizeBytes,
    this.fileId,
    this.contentType,
  }) : extensionLabel = (extension ?? _inferExtension(fileName)).toUpperCase(),
       sizeLabel = formatFileSize(sizeBytes);

  final String fileName;
  final String extensionLabel;
  final String sizeLabel;

  /// The document's permanent identity on the backend — private in
  /// Cloudflare R2, never exposed as a permanent/public URL. Null only
  /// for the composer's local "picked but not yet uploaded" preview,
  /// which predates the file existing on the server and isn't tappable
  /// yet. Once set, this is what's sent to `/api/chat` and what's used
  /// to request a fresh, short-lived view URL from
  /// `GET /api/files/<fileId>/view` immediately before opening the
  /// shared in-app document viewer — never stored as a URL here.
  final int? fileId;

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
