import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/services/statement_file_picker_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../chat/presentation/providers/chat_controller.dart';
import '../../data/models/uploaded_statement.dart';
import '../../data/repositories/api_document_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/repositories/file_upload_repository.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return ApiDocumentRepository(baseUrl: apiBaseUrl);
});

/// Rebuilt per authenticated user, same as `chatControllerProvider` and
/// `profileControllerProvider`. Reuses the existing
/// `statementFilePickerServiceProvider`/`fileUploadRepositoryProvider`
/// (both defined in `chat_controller.dart` since Chat's composer
/// attachment flow shares them too) rather than inventing a parallel
/// upload pipeline — only the document *list* now comes from here, via the
/// real, paginated `GET /api/files`.
final profileFinanceControllerProvider =
    StateNotifierProvider<ProfileFinanceController, ProfileFinanceState>((ref) {
      ref.watch(authControllerProvider.select((state) => state.user?.id));
      return ProfileFinanceController(
        ref.watch(statementFilePickerServiceProvider),
        ref.watch(fileUploadRepositoryProvider),
        ref.watch(documentRepositoryProvider),
      );
    });

enum StatementUploadStatus { idle, uploading, success, error, unavailable }

class ProfileFinanceState {
  const ProfileFinanceState({
    this.statements = const [],
    this.isLoadingStatements = true,
    this.loadError,
    this.pagination,
    this.isLoadingMore = false,
    this.uploadStatus = StatementUploadStatus.idle,
    this.uploadMessage,
    this.deletingDocumentId,
  });

  /// Real, backend-authoritative documents this user has uploaded —
  /// `GET /api/files`, never a fake/placeholder count.
  final List<UploadedStatement> statements;

  final bool isLoadingStatements;
  final String? loadError;
  final Pagination? pagination;
  final bool isLoadingMore;
  final StatementUploadStatus uploadStatus;
  final String? uploadMessage;

  /// The backend id of the document currently being deleted, if any —
  /// lets the tile show its own spinner without disabling the whole list.
  final int? deletingDocumentId;

  bool get hasFinancialData => statements.isNotEmpty;
  bool get hasMoreStatements => pagination?.hasMore ?? false;

  ProfileFinanceState copyWith({
    List<UploadedStatement>? statements,
    bool? isLoadingStatements,
    String? loadError,
    bool clearLoadError = false,
    Pagination? pagination,
    bool clearPagination = false,
    bool? isLoadingMore,
    StatementUploadStatus? uploadStatus,
    String? uploadMessage,
    bool clearUploadMessage = false,
    int? deletingDocumentId,
    bool clearDeletingDocumentId = false,
  }) {
    return ProfileFinanceState(
      statements: statements ?? this.statements,
      isLoadingStatements: isLoadingStatements ?? this.isLoadingStatements,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      pagination: clearPagination ? null : (pagination ?? this.pagination),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadMessage: clearUploadMessage
          ? null
          : (uploadMessage ?? this.uploadMessage),
      deletingDocumentId: clearDeletingDocumentId
          ? null
          : (deletingDocumentId ?? this.deletingDocumentId),
    );
  }
}

/// Coordinates Profile's financial-data summary: the real, backend-
/// authoritative list of uploaded files (`GET /api/files`, shared with
/// Chat's attachment flow) and deleting all of them at once.
class ProfileFinanceController extends StateNotifier<ProfileFinanceState> {
  ProfileFinanceController(
    this._filePicker,
    this._uploadRepository,
    this._documentRepository,
  ) : super(const ProfileFinanceState()) {
    _load();
  }

  final StatementFilePickerService _filePicker;
  final FileUploadRepository _uploadRepository;
  final DocumentRepository _documentRepository;

  Future<void> _load() async {
    state = state.copyWith(isLoadingStatements: true, clearLoadError: true);
    try {
      final page = await _documentRepository.listFiles();
      state = state.copyWith(
        statements: page.items,
        pagination: page.pagination,
        isLoadingStatements: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingStatements: false, loadError: e.message);
    }
  }

  Future<void> refresh() => _load();

  Future<void> loadMore() async {
    final pagination = state.pagination;
    if (pagination == null || !pagination.hasMore || state.isLoadingMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _documentRepository.listFiles(
        page: pagination.page + 1,
      );
      state = state.copyWith(
        statements: [...state.statements, ...page.items],
        pagination: page.pagination,
        isLoadingMore: false,
      );
    } on ApiException {
      state = state.copyWith(isLoadingMore: false);
    }
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
        backendId: uploaded.id,
        fileName: uploaded.filename,
        uploadedAt: DateTime.now(),
        contentType: uploaded.contentType,
      );
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

  /// Deletes a single document. Returns `false` (leaving [state] unchanged
  /// beyond clearing the in-flight marker) if the backend rejects it, so
  /// the UI can show a real error instead of silently removing a tile that
  /// wasn't actually deleted server-side.
  Future<bool> deleteDocument(int backendId) async {
    state = state.copyWith(deletingDocumentId: backendId);
    try {
      await _documentRepository.deleteFile(backendId);
      state = state.copyWith(
        statements: state.statements
            .where((s) => s.backendId != backendId)
            .toList(),
        clearDeletingDocumentId: true,
      );
      return true;
    } on ApiException {
      state = state.copyWith(clearDeletingDocumentId: true);
      return false;
    }
  }
}
