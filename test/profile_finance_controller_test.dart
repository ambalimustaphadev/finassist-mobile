import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finassist/core/services/statement_file_picker_service.dart';
import 'package:finassist/features/profile/data/local/financial_data_store.dart';
import 'package:finassist/features/profile/data/models/uploaded_file.dart';
import 'package:finassist/features/profile/data/repositories/file_upload_repository.dart';
import 'package:finassist/features/profile/presentation/providers/profile_finance_controller.dart';

const _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void _mockSecureStorage(
  TestWidgetsFlutterBinding binding,
  Map<String, String> values,
) {
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _secureStorageChannel,
    (call) async {
      switch (call.method) {
        case 'read':
          return values[call.arguments['key']];
        case 'write':
          values[call.arguments['key'] as String] =
              call.arguments['value'] as String;
          return null;
        case 'delete':
          values.remove(call.arguments['key']);
          return null;
        default:
          return null;
      }
    },
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

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockSecureStorage(binding, {});
    _mockPathProvider(binding);
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _secureStorageChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _pathProviderChannel,
      null,
    );
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
      FinancialDataStore(),
      'user-1',
      () {},
    );
    await waitUntil(() => !controller.state.isLoadingStatements);

    expect(controller.state.statements, isEmpty);
    expect(controller.state.hasFinancialData, isFalse);
  });

  test('cancelling the file picker leaves state untouched', () async {
    final controller = ProfileFinanceController(
      _FakeFilePicker(result: null),
      _FakeFileUploadRepository(),
      FinancialDataStore(),
      'user-1',
      () {},
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
            key: 'statements/1/uuid.pdf',
          ),
        ),
        FinancialDataStore(),
        'user-1',
        () {},
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      await controller.uploadStatement();

      expect(controller.state.uploadStatus, StatementUploadStatus.success);
      expect(controller.state.statements, hasLength(1));
      expect(controller.state.statements.single.fileName, 'Statement.pdf');
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
            key: 'statements/1/uuid2.pdf',
          ),
        ),
        FinancialDataStore(),
        'user-1',
        () {},
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
        FinancialDataStore(),
        'user-1',
        () {},
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
        FinancialDataStore(),
        'user-1',
        () {},
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
        FinancialDataStore(),
        'user-1',
        () {},
      );
      await waitUntil(() => !controller.state.isLoadingStatements);

      await controller.uploadStatement();

      expect(controller.state.uploadStatus, StatementUploadStatus.error);
      expect(controller.state.uploadMessage, contains('log in again'));
    },
  );

  test(
    'deleting financial data clears statements and notifies the chat context',
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
      var clearedCalled = false;
      final store = FinancialDataStore();
      final controller = ProfileFinanceController(
        picker,
        _FakeFileUploadRepository(
          result: const UploadedFile(
            id: 3,
            filename: 'Statement.pdf',
            size: 1024,
            contentType: 'application/pdf',
            key: 'statements/1/uuid3.pdf',
          ),
        ),
        store,
        'user-1',
        () => clearedCalled = true,
      );
      await waitUntil(() => !controller.state.isLoadingStatements);
      await controller.uploadStatement();
      expect(controller.state.statements, hasLength(1));

      final success = await controller.deleteFinancialData();

      expect(success, isTrue);
      expect(controller.state.statements, isEmpty);
      expect(controller.state.hasFinancialData, isFalse);
      expect(clearedCalled, isTrue);
      // Persisted deletion, not just in-memory.
      expect(await store.loadStatements('user-1'), isEmpty);
    },
  );

  test('uploaded statements persist across a simulated app restart', () async {
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
    final store = FinancialDataStore();
    final firstController = ProfileFinanceController(
      picker,
      _FakeFileUploadRepository(
        result: const UploadedFile(
          id: 4,
          filename: 'Statement.pdf',
          size: 1024,
          contentType: 'application/pdf',
          key: 'statements/1/uuid4.pdf',
        ),
      ),
      store,
      'user-1',
      () {},
    );
    await waitUntil(() => !firstController.state.isLoadingStatements);
    await firstController.uploadStatement();
    expect(firstController.state.statements, hasLength(1));

    final restartedController = ProfileFinanceController(
      _FakeFilePicker(result: null),
      _FakeFileUploadRepository(),
      store,
      'user-1',
      () {},
    );
    await waitUntil(() => !restartedController.state.isLoadingStatements);

    expect(restartedController.state.statements, hasLength(1));
    expect(
      restartedController.state.statements.single.fileName,
      'Statement.pdf',
    );
  });
}
