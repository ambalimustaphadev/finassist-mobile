import '../../../../core/network/pagination.dart';
import '../models/uploaded_statement.dart';

abstract class DocumentRepository {
  Future<Paginated<UploadedStatement>> listFiles({int page = 1});

  Future<void> deleteFile(int id);

  /// Asks the backend for a fresh, short-lived signed URL to view the
  /// document identified by [fileId] — the document itself is private in
  /// R2, so this must be called immediately before viewing, never stored
  /// or reused once it expires (see `GET /api/files/<id>/view`).
  Future<String> getViewUrl(int fileId);
}
