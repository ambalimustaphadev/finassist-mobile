/// The backend's record of a file uploaded via `POST /api/files/upload` —
/// mirrors the safe metadata shape of the `file` object in its JSON
/// response. Financial documents are private in Cloudflare R2: the
/// backend no longer returns a permanent/public URL (or its R2 [key])
/// here at all — [id] is the document's only identity Flutter ever
/// carries. Viewing it later means asking `GET /api/files/<id>/view` for
/// a fresh, short-lived signed URL, not reusing anything from this model.
class UploadedFile {
  const UploadedFile({
    required this.id,
    required this.filename,
    required this.size,
    required this.contentType,
    this.documentType,
    this.processingStatus,
    this.createdAt,
  });

  final int id;
  final String filename;
  final int size;
  final String contentType;

  /// The backend's classification of the document (e.g. `bank_statement`),
  /// when it reports one. Purely informational today — nothing in Flutter
  /// branches on it yet.
  final String? documentType;

  /// The backend's processing/analysis status for this document, when it
  /// reports one (e.g. `pending`, `processed`). Purely informational
  /// today.
  final String? processingStatus;

  final DateTime? createdAt;

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      filename: (json['filename'] ?? '').toString(),
      size: json['size'] is int
          ? json['size'] as int
          : int.tryParse(json['size'].toString()) ?? 0,
      contentType: (json['content_type'] ?? '').toString(),
      documentType: json['document_type'] as String?,
      processingStatus: json['processing_status'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}
