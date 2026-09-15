import '../../../../core/network/api_client.dart';
import '../../../../core/network/pagination.dart';
import '../models/uploaded_statement.dart';
import 'document_repository.dart';

class ApiDocumentRepository implements DocumentRepository {
  ApiDocumentRepository({required String baseUrl, ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: baseUrl);

  final ApiClient _client;

  @override
  Future<Paginated<UploadedStatement>> listFiles({int page = 1}) async {
    final json = await _client.get('/api/files', query: {'page': '$page'});
    final items = (json['items'] as List?) ?? const [];
    return Paginated(
      items: items
          .map(
            (item) =>
                UploadedStatement.fromFileJson(item as Map<String, dynamic>),
          )
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  Future<void> deleteFile(int id) {
    return _client.delete('/api/files/$id');
  }

  @override
  Future<String> getViewUrl(int fileId) async {
    final json = await _client.get('/api/files/$fileId/view');
    // The exact key name isn't pinned down on this side of the API
    // boundary — accept whichever of the plausible shapes the backend
    // actually returns rather than guessing wrong and failing silently.
    final url =
        json['url'] ??
        json['view_url'] ??
        json['signed_url'] ??
        json['file_url'];
    if (url is! String || url.isEmpty) {
      throw Exception('The server returned an invalid view link.');
    }
    return url;
  }
}
