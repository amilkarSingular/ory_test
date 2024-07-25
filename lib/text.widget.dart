
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HighlightedText extends StatefulWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.onSelect,
    required this.onUpdate,
    required this.unSelect,
  });

  final String text;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onUpdate; // Change to ValueChanged<String> to pass selected text
  final VoidCallback unSelect;
  @override
  State<HighlightedText> createState() => HighlightedTextState();
}

class HighlightedTextState extends  State<HighlightedText> with SingleTickerProviderStateMixin {
  String fullText = ''; // This is the full text will be rendered
  String oldText = ''; // This is the old text user wants to replace
  String oldFullText = ''; // This is a kind of auxiliar to backup the latest Full text rendered, this will help Undo function works correctly
  TextSelection? currentSelection;
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
     _controller = TextEditingController(text: widget.text);
     fullText = widget.text;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _colorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.transparent,
    ).animate(_animationController);

    _animationController.addListener(() {
      setState(() {});
    });
  }

    @override
  void didUpdateWidget(covariant HighlightedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      setState(() {
        _controller.text = widget.text;
        fullText = widget.text;
      });
    }
  }

  void undo() {
    setState(() {
      final selection = currentSelection;
      if (selection != null && selection.isValid && !selection.isCollapsed) {
        print(fullText);
        print(oldFullText);
        print(oldText);
        print(_controller.text);
        final newTextContent = fullText.replaceRange(selection.start, selection.end, oldText);
        print(newTextContent);
        _controller.value = _controller.value.copyWith(
          text: newTextContent,
          selection: TextSelection(
            baseOffset: selection.start,
            extentOffset: selection.start + oldFullText.length,
          ),
        );
        fullText = newTextContent;
        print('NEWWWW');
        print(_controller.text);
        widget.onUpdate(newTextContent);

        // Update the selection to the new text
        currentSelection = TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + oldText.length,
        );

        _animationController.reset();
      }
    });

  }

  void replaceSelectedText(String newText) {
    setState(() {
      final oldText = _controller.text;
      final selection = currentSelection;
      if (selection != null && selection.isValid && !selection.isCollapsed) {
        final newTextContent = oldText.replaceRange(selection.start, selection.end, newText);
        _controller.value = _controller.value.copyWith(
          text: newTextContent,
          selection: TextSelection(
            baseOffset: selection.start,
            extentOffset: selection.start + newText.length,
          ),
        );
        fullText = newTextContent;
        widget.onUpdate(newTextContent);

        // Update the selection to the new text
        currentSelection = TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + newText.length,
        );

        // Start the highlight animation
        _animationController.forward(from: 0.0);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final TextPosition position = _controller.selection.base;
        final TextSelection newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: position.offset + 1,
        );
        setState(() {
          currentSelection = newSelection;
        });
      },
      child: SelectableText.rich(
        TextSpan(
          children: _buildTextSpans(),
        ),
        onSelectionChanged: (selection, cause) {
          currentSelection = selection;
          final start = selection.start;
          final end = selection.end;
          final selectedText = (start < end)
              ? fullText.substring(start, end)
              : fullText.substring(end, start);
          setState(() {
              oldText = selectedText;
          });
          if (selection.isCollapsed) {
            // No text selected
            widget.unSelect();
          } else if (cause == SelectionChangedCause.longPress) {
            // Text selected via long press
            widget.onSelect(selectedText);
          } else {
            // Text selection updated
            widget.onUpdate(selectedText);
          }
        },
      ),
    );
  }

    List<TextSpan> _buildTextSpans() {
    if (currentSelection == null) {
      return [TextSpan(text: fullText, style: const TextStyle(color: Colors.black))];
    }

    final List<TextSpan> spans = [];
    int start = 0;

    if (currentSelection!.start > 0) {
      spans.add(TextSpan(
        text: fullText.substring(0, currentSelection!.start),
        style: const TextStyle(color: Colors.black),
      ));
    }

    spans.add(TextSpan(
      text: fullText.substring(currentSelection!.start, currentSelection!.end),
      style: TextStyle(backgroundColor: _colorAnimation.value, color: Colors.black,),
    ));

    if (currentSelection!.end < fullText.length) {
      spans.add(TextSpan(
        text: fullText.substring(currentSelection!.end),
        style: const TextStyle(color: Colors.black),
      ));
    }

    return spans;
  }
}