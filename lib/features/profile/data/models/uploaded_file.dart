/// The backend's record of a file uploaded via `POST /api/files/upload` —
/// mirrors the `file` object in its JSON response exactly. The actual
/// bytes live in Cloudflare R2 under [key]; Flutter never talks to R2
/// directly and never sees any R2 credentials, only this metadata.
class UploadedFile {
  const UploadedFile({
    required this.id,
    required this.filename,
    required this.size,
    required this.contentType,
    required this.key,
  });

  final int id;
  final String filename;
  final int size;
  final String contentType;

  /// The object's storage key inside the R2 bucket — server-generated,
  /// never constructed on the Flutter side.
  final String key;

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
      key: (json['key'] ?? '').toString(),
    );
  }
}
