import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Renders [text] with any substring listed in [highlights] colored with
/// [highlightColor]. Used for AI insight and chat copy where key figures
/// and category names are called out, e.g. "You spent 18% more on
/// **Food & Dining**".
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    this.highlights = const [],
    required this.style,
    this.highlightColor = AppColors.accent,
    this.highlightWeight = FontWeight.w600,
  });

  final String text;
  final List<String> highlights;
  final TextStyle style;
  final Color highlightColor;
  final FontWeight highlightWeight;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    var cursor = 0;

    while (cursor < text.length) {
      int? matchStart;
      String? matchedHighlight;

      for (final highlight in highlights) {
        if (highlight.isEmpty) continue;
        final index = text.indexOf(highlight, cursor);
        if (index != -1 && (matchStart == null || index < matchStart)) {
          matchStart = index;
          matchedHighlight = highlight;
        }
      }

      if (matchStart == null || matchedHighlight == null) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }

      if (matchStart > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, matchStart)));
      }

      spans.add(
        TextSpan(
          text: matchedHighlight,
          style: TextStyle(color: highlightColor, fontWeight: highlightWeight),
        ),
      );
      cursor = matchStart + matchedHighlight.length;
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}
