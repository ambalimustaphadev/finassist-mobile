import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// A simple, friendly FinAssist "robot assistant" mark, drawn from basic
/// shapes rather than a commissioned illustration (no such asset exists
/// in the project yet) — deliberately plain (a rounded face, two eyes, a
/// small antenna) so it reads as an AI companion, never as fabricated
/// financial charts/statistics.
class FinAssistRobotAvatar extends StatelessWidget {
  const FinAssistRobotAvatar({
    super.key,
    this.size = 88,
    this.celebrating = false,
  });

  final double size;

  /// The completion page's variant: a small checkmark badge overlapping
  /// the face, instead of the plain greeting expression.
  final bool celebrating;

  @override
  Widget build(BuildContext context) {
    final faceSize = size * 0.62;
    final eyeSize = faceSize * 0.16;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.accentSoft,
            ),
          ),
          // Antenna.
          Positioned(
            top: size * 0.06,
            child: Container(
              width: 3,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: context.colors.accentStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: size * 0.02,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.accent,
              ),
            ),
          ),
          // Face.
          Container(
            width: faceSize,
            height: faceSize * 0.82,
            margin: EdgeInsets.only(top: size * 0.14),
            decoration: BoxDecoration(
              color: context.colors.textPrimary,
              borderRadius: BorderRadius.circular(faceSize * 0.28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Eye(size: eyeSize),
                SizedBox(width: eyeSize * 1.4),
                _Eye(size: eyeSize),
              ],
            ),
          ),
          if (celebrating)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.accent,
                  border: Border.all(
                    color: context.colors.background,
                    width: 2.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_rounded,
                  size: size * 0.18,
                  color: context.colors.textOnAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // The face uses context.colors.textPrimary (dark in Light mode,
        // light in Dark mode) — the eyes need to contrast against *that*,
        // not be hardcoded white, or they'd vanish against a light face
        // in Dark mode.
        color: context.colors.background,
      ),
    );
  }
}
