import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/network/api_client.dart';
import 'package:finassist/core/network/pagination.dart';
import 'package:finassist/core/services/statement_file_picker_service.dart';
import 'package:finassist/features/profile/data/models/uploaded_file.dart';
import 'package:finassist/features/profile/data/models/uploaded_statement.dart';
import 'package:finassist/features/profile/data/repositories/document_repository.dart';
import 'package:finassist/features/profile/data/repositories/file_upload_repository.dart';
import 'package:finassist/features/profile/presentation/providers/profile_finance_controller.dart';

const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(TestWidgetsFlutterBinding binding) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async => null,
  );
}

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

/// `path_provider`'s MethodChannel doesn't exist in a test environment
/// either — needed here because `ProfileFinanceController._resolveFile`
/// falls back to `getTemporaryDirectory()` when a picked file has no
/// `path`, only `bytes`.
void _mockPathProvider(TestWidgetsFlutterBinding binding) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _pathProviderChannel,
    (call) async => Directory.systemTemp.path,
  );
}

class _FakeFilePicker implements StatementFilePickerService {
  _FakeFilePicker({this.result});
  final PickedFile? result;

  @override
  Future<PickedFile?> pickStatementFile() async => result;
}

/// A fake standing in for the real `POST /api/files/upload` HTTP call —
/// either returns [result] (mirroring a 2xx response) or throws
/// [errorToThrow] (mirroring a failed request), so `ProfileFinanceController`
/// can be tested against both outcomes without spinning up an HTTP client.
class _FakeFileUploadRepository implements FileUploadRepository {
  _FakeFileUploadRepository({this.result, this.errorToThrow});
  final UploadedFile? result;
  final Object? errorToThrow;

  @override
  Future<UploadedFile> uploadFile(File file) async {
    if (errorToThrow != null) throw errorToThrow!;
    return result!;
  }
}

/// A fake standing in for the real `GET /api/files`/`DELETE /api/files/<id>`
/// calls — [perPage] lets a test exercise pagination (`loadMore`) without a
/// real backend.
class _FakeDocumentRepository implements DocumentRepository {
  _FakeDocumentRepository({
    List<UploadedStatement>? seed,
    this.perPage = 20,
    this.loadError,
    this.deleteError,
  }) : _files = List.of(seed ?? const []);

  final List<UploadedStatement> _files;
  final int perPage;
  final Object? loadError;
  final Object? deleteError;

  @override
  Future<Paginated<UploadedStatement>> listFiles({int page = 1}) async {
    if (loadError != null) throw loadError!;
    final start = (page - 1) * perPage;
    final items = start >= _files.length
        ? const <UploadedStatement>[]
        : _files.sublist(start, (start + perPage).clamp(0, _files.length));
    return Paginated(
      items: items,
      pagination: Pagination(
        page: page,
        perPage: perPage,
        total: _files.length,
      ),
    );
  }

  @override
  Future<void> deleteFile(int id) async {
    if (deleteError != null) throw deleteError!;
    _files.removeWhere((f) => f.backendId == id);
  }

  @override
  Future<String> getViewUrl(int fileId) async {
    return 'https://pub-test.r2.dev/signed/$fileId';
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockSecureStorage(binding);
    _mockPathProvider(binding);
  });

  Future<void> waitUntil(
    bool Function() condition, {
    int maxTries = 200,
  }) async {
    for (var i = 0; i < maxTries; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  /// A real temp file on disk — `ProfileFinanceController` reads the
  /// picked file's path back via `File(picked.path)` before uploading it,
  /// same as it would for a real `file_picker` result.
  Future<File> createTempFile(String name) async {
    final file = File(
      '${Directory.systemTemp.path}/finance_test_${DateTime.now().microsecondsSinceEpoch}_$name',
    );
    return file.create();
  }

  test('starts empty with no fake statement count', () async {
    final controller = ProfileFinanceController(
      _FakeFilePicker(result: null),
      _FakeFileUploadRepository(),
      _FakeDocumentRepository(),
    );
    await waitUntil(() => !controller.state.isLoadingStatements);

    expect(controller.state.statements, isEmpty);
    expect(controller.state.hasFinancialData, isFalse);
  });

  test('a failed load surfaces a clear error, not a crash', () async {
    final controller = ProfileFinanceController(
      _FakeFilePicker(result: null),
      _FakeFileUploadRepository(),
      _FakeDocumentRepository(
        loadError: const ApiException("Couldn't connect."),
      ),
    );
    await waitUntil(() => !controller.state.isLoadingStatements);

    expect(controller.state.loadError, isNotNull);
    expect(controller.state.statements, isEmpty);
  });

  test('cancelling the file picker leaves state untouched', () async {
    final controller = ProfileFinanceController(
      _FakeFilePicker(result: null),
      _FakeFileUploadRepository(),
      _FakeDocumentRepository(),
    );
    await waitUntil(() => !controller.state.isLoadingStatements);

    await controller.uploadStatement();

    expect(controller.state.statements, isEmpty);
    expect(controller.state.uploadStatus, StatementUploadStatus.idle);
  });

  test(
    'a successful upload adds a real statement record from the server response',
    () async {
      final tempFile = await createTempFile('Statement.pdf');
      addTearDown(() => tempFile.delete());

      final picker = _FakeFilePicker(
        result: PickedFile(
          name: 'Statement.pdf',
          extension: 'pdf',
          sizeBytes: 1024,
          path: tempFile.path,
        ),
      );
      final controller = ProfileFinanceController(
        picker,
        _FakeFileUploadRepository(
          result: const UploadedFile(
            id: 1,
            filename: 'Statement.pdf',
            size: 1024,
            contentType: 'application/pdf',
          ),
        ),
        _FakeDocumentRepository(),
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      await controller.uploadStatement();

      expect(controller.state.uploadStatus, StatementUploadStatus.success);
      expect(controller.state.statements, hasLength(1));
      expect(controller.state.statements.single.fileName, 'Statement.pdf');
      expect(controller.state.statements.single.backendId, 1);
      expect(controller.state.hasFinancialData, isTrue);
    },
  );

  test(
    'a picked file with no path falls back to its bytes instead of crashing',
    () async {
      final picker = _FakeFilePicker(
        result: PickedFile(
          name: 'Statement.pdf',
          extension: 'pdf',
          sizeBytes: 3,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      final controller = ProfileFinanceController(
        picker,
        _FakeFileUploadRepository(
          result: const UploadedFile(
            id: 2,
            filename: 'Statement.pdf',
            size: 3,
            contentType: 'application/pdf',
          ),
        ),
        _FakeDocumentRepository(),
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      await controller.uploadStatement();

      expect(controller.state.uploadStatus, StatementUploadStatus.success);
      expect(controller.state.statements, hasLength(1));
    },
  );

  test(
    'a picked file with neither a path nor bytes fails cleanly, no crash',
    () async {
      final picker = _FakeFilePicker(
        result: const PickedFile(name: 'Statement.pdf', extension: 'pdf'),
      );
      final controller = ProfileFinanceController(
        picker,
        _FakeFileUploadRepository(),
        _FakeDocumentRepository(),
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      await controller.uploadStatement();

      expect(controller.state.uploadStatus, StatementUploadStatus.error);
      expect(controller.state.statements, isEmpty);
    },
  );

  test(
    'upload reports a clear message when the backend request fails',
    () async {
      final tempFile = await createTempFile('Statement.pdf');
      addTearDown(() => tempFile.delete());

      final picker = _FakeFilePicker(
        result: PickedFile(
          name: 'Statement.pdf',
          extension: 'pdf',
          sizeBytes: 1024,
          path: tempFile.path,
        ),
      );
      final controller = ProfileFinanceController(
        picker,
        _FakeFileUploadRepository(errorToThrow: Exception('boom')),
        _FakeDocumentRepository(),
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      await controller.uploadStatement();

      expect(controller.state.uploadStatus, StatementUploadStatus.error);
      expect(controller.state.uploadMessage, isNotNull);
      expect(controller.state.statements, isEmpty);
    },
  );

  test(
    'an expired session surfaces a login-again message, not a raw error',
    () async {
      final tempFile = await createTempFile('Statement.pdf');
      addTearDown(() => tempFile.delete());

      final picker = _FakeFilePicker(
        result: PickedFile(
          name: 'Statement.pdf',
          extension: 'pdf',
          sizeBytes: 1024,
          path: tempFile.path,
        ),
      );
      final controller = ProfileFinanceController(
        picker,
        _FakeFileUploadRepository(
          errorToThrow: const FileUploadUnauthorizedException(),
        ),
        _FakeDocumentRepository(),
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      await controller.uploadStatement();

      expect(controller.state.uploadStatus, StatementUploadStatus.error);
      expect(controller.state.uploadMessage, contains('log in again'));
    },
  );

  test('deleteDocument removes just that document on success', () async {
    final controller = ProfileFinanceController(
      _FakeFilePicker(result: null),
      _FakeFileUploadRepository(),
      _FakeDocumentRepository(
        seed: [
          UploadedStatement(
            id: 'stmt-10',
            backendId: 10,
            fileName: 'August.pdf',
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );
    await waitUntil(() => !controller.state.isLoadingStatements);
    expect(controller.state.statements, hasLength(1));

    final success = await controller.deleteDocument(10);

    expect(success, isTrue);
    expect(controller.state.statements, isEmpty);
    expect(controller.state.deletingDocumentId, isNull);
  });

  test('a failed deleteDocument leaves the document in place', () async {
    final controller = ProfileFinanceController(
      _FakeFilePicker(result: null),
      _FakeFileUploadRepository(),
      _FakeDocumentRepository(
        seed: [
          UploadedStatement(
            id: 'stmt-11',
            backendId: 11,
            fileName: 'August.pdf',
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
        deleteError: const ApiException("Couldn't connect."),
      ),
    );
    await waitUntil(() => !controller.state.isLoadingStatements);

    final success = await controller.deleteDocument(11);

    expect(success, isFalse);
    expect(controller.state.statements, hasLength(1));
  });

  test(
    'loadMore appends the next page without dropping what\'s loaded',
    () async {
      final controller = ProfileFinanceController(
        _FakeFilePicker(result: null),
        _FakeFileUploadRepository(),
        _FakeDocumentRepository(
          perPage: 1,
          seed: [
            UploadedStatement(
              id: 'stmt-1',
              backendId: 1,
              fileName: 'Jan.pdf',
              uploadedAt: DateTime(2026, 1, 1),
            ),
            UploadedStatement(
              id: 'stmt-2',
              backendId: 2,
              fileName: 'Feb.pdf',
              uploadedAt: DateTime(2026, 2, 1),
            ),
          ],
        ),
      );
      await waitUntil(() => !controller.state.isLoadingStatements);
      expect(controller.state.statements, hasLength(1));
      expect(controller.state.hasMoreStatements, isTrue);

      await controller.loadMore();

      expect(controller.state.statements, hasLength(2));
      expect(controller.state.hasMoreStatements, isFalse);
    },
  );

  test(
    'a freshly constructed controller loads whatever the backend already has',
    () async {
      final repository = _FakeDocumentRepository(
        seed: [
          UploadedStatement(
            id: 'stmt-4',
            backendId: 4,
            fileName: 'Statement.pdf',
            uploadedAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      final controller = ProfileFinanceController(
        _FakeFilePicker(result: null),
        _FakeFileUploadRepository(),
        repository,
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      expect(controller.state.statements, hasLength(1));
      expect(controller.state.statements.single.fileName, 'Statement.pdf');
    },
  );
}
