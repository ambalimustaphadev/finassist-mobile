/// A bank statement the user has uploaded and had analyzed, as tracked
/// locally on this device. There is no backend endpoint yet for listing a
/// user's statements server-side (see `ProfileFinanceController`'s doc
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
  });

  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// The R2-accessible URL returned by `POST /api/files/upload` —
  /// cached locally so tapping this statement can open the real document
  /// without a separate backend round trip. Null for statements uploaded
  /// before this field existed.
  final String? fileUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'uploadedAt': uploadedAt.toIso8601String(),
    'periodStart': periodStart?.toIso8601String(),
    'periodEnd': periodEnd?.toIso8601String(),
    'fileUrl': fileUrl,
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
    );
  }
}
