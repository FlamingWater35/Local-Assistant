import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../i18n/generated/translations.g.dart';

class ThrottledMarkdownWidget extends StatefulWidget {
  const ThrottledMarkdownWidget({
    super.key,
    required this.text,
    required this.isGenerating,
    this.style,
  });

  final bool isGenerating;
  final TextStyle? style;
  final String text;

  @override
  State<ThrottledMarkdownWidget> createState() =>
      _ThrottledMarkdownWidgetState();
}

class _ThrottledMarkdownWidgetState extends State<ThrottledMarkdownWidget> {
  late String _displayedText;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant ThrottledMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      if (!widget.isGenerating) {
        _timer?.cancel();
        setState(() {
          _displayedText = widget.text;
        });
      } else {
        if (_timer == null || !_timer!.isActive) {
          _timer = Timer(const Duration(milliseconds: 250), () {
            if (mounted) {
              setState(() {
                _displayedText = widget.text;
              });
            }
          });
        }
      }
    } else if (oldWidget.isGenerating && !widget.isGenerating) {
      _timer?.cancel();
      setState(() {
        _displayedText = widget.text;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _displayedText = widget.text;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);

    final bool showPlaceholder = widget.isGenerating && _displayedText.isEmpty;
    final String textToRender = showPlaceholder
        ? t.chat.generating
        : _displayedText;

    return RepaintBoundary(
      child: GptMarkdown(
        textToRender,
        style: showPlaceholder
            ? widget.style?.copyWith(
                fontStyle: FontStyle.italic,
                color: widget.style?.color?.withValues(alpha: 0.7),
              )
            : widget.style,
        useDollarSignsForLatex: true,
      ),
    );
  }
}
