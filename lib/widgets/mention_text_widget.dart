import 'package:flutter/material.dart';

class MentionTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color mentionColor;
  final Color mentionBackgroundColor;

  const MentionTextWidget({
    Key? key,
    required this.text,
    this.textStyle,
    this.mentionColor = const Color(0xFF2196F3),
    this.mentionBackgroundColor = const Color(0xFF2196F3),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'@everyone', caseSensitive: false);
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add text before mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: textStyle,
        ));
      }

      // Add highlighted mention
      spans.add(TextSpan(
        text: match.group(0),
        style: textStyle?.copyWith(
          color: mentionColor,
          fontWeight: FontWeight.bold,
          backgroundColor: mentionBackgroundColor.withOpacity(0.2),
        ) ?? TextStyle(
          color: mentionColor,
          fontWeight: FontWeight.bold,
          backgroundColor: mentionBackgroundColor.withOpacity(0.2),
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: textStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}