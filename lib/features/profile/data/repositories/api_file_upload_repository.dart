import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/uploaded_file.dart';
import 'file_upload_repository.dart';

class ApiFileUploadRepository implements FileUploadRepository {
  ApiFileUploadRepository({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage();

  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';

  /// Statements can be a few MB — longer than the JSON-request endpoints'
  /// timeout, but still bounded so a stalled upload doesn't spin forever.
  static const _uploadTimeout = Duration(seconds: 60);

  @override
  Future<UploadedFile> uploadFile(File file) async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) {
      throw const FileUploadUnauthorizedException();
    }

    if (!await file.exists()) {
      throw Exception("That file couldn't be found. Please pick it again.");
    }

    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/files/upload'))
          ..headers['Authorization'] = 'Bearer $accessToken'
          // Field name must be exactly "file" — that's what the backend reads
          // via `request.files["file"]`.
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request).timeout(_uploadTimeout);
    } on TimeoutException {
      throw Exception(
        "Couldn't connect. Please check your connection and try again.",
      );
    } catch (_) {
      throw Exception(
        "Couldn't reach the server. Please check your connection and try again.",
      );
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      throw const FileUploadUnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload failed: ${response.statusCode}');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('The server returned an invalid upload response.');
    }

    final fileJson = data['file'];
    if (fileJson is! Map<String, dynamic>) {
      throw Exception('The server returned an invalid upload response.');
    }
    return UploadedFile.fromJson(fileJson);
  }
}
