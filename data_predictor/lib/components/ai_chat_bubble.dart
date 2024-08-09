import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiChatBubble extends StatefulWidget {
  final String message;

  const AiChatBubble({
    super.key,
    required this.message,
  });

  @override
  _AiChatBubbleState createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<AiChatBubble> {
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: GestureDetector(
        onTap: () {
          _focusNode.unfocus(); // Unfocus to clear selection
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align the icon at the top
          children: [
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Icon(
                Icons.person, 
                color: Colors.white,
                size: 24, // Size of the icon
              ),
            ),
            const SizedBox(width: 20), // Add some space between the icon and text
            Expanded(
              child: SelectableText.rich(
                TextSpan(
                  children: richText,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontFamily: 'SFCompactText',
                    height: 1.5, // Line spacing
                  ),
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
          ],
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
          style: const TextStyle(
              fontSize: 16.0, color: Colors.white, fontFamily: 'SFCompactText',  height: 1.5,),
        ));
      }

      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
          fontFamily: 'SFCompactText',
           height: 1.5,
        ),
      ));

      lastIndex = match.end;
    }

    // Add any remaining text after the last match
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
            fontSize: 16.0,
            color: Colors.white, 
            fontFamily: 'SFCompactText',
            height: 1.5,
        ),
      ));
    }

    return spans;
  }
}