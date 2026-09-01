/// A financial document (a bank statement today; investment/loan/insurance
/// documents and other financial reports are the same shape, per the
/// Documents page's broader remit) the user has uploaded, as tracked
/// locally on this device. There is no backend endpoint yet for listing a
/// user's documents server-side (see `ProfileFinanceController`'s doc
/// comment) — this is real data about what actually happened on this
/// device, not a placeholder.
class UploadedStatement {
  const UploadedStatement({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    this.periodStart,
    this.periodEnd,
    this.fileUrl,
    this.contentType,
  });

  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// The R2-accessible URL returned by `POST /api/files/upload` —
  /// cached locally so tapping this document can open it (via the shared
  /// document viewer) without a separate backend round trip. Null for
  /// documents uploaded before this field existed.
  final String? fileUrl;

  /// The backend's reported MIME type, when known — lets the document
  /// viewer pick a renderer without guessing from the filename alone.
  /// Null for documents uploaded before this field existed; the viewer
  /// falls back to the filename's extension in that case.
  final String? contentType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'uploadedAt': uploadedAt.toIso8601String(),
    'periodStart': periodStart?.toIso8601String(),
    'periodEnd': periodEnd?.toIso8601String(),
    'fileUrl': fileUrl,
    'contentType': contentType,
  };

  factory UploadedStatement.fromJson(Map<String, dynamic> json) {
    return UploadedStatement(
      id: json['id'] as String,
      fileName: (json['fileName'] as String?) ?? 'Statement',
      uploadedAt:
          DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ??
          DateTime.now(),
      periodStart: json['periodStart'] == null
          ? null
          : DateTime.tryParse(json['periodStart'].toString()),
      periodEnd: json['periodEnd'] == null
          ? null
          : DateTime.tryParse(json['periodEnd'].toString()),
      fileUrl: json['fileUrl'] as String?,
      contentType: json['contentType'] as String?,
    );
  }
}
