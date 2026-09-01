import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/statement_file_picker_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../chat/presentation/providers/chat_controller.dart';
import '../../data/local/financial_data_store.dart';
import '../../data/models/uploaded_statement.dart';
import '../../data/repositories/file_upload_repository.dart';

/// Rebuilt per authenticated user, same as `chatControllerProvider` and
/// `profileImageControllerProvider`. Reuses the existing
/// `statementFilePickerServiceProvider`, `fileUploadRepositoryProvider`
/// and `financialDataStoreProvider` (all defined in `chat_controller.dart`
/// since Chat's composer attachment flow shares them too) rather than
/// inventing a parallel upload pipeline.
final profileFinanceControllerProvider =
    StateNotifierProvider<ProfileFinanceController, ProfileFinanceState>((ref) {
      final userId =
          ref.watch(authControllerProvider.select((state) => state.user?.id)) ??
          'guest';
      return ProfileFinanceController(
        ref.watch(statementFilePickerServiceProvider),
        ref.watch(fileUploadRepositoryProvider),
        ref.watch(financialDataStoreProvider),
        userId,
        () => ref
            .read(chatControllerProvider.notifier)
            .clearFinancialDataContext(),
      );
    });

enum StatementUploadStatus { idle, uploading, success, error, unavailable }

class ProfileFinanceState {
  const ProfileFinanceState({
    this.statements = const [],
    this.isLoadingStatements = true,
    this.uploadStatus = StatementUploadStatus.idle,
    this.uploadMessage,
    this.isDeletingData = false,
    this.deleteFailed = false,
  });

  /// Statements this device has actually uploaded and had analyzed — never
  /// a fake/placeholder count. Empty until the backend supports listing
  /// statements or the user uploads one from this device.
  final List<UploadedStatement> statements;

  final bool isLoadingStatements;
  final StatementUploadStatus uploadStatus;
  final String? uploadMessage;
  final bool isDeletingData;
  final bool deleteFailed;

  bool get hasFinancialData => statements.isNotEmpty;

  ProfileFinanceState copyWith({
    List<UploadedStatement>? statements,
    bool? isLoadingStatements,
    StatementUploadStatus? uploadStatus,
    String? uploadMessage,
    bool clearUploadMessage = false,
    bool? isDeletingData,
    bool? deleteFailed,
  }) {
    return ProfileFinanceState(
      statements: statements ?? this.statements,
      isLoadingStatements: isLoadingStatements ?? this.isLoadingStatements,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadMessage: clearUploadMessage
          ? null
          : (uploadMessage ?? this.uploadMessage),
      isDeletingData: isDeletingData ?? this.isDeletingData,
      deleteFailed: deleteFailed ?? false,
    );
  }
}

/// Coordinates the Profile page's "Your Finances" section: the locally
/// tracked list of uploaded statements, uploading a new one via
/// `POST /api/files/upload`, and deleting all stored financial data.
///
/// There is no backend endpoint yet for listing or deleting a user's
/// statements server-side, so the statement list itself stays a local,
/// on-device record of what this device has actually uploaded — but the
/// upload call itself is real, not mocked.
class ProfileFinanceController extends StateNotifier<ProfileFinanceState> {
  ProfileFinanceController(
    this._filePicker,
    this._uploadRepository,
    this._store,
    this._userId,
    this._onFinancialDataCleared,
  ) : super(const ProfileFinanceState()) {
    _load();
  }

  final StatementFilePickerService _filePicker;
  final FileUploadRepository _uploadRepository;
  final FinancialDataStore _store;
  final String _userId;
  final void Function() _onFinancialDataCleared;

  Future<void> _load() async {
    final statements = await _store.loadStatements(_userId);
    state = state.copyWith(statements: statements, isLoadingStatements: false);
  }

  Future<void> uploadStatement() async {
    // `isUploading` in the UI already disables the button while a request
    // is in flight, but guard here too so a second call (e.g. a stray
    // double-tap) can never start a duplicate upload.
    if (state.uploadStatus == StatementUploadStatus.uploading) return;

    final PickedFile? picked;
    try {
      picked = await _filePicker.pickStatementFile();
    } catch (_) {
      state = state.copyWith(
        uploadStatus: StatementUploadStatus.error,
        uploadMessage: "Couldn't open the file picker. Please try again.",
      );
      return;
    }
    if (picked == null) return; // user cancelled — no error, no state change

    state = state.copyWith(
      uploadStatus: StatementUploadStatus.uploading,
      clearUploadMessage: true,
    );

    try {
      final file = await resolvePickedFile(picked);
      if (file == null) {
        state = state.copyWith(
          uploadStatus: StatementUploadStatus.error,
          uploadMessage: "Couldn't read that file. Please try again.",
        );
        return;
      }

      final uploaded = await _uploadRepository.uploadFile(file);
      final record = UploadedStatement(
        id: 'stmt-${uploaded.id}',
        fileName: uploaded.filename,
        uploadedAt: DateTime.now(),
        fileUrl: uploaded.fileUrl,
        contentType: uploaded.contentType,
      );
      await _store.addStatement(_userId, record);
      state = state.copyWith(
        statements: [record, ...state.statements],
        uploadStatus: StatementUploadStatus.success,
        uploadMessage: 'Statement uploaded successfully.',
      );
    } on FileUploadUnauthorizedException {
      state = state.copyWith(
        uploadStatus: StatementUploadStatus.error,
        uploadMessage: 'Your session has expired. Please log in again.',
      );
    } catch (_) {
      state = state.copyWith(
        uploadStatus: StatementUploadStatus.error,
        uploadMessage: "Couldn't upload that statement. Please try again.",
      );
    }
  }

  void dismissUploadStatus() {
    state = state.copyWith(
      uploadStatus: StatementUploadStatus.idle,
      clearUploadMessage: true,
    );
  }

  /// Deletes all locally stored financial data for this user and clears
  /// the active conversation's financial-data context, so the assistant
  /// can't keep referencing a statement that was just deleted. Does not
  /// touch the account, conversations, or profile picture.
  Future<bool> deleteFinancialData() async {
    state = state.copyWith(isDeletingData: true, deleteFailed: false);
    try {
      await _store.clear(_userId);
      _onFinancialDataCleared();
      state = state.copyWith(statements: const [], isDeletingData: false);
      return true;
    } catch (_) {
      state = state.copyWith(isDeletingData: false, deleteFailed: true);
      return false;
    }
  }
}
