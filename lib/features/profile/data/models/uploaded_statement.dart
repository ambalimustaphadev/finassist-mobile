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
  });

  final String id;
  final String fileName;
  final DateTime uploadedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'uploadedAt': uploadedAt.toIso8601String(),
    'periodStart': periodStart?.toIso8601String(),
    'periodEnd': periodEnd?.toIso8601String(),
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
    );
  }
}
