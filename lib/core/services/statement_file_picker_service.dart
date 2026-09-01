import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// File extensions FinAssist accepts for a bank statement upload.
const List<String> supportedStatementExtensions = [
  'pdf',
  'csv',
  'xls',
  'xlsx',
  'jpg',
  'jpeg',
  'png',
];

/// The result of a successful file pick, decoupled from `file_picker`'s own
/// types so the rest of the app (and tests) don't depend on the plugin.
class PickedFile {
  const PickedFile({
    required this.name,
    this.extension,
    this.sizeBytes,
    this.path,
    this.bytes,
  });

  final String name;
  final String? extension;
  final int? sizeBytes;

  /// The file's on-disk path, when the platform provides one — the
  /// preferred way to read it back for an upload (streams from disk
  /// rather than holding the whole file in memory).
  final String? path;

  /// The file's raw bytes, populated as a fallback for when [path] isn't
  /// available (uncommon, but possible depending on platform/picker
  /// behavior) so a caller can still upload it without touching disk.
  final Uint8List? bytes;
}

/// Lets the user pick a bank statement file from their device. A real
/// implementation wraps the OS file picker; tests can substitute a fake
/// that returns a canned file without touching platform channels.
abstract class StatementFilePickerService {
  /// Returns `null` if the user cancels the picker.
  Future<PickedFile?> pickStatementFile();
}

class FilePickerStatementService implements StatementFilePickerService {
  @override
  Future<PickedFile?> pickStatementFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedStatementExtensions,
      // Guarantees `bytes` is populated even on the rare platform/device
      // combination where `path` comes back null, so a real upload never
      // has nothing to read from.
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    return PickedFile(
      name: file.name,
      extension: file.extension,
      sizeBytes: file.size,
      path: file.path,
      bytes: file.bytes,
    );
  }
}

/// Turns a [PickedFile] into a real [File] to upload — shared by every
/// caller that picks via [StatementFilePickerService] and then needs to
/// read the bytes back (Profile's statement upload, Chat's composer
/// attachment). Prefers [PickedFile.path] (memory-efficient — streams
/// straight off disk); if the platform didn't provide one, falls back to
/// writing [PickedFile.bytes] to a temp file so the same upload path
/// still works. Returns `null` (never throws) if neither is available,
/// which callers turn into a friendly error instead of a crash.
Future<File?> resolvePickedFile(PickedFile picked) async {
  final path = picked.path;
  if (path != null) return File(path);

  final bytes = picked.bytes;
  if (bytes == null) return null;

  try {
    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/${picked.name}');
    return await tempFile.writeAsBytes(bytes);
  } catch (_) {
    return null;
  }
}
