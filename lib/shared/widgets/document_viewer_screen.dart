import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// `pdfx` re-exports `photo_view`'s API (it uses `PhotoView` internally for
// its own image-page zooming), so no separate direct import is needed —
// one less dependency to track for the same viewer this screen already
// pulls in for PDFs.
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'icon_badge.dart';

/// Pushes the shared in-app document viewer — the one place Chat and
/// Profile → Documents both open an uploaded file, so there's a single
/// PDF/image viewing implementation rather than two. [fileUrl] is the R2
/// URL exactly as returned by `POST /api/files/upload`; nothing is
/// re-uploaded or re-fetched from anywhere else.
Future<void> openDocumentViewer(
  BuildContext context, {
  required String? fileUrl,
  required String filename,
  String? contentType,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DocumentViewerScreen(
        fileUrl: fileUrl,
        filename: filename,
        contentType: contentType,
      ),
    ),
  );
}

enum _DocumentKind { pdf, image, unsupported }

/// Displays a single uploaded document inside FinAssist — a PDF (with
/// pinch-to-zoom and scroll) or an image (with pinch-to-zoom) — based on
/// [contentType] if known, falling back to [filename]'s extension. Types
/// neither viewer supports get a friendly "can't preview this" state with
/// "Open externally" as its only, clearly-secondary way out; PDFs and
/// images stay inside the app by default, with "Open externally" always
/// available as a secondary AppBar action.
class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({
    super.key,
    required this.fileUrl,
    required this.filename,
    this.contentType,
  });

  final String? fileUrl;
  final String filename;
  final String? contentType;

  _DocumentKind get _kind {
    final type = (contentType ?? '').toLowerCase();
    final ext = _extensionOf(filename);
    if (type.contains('pdf') || ext == 'pdf') return _DocumentKind.pdf;
    if (type.startsWith('image/') ||
        const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) {
      return _DocumentKind.image;
    }
    return _DocumentKind.unsupported;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  Future<void> _openExternally(BuildContext context) async {
    final url = fileUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              "Couldn't open this document.",
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = fileUrl;
    final validUrl = url != null && url.isNotEmpty && Uri.tryParse(url) != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.screenTitle,
        ),
        actions: [
          if (validUrl)
            IconButton(
              tooltip: 'Open externally',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => _openExternally(context),
            ),
        ],
      ),
      body: SafeArea(
        child: !validUrl
            ? const _DocumentMessage(
                icon: Icons.link_off_rounded,
                title: "This document can't be opened",
                message: 'Its link is missing or invalid.',
              )
            : switch (_kind) {
                _DocumentKind.pdf => _PdfViewer(fileUrl: url),
                _DocumentKind.image => _ImageViewer(fileUrl: url),
                _DocumentKind.unsupported => _UnsupportedDocument(
                  filename: filename,
                  onOpenExternally: () => _openExternally(context),
                ),
              },
      ),
    );
  }
}

class _DocumentLoadException implements Exception {
  const _DocumentLoadException(this.message);
  final String message;
}

class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.fileUrl});
  final String fileUrl;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late final Future<PdfControllerPinch> _future = _load();

  Future<PdfControllerPinch> _load() async {
    final http.Response response;
    try {
      response = await http
          .get(Uri.parse(widget.fileUrl))
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw const _DocumentLoadException(
        "Couldn't connect. Please check your connection and try again.",
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const _DocumentLoadException("Couldn't download this document.");
    }

    final PdfDocument document;
    try {
      document = await PdfDocument.openData(response.bodyBytes);
    } catch (_) {
      throw const _DocumentLoadException(
        "This document couldn't be displayed.",
      );
    }
    return PdfControllerPinch(document: Future.value(document));
  }

  @override
  void dispose() {
    _future.then((controller) => controller.dispose()).ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfControllerPinch>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _DocumentMessage(
            icon: Icons.error_outline_rounded,
            title: "Couldn't open this document",
            message: error is _DocumentLoadException
                ? error.message
                : 'Something went wrong. Please try again.',
          );
        }
        return PdfViewPinch(controller: snapshot.data!);
      },
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.fileUrl});
  final String fileUrl;

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: NetworkImage(fileUrl),
      backgroundDecoration: const BoxDecoration(color: AppColors.background),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      loadingBuilder: (context, event) => const _LoadingState(),
      errorBuilder: (context, error, stackTrace) => const _DocumentMessage(
        icon: Icons.broken_image_outlined,
        title: "Couldn't load this image",
        message: 'Please check your connection and try again.',
      ),
    );
  }
}

class _UnsupportedDocument extends StatelessWidget {
  const _UnsupportedDocument({
    required this.filename,
    required this.onOpenExternally,
  });

  final String filename;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return _DocumentMessage(
      icon: Icons.insert_drive_file_outlined,
      title: "Can't preview this file type",
      message:
          "FinAssist can't display $filename inside the app yet, but you "
          'can open it in another app.',
      action: SizedBox(
        width: double.infinity,
        child: Material(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: onOpenExternally,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.xl,
              ),
              child: Text(
                'Open externally',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2.4,
        ),
      ),
    );
  }
}

class _DocumentMessage extends StatelessWidget {
  const _DocumentMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon: icon,
              color: AppColors.textMuted,
              size: 56,
              iconSize: 26,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.sectionHeading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
