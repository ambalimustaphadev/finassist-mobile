/// A financial document (a bank statement today; investment/loan/insurance
/// documents and other financial reports are the same shape) the user has
/// uploaded within a chat conversation — mirrors one item from the real,
/// backend-authoritative `GET /api/files` response.
///
/// Financial documents are private in Cloudflare R2 — this model never
/// carries a permanent/public URL. [backendId] (the real `UploadFile.id`,
/// i.e. `file_id`) is the only identity needed to delete a document or to
/// request a fresh, short-lived view URL from `GET /api/files/<id>/view`.
class UploadedStatement {
  const UploadedStatement({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    this.periodStart,
    this.periodEnd,
    this.contentType,
    this.backendId,
  });

  final String id;

  /// The backend's real `UploadFile.id` (`file_id`) — what
  /// `DELETE /api/files/<id>` and the view endpoint need.
  final int? backendId;
  final String fileName;
  final DateTime uploadedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// The backend's reported MIME type, when known — lets the document
  /// viewer pick a renderer without guessing from the filename alone.
  /// Null for documents uploaded before this field existed; the viewer
  /// falls back to the filename's extension in that case.
  final String? contentType;

  /// Mirrors `_file_to_dict` in the backend's `file_routes.py` — one item
  /// from the real, paginated `GET /api/files` response.
  factory UploadedStatement.fromFileJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    return UploadedStatement(
      id: 'stmt-$id',
      backendId: id,
      fileName: (json['filename'] as String?) ?? 'Document',
      uploadedAt: DateTime.parse(json['created_at'] as String),
      periodStart: json['financial_period_start'] == null
          ? null
          : DateTime.parse(json['financial_period_start'] as String),
      periodEnd: json['financial_period_end'] == null
          ? null
          : DateTime.parse(json['financial_period_end'] as String),
      contentType: json['content_type'] as String?,
    );
  }
}
