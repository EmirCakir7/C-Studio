import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_language_service.dart';

class TerminalPanel extends StatefulWidget {
  final String output;
  final bool isRunning;
  final ValueChanged<String> onSendInput;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final VoidCallback? onRun;

  const TerminalPanel({
    super.key,
    required this.output,
    required this.isRunning,
    required this.onSendInput,
    required this.onStop,
    required this.onClear,
    this.onRun,
  });

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void didUpdateWidget(covariant TerminalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.output != oldWidget.output) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
    if (widget.isRunning && !oldWidget.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _submitInput() {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      widget.onSendInput(text);
      _inputController.clear();
      _inputFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = AppLanguageService();

    return Container(
      color: const Color(0xFF13141C),
      child: Column(
        children: [
          // Üst Konsol Araç Çubuğu
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              border: Border(bottom: BorderSide(color: Color(0xFF24283B))),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isRunning ? const Color(0xFF9ECE6A) : const Color(0xFF565F89),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isRunning
                      ? langService.trEnDe('Program Çalışıyor...', 'Program Running...', 'Programm läuft...')
                      : langService.trEnDe('Terminal Hazır', 'Terminal Ready', 'Terminal bereit'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isRunning ? const Color(0xFF9ECE6A) : const Color(0xFF7982A9),
                  ),
                ),
                const Spacer(),
                if (widget.isRunning)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.stop_rounded, size: 13, color: Color(0xFFF7768E)),
                    label: Text(
                      langService.trEnDe('Programı Durdur', 'Stop Program', 'Programm anhalten'),
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFF7768E)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF7768E)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: widget.onStop,
                  )
                else if (widget.onRun != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 15),
                    label: Text(
                      langService.trEnDe('Programı Çalıştır (F5)', 'Run Program (F5)', 'Programm ausführen (F5)'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9ECE6A),
                      foregroundColor: const Color(0xFF13141C),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      elevation: 0,
                    ),
                    onPressed: widget.onRun,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFF7982A9)),
                  tooltip: langService.trEnDe('Terminali Temizle', 'Clear Terminal', 'Terminal leeren'),
                  onPressed: widget.onClear,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Çıktı Alanı
          Expanded(
            child: Container(
              color: const Color(0xFF10111A),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: widget.output.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            langService.trEnDe(
                              'Programınızı çalıştırmak için butona veya F5 tuşuna basın.\nÇıktılar ve sonuçlar burada canlı olarak görüntülenecektir.',
                              'Press the button or F5 to run your program.\nOutput and results will appear here in real time.',
                              'Drücken Sie die Taste oder F5, um das Programm auszuführen.\nAusgaben und Ergebnisse werden hier live angezeigt.',
                            ),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF565F89), height: 1.5),
                          ),
                          if (widget.onRun != null) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: Text(
                                langService.trEnDe('▶ Programı Çalıştır (F5)', '▶ Run Program (F5)', '▶ Programm ausführen (F5)'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9ECE6A),
                                foregroundColor: const Color(0xFF13141C),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: widget.onRun,
                            ),
                          ],
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: SelectableText(
                        widget.output,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.5,
                          height: 1.45,
                          color: const Color(0xFFC0CAF5),
                        ),
                      ),
                    ),
            ),
          ),

          // Alt İnteraktif Girdi Çubuğu (scanf için)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              border: Border(top: BorderSide(color: Color(0xFF24283B))),
            ),
            child: Row(
              children: [
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF7AA2F7)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    enabled: widget.isRunning,
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: widget.isRunning
                          ? langService.trEnDe(
                              'Buraya girdi yazıp Enter\'a basın (scanf için)...',
                              'Type input here and press Enter (for scanf)...',
                              'Eingabe eingeben und Enter drücken (für scanf)...',
                            )
                          : langService.trEnDe(
                              'Program çalışırken buradan girdi gönderebilirsiniz',
                              'Send input here while program is running',
                              'Eingabe senden während das Programm läuft',
                            ),
                      hintStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF414868)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _submitInput(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 14, color: Color(0xFF7AA2F7)),
                  tooltip: langService.trEnDe('Gönder', 'Send', 'Senden'),
                  onPressed: widget.isRunning ? _submitInput : null,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
