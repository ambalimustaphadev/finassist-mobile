import 'dart:io';

import '../models/uploaded_file.dart';

/// Thrown when the backend rejects the request because the access token is
/// missing, expired, or otherwise invalid (a 401) — lets callers show a
/// "please log in again" message instead of a generic upload failure.
class FileUploadUnauthorizedException implements Exception {
  const FileUploadUnauthorizedException();
}

/// Uploads a file to FinAssist's backend, which stores it in Cloudflare R2
/// and records its metadata. The chat feature's `ChatRepository` already
/// has its own (separate) `analyzeStatement` concept for the AI-analysis
/// flow — this repository is only the plain "send this file to the
/// server" primitive `POST /api/files/upload` provides, independent of
/// whether/when analysis happens.
abstract class FileUploadRepository {
  Future<UploadedFile> uploadFile(File file);
}
