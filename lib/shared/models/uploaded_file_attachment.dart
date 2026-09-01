import '../../core/extensions/formatting_extensions.dart';

/// A file the user attached to the chat (e.g. a bank statement). Display
/// fields are precomputed once here rather than re-derived in widgets.
class UploadedFileAttachment {
  UploadedFileAttachment({
    required this.fileName,
    String? extension,
    int? sizeBytes,
  }) : extensionLabel = (extension ?? _inferExtension(fileName)).toUpperCase(),
       sizeLabel = formatFileSize(sizeBytes);

  final String fileName;
  final String extensionLabel;
  final String sizeLabel;

  static String _inferExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1);
  }
}
