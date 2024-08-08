import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatBubble extends StatefulWidget {
  final String message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Clear the selection when losing focus
        Clipboard.setData(ClipboardData(text: widget.message));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final richText = _convertToRichText(widget.message);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 184, 60, 22),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: GestureDetector(
        onTap: () {
          _focusNode.unfocus(); // Unfocus to clear selection
        },
        child: SelectableText.rich(
          TextSpan(
            children: richText,
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16.0),
          ),
          focusNode: _focusNode,
          onSelectionChanged: (selection, cause) {
            if (selection.isCollapsed) {
              // If selection is collapsed (i.e., text is copied), remove focus
              _focusNode.unfocus();
            }
          },
        ),
      ),
    );
  }

  List<TextSpan> _convertToRichText(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in boldRegex.allMatches(text)) {
      // Add the text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(fontSize: 16.0),
        ));
      }

      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
        ),
      ));

      lastIndex = match.end;
    }

    // Add any remaining text after the last match
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(fontSize: 16.0),
      ));
    }

    return spans;
  }
}