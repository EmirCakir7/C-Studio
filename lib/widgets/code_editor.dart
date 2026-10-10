import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CSyntaxTextController extends TextEditingController {
  CSyntaxTextController({super.text});

  static final RegExp _keywords = RegExp(
    r'\b(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|_Bool|_Complex|_Imaginary|bool|true|false)\b',
  );

  static final RegExp _typesAndFuncs = RegExp(
    r'\b(printf|scanf|puts|gets|getchar|putchar|fopen|fclose|fprintf|fscanf|sscanf|sprintf|fgets|fputs|malloc|free|calloc|realloc|exit|system|atoi|atof|rand|srand|sqrt|pow|sin|cos|tan|fabs|strlen|strcpy|strcmp|strcat|strncpy|memset|memcpy|FILE|NULL|size_t)\b',
  );

  static final RegExp _preproc = RegExp(
    r'^[ \t]*#[ \t]*(include|define|undef|if|ifdef|ifndef|elif|else|endif|pragma|error|line).*',
    multiLine: true,
  );

  static final RegExp _numbers = RegExp(r'\b(0x[0-9a-fA-F]+|\d+(\.\d+)?f?)\b');
  static final RegExp _strings = RegExp(r'("(?:[^"\\]|\\.)*"|' r"'(?:[^'\\]|\\.)*')");
  static final RegExp _comments = RegExp(r'(//.*$)|(/\*[\s\S]*?\*/)', multiLine: true);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    final List<TextSpan> spans = [];

    final baseStyle = style ?? GoogleFonts.jetBrainsMono(fontSize: 14, color: const Color(0xFFC0CAF5));

    if (text.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    // Tokenization with regex scanning
    int lastIndex = 0;

    // We collect all styled matches into an interval list
    final List<_HighlightToken> tokens = [];

    for (final m in _comments.allMatches(text)) {
      tokens.add(_HighlightToken(m.start, m.end, const TextStyle(color: Color(0xFF565F89), fontStyle: FontStyle.italic)));
    }
    for (final m in _preproc.allMatches(text)) {
      tokens.add(_HighlightToken(m.start, m.end, const TextStyle(color: Color(0xFFBB9AF7), fontWeight: FontWeight.bold)));
    }
    for (final m in _strings.allMatches(text)) {
      tokens.add(_HighlightToken(m.start, m.end, const TextStyle(color: Color(0xFFE0AF68))));
    }
    for (final m in _keywords.allMatches(text)) {
      tokens.add(_HighlightToken(m.start, m.end, const TextStyle(color: Color(0xFF7AA2F7), fontWeight: FontWeight.bold)));
    }
    for (final m in _typesAndFuncs.allMatches(text)) {
      tokens.add(_HighlightToken(m.start, m.end, const TextStyle(color: Color(0xFF7DCFFF))));
    }
    for (final m in _numbers.allMatches(text)) {
      tokens.add(_HighlightToken(m.start, m.end, const TextStyle(color: Color(0xFF9ECE6A))));
    }

    // Sort tokens by start position
    tokens.sort((a, b) => a.start.compareTo(b.start));

    // Filter overlapping tokens (first token wins)
    final List<_HighlightToken> nonOverlapping = [];
    int currentEnd = 0;
    for (final t in tokens) {
      if (t.start >= currentEnd) {
        nonOverlapping.add(t);
        currentEnd = t.end;
      }
    }

    // Build the TextSpan tree
    for (final t in nonOverlapping) {
      if (t.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, t.start), style: baseStyle));
      }
      spans.add(TextSpan(text: text.substring(t.start, t.end), style: baseStyle.merge(t.style)));
      lastIndex = t.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return TextSpan(children: spans);
  }
}

class _HighlightToken {
  final int start;
  final int end;
  final TextStyle style;

  _HighlightToken(this.start, this.end, this.style);
}

class CodeEditor extends StatefulWidget {
  final CSyntaxTextController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final Set<int> errorLines;
  final VoidCallback? onCursorChanged;

  const CodeEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.errorLines = const {},
    this.onCursorChanged,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _gutterController = ScrollController();

  int _lineCount = 1;
  int _currentLine = 1;

  @override
  void initState() {
    super.initState();
    _updateMetrics();
    widget.controller.addListener(_handleTextChange);
    _scrollController.addListener(_syncScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncScroll);
    widget.controller.removeListener(_handleTextChange);
    _scrollController.dispose();
    _gutterController.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (_gutterController.hasClients) {
      _gutterController.jumpTo(_scrollController.offset);
    }
  }

  void _handleTextChange() {
    _updateMetrics();
    widget.onCursorChanged?.call();
  }

  void _updateMetrics() {
    final text = widget.controller.text;
    final lines = text.split('\n');
    final count = lines.isEmpty ? 1 : lines.length;

    final sel = widget.controller.selection;
    int line = 1;
    if (sel.baseOffset >= 0 && sel.baseOffset <= text.length) {
      final prefix = text.substring(0, sel.baseOffset);
      final preLines = prefix.split('\n');
      line = preLines.length;
    }

    if (mounted) {
      setState(() {
        _lineCount = count;
        _currentLine = line;
      });
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        // Tab tuşu 4 boşluk eklesin
        final text = widget.controller.text;
        final sel = widget.controller.selection;
        final newText = text.replaceRange(sel.start, sel.end, '    ');
        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: sel.start + 4),
        );
        widget.onChanged?.call(newText);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final monoStyle = GoogleFonts.jetBrainsMono(
      fontSize: 13.5,
      height: 1.5,
      color: const Color(0xFFC0CAF5),
    );

    return Focus(
      onKeyEvent: _handleKey,
      child: Container(
        color: const Color(0xFF16161E),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line numbers gutter
            Container(
              width: 58,
              decoration: const BoxDecoration(
                color: Color(0xFF13141C),
                border: Border(
                  right: BorderSide(color: Color(0xFF24283B), width: 1),
                ),
              ),
              child: ListView.builder(
                controller: _gutterController,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 16, bottom: 200, right: 10),
                itemCount: _lineCount,
                itemBuilder: (context, index) {
                  final lineNum = index + 1;
                  final isCur = lineNum == _currentLine;
                  final isErr = widget.errorLines.contains(lineNum);

                  return Container(
                    height: 20.25, // Matches line height
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isErr)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF7768E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          '$lineNum',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                            color: isErr
                                ? const Color(0xFFF7768E)
                                : (isCur ? const Color(0xFF7AA2F7) : const Color(0xFF414868)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Code text field
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  maxLines: null,
                  style: monoStyle,
                  cursorColor: const Color(0xFF7AA2F7),
                  cursorWidth: 2,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
