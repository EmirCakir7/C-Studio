import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_assistant_service.dart';
import '../services/app_language_service.dart';
import 'settings_dialog.dart';
import 'ai_model_download_card.dart';

class AiPanel extends StatefulWidget {
  final String activeCode;
  final String? Function()? getActiveCode;
  final Function(String code)? onApplyCodeToEditor;
  final Function(String code)? onInsertCodeToCursor;

  const AiPanel({
    super.key,
    required this.activeCode,
    this.getActiveCode,
    this.onApplyCodeToEditor,
    this.onInsertCodeToCursor,
  });

  @override
  State<AiPanel> createState() => AiPanelState();
}

class AiPanelState extends State<AiPanel> {
  final TextEditingController _promptController = TextEditingController();
  final AiAssistantService _aiService = AiAssistantService();
  final AppLanguageService _langService = AppLanguageService();
  final ScrollController _scrollController = ScrollController();
  List<AiMessage> get _messages => _aiService.messages;
  bool _isLoading = false;

  String _getWelcomeMessage(String lang) {
    if (lang == 'tr') {
      return 'Merhaba! C-Studio Akıllı Kod Asistanına hoş geldiniz. 🚀\n\n'
          'Editörünüzde açık olan C kodunuz hakkında soru sorabilir, koddaki hataları düzelttirebilir veya optimize ettirebilirsiniz.\n\n'
          '💡 **İpucu:** Asistanın önerdiği kod bloğunun sağ üstündeki **"Editördeki Kodu Değiştir"** butonuna basarak doğrudan dosyanızı güncelleyebilirsiniz.';
    } else if (lang == 'de') {
      return 'Hallo! Willkommen beim C-Studio KI-Assistenten. 🚀\n\n'
          'Sie können Fragen zu Ihrem C-Code stellen, Fehler analysieren und beheben lassen oder Ihren Code optimieren.\n\n'
          '💡 **Tipp:** Klicken Sie auf **"Im Editor ersetzen"**, um vorgeschlagene Codeblöcke direkt in Ihre Datei zu übernehmen.';
    } else {
      return 'Hello! Welcome to the C-Studio AI Assistant. 🚀\n\n'
          'You can ask any questions about your C code, request bug fixes, or get help with algorithms.\n\n'
          '💡 **Tip:** Click **"Replace in Editor"** on any suggested code snippet to apply it directly to your file.';
    }
  }

  @override
  void initState() {
    super.initState();
    _langService.addListener(_onLanguageChanged);
    if (_aiService.messages.isEmpty) {
      _aiService.messages.add(
        AiMessage(
          text: _getWelcomeMessage(_aiService.language),
          isUser: false,
        ),
      );
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      if (_messages.length == 1 && !_messages.first.isUser) {
        _messages[0] = AiMessage(
          text: _getWelcomeMessage(_aiService.language),
          isUser: false,
        );
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _langService.removeListener(_onLanguageChanged);
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendUserPrompt(String promptText, {bool includeCode = true}) async {
    final text = promptText.trim();
    if (text.isEmpty || _isLoading) return;

    if (!_aiService.isReady) {
      final configured = await showDialog<bool>(
        context: context,
        builder: (context) => const SettingsDialog(initialTab: 1),
      );
      if (configured != true || !_aiService.isReady) {
        return;
      }
    }

    setState(() {
      _messages.add(AiMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();
    _promptController.clear();

    try {
      final currentCode = widget.getActiveCode?.call() ?? widget.activeCode;
      final historyBeforeThis = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : <AiMessage>[];

      final reply = await _aiService.sendPrompt(
        prompt: text,
        history: historyBeforeThis,
        currentCode: includeCode && currentCode.trim().isNotEmpty ? currentCode : null,
      );

      if (mounted) {
        setState(() {
          _messages.add(AiMessage(text: reply, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final lang = _aiService.language;
        final errMsg = lang == 'tr'
            ? '⚠️ Hata oluştu:\n$e'
            : (lang == 'de' ? '⚠️ Fehler aufgetreten:\n$e' : '⚠️ Error occurred:\n$e');
        setState(() {
          _messages.add(
            AiMessage(
              text: errMsg,
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void askAboutError(String errorContext) {
    sendUserPrompt(errorContext, includeCode: true);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const SettingsDialog(initialTab: 1),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF13141C),
      child: Column(
        children: [
          // 1. Üst Başlık Çubuğu
          _buildHeaderBar(),

          // 2. Hızlı Komutlar Çubuğu (Chips)
          _buildQuickActionChips(),

          // Model İndirme Kartı (Model yüklü değilse gösterilir)
          if (!_aiService.isReady)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: AiModelDownloadCard(
                onDownloadCompleted: () {
                  setState(() {});
                },
              ),
            ),

          // 3. Mesajlar Listesi
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // 4. Yükleniyor Göstergesi
          if (_isLoading) _buildLoadingIndicator(),

          // 5. Giriş ve Gönder Butonu Çubuğu
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    final isLocal = _aiService.isLocal;
    final isReady = _aiService.isReady;
    final lang = _aiService.language;
    final langService = _langService;

    final badgeLabel = lang == 'tr'
        ? AppLanguageService.turkishShortLabel
        : (lang == 'de' ? AppLanguageService.germanShortLabel : AppLanguageService.englishShortLabel);

    final Color badgeBg = !isReady
        ? const Color(0xFFFF9E64)
        : (isLocal ? const Color(0xFF9ECE6A) : const Color(0xFF7AA2F7));
    final IconData badgeIcon = !isReady
        ? Icons.download_rounded
        : (isLocal ? Icons.offline_bolt_rounded : Icons.cloud_done_rounded);
    final String badgeText = !isReady
        ? langService.trEnDe('Qwen 2.5 (Model İndir)', 'Qwen 2.5 (Download)', 'Qwen 2.5 (Herunterladen)')
        : (isLocal ? 'Qwen 2.5 Coder 1.5B' : _aiService.selectedModel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        border: Border(bottom: BorderSide(color: Color(0xFF24283B))),
      ),
      child: Row(
        children: [
          // Durum Rozeti
          InkWell(
            onTap: !isReady ? _openSettings : null,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badgeIcon,
                    color: const Color(0xFF13141C),
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF13141C)),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Dil Değiştirici Butonu (TR / EN / DE)
          InkWell(
            onTap: () {
              final current = _aiService.language;
              final newLang = current == 'tr' ? 'en' : (current == 'en' ? 'de' : 'tr');
              _langService.setUnifiedLanguage(newLang);
              _aiService.saveConfig(language: newLang);
              final switchMsg = newLang == 'tr'
                  ? '🇹🇷 Dil **Türkçe** olarak ayarlandı.'
                  : (newLang == 'de'
                      ? '🇩🇪 Sprache auf **Deutsch** umgestellt.'
                      : 'Language switched to **English**.');
              setState(() {
                _messages.add(
                  AiMessage(
                    text: switchMsg,
                    isUser: false,
                  ),
                );
              });
              _scrollToBottom();
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2335),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF292E42)),
              ),
              child: Text(
                badgeLabel,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFC0CAF5)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Ayarlar Butonu
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF7982A9)),
            tooltip: langService.trEnDe('Yapay Zeka Ayarları', 'AI Settings', 'KI-Einstellungen'),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),

          // Sohbeti Temizle
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF7982A9)),
            tooltip: langService.trEnDe('Sohbeti Temizle', 'Clear Chat', 'Chat leeren'),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChips() {
    final langService = _langService;

    return Container(
      height: 32,
      color: const Color(0xFF16161E).withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip(
            icon: Icons.auto_fix_high_rounded,
            label: langService.trEnDe(
              'Kodu İncele & Hataları Düzelt',
              'Fix Bugs & Provide Working Code',
              'Fehler prüfen & beheben',
            ),
            prompt: langService.trEnDe(
              'Editörümde açık olan C kodundaki tüm mantık ve derleme hatalarını tespit et, neyin yanlış olduğunu açıkla ve düzeltilmiş tam çalışan C kodunu ```c ve ``` blokları arasında ver.',
              'Detect all errors and bugs in my open C code, explain what went wrong, and provide the fully working corrected C code inside ```c and ``` code blocks.',
              'Finde alle Fehler im geöffneten C-Code, erkläre was falsch war und stelle den korrigierten lauffähigen C-Code in ```c und ``` Blöcken bereit.',
            ),
          ),
          _buildChip(
            icon: Icons.menu_book_rounded,
            label: langService.trEnDe(
              'Kodu Satır Satır Açıkla',
              'Explain Line by Line',
              'Code Zeile für Zeile erklären',
            ),
            prompt: langService.trEnDe(
              'Editörümde açık olan C kodunun ne yaptığını, algoritmik mantığını ve fonksiyonlarını anlaşılır bir şekilde satır satır açıkla.',
              'Explain what my open C code does, its algorithmic logic, and functions line-by-line in a clear manner.',
              'Erkläre verständlich und Zeile für Zeile die Logik und Funktionen meines geöffneten C-Codes.',
            ),
          ),
          _buildChip(
            icon: Icons.memory_rounded,
            label: langService.trEnDe(
              'Bellek & Pointer Kontrolü',
              'Memory & Pointer Check',
              'Speicher- & Zeigerprüfung',
            ),
            prompt: langService.trEnDe(
              'Editörümdeki C kodunun bellek yönetimini (malloc/free), göstericileri (pointer) ve dizi sınırlarını denetle, olası bellek sızıntılarını ve çözümlerini göster.',
              'Inspect memory management (malloc/free), pointers, and array bounds in my C code. Point out potential leaks and show fixes.',
              'Überprüfe die Speicherverwaltung (malloc/free), Zeiger und Arraygrenzen meines C-Codes auf Speicherlecks und zeige Lösungen.',
            ),
          ),
          _buildChip(
            icon: Icons.speed_rounded,
            label: langService.trEnDe(
              'Kodu Optimize Et',
              'Optimize Code',
              'Code optimieren',
            ),
            prompt: langService.trEnDe(
              'Editörümdeki C kodunu daha temiz, performanslı ve modern standartlara uygun hale getirmek için optimize et ve optimize edilmiş çalışan kodu ```c ve ``` blokları arasında ver.',
              'Optimize my open C code for better performance, safety, and cleaner structure, and provide the improved code inside ```c and ``` blocks.',
              'Optimiere meinen C-Code für bessere Leistung, Sicherheit und Struktur, und gib den verbesserten Code in ```c und ``` Blöcken aus.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String label, required String prompt}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
      child: ActionChip(
        avatar: Icon(icon, size: 12, color: const Color(0xFF7AA2F7)),
        label: Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFFC0CAF5))),
        backgroundColor: const Color(0xFF1F2335),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        side: const BorderSide(color: Color(0xFF292E42)),
        onPressed: () => sendUserPrompt(prompt),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage message) {
    final isUser = message.isUser;
    final langService = _langService;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF7AA2F7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.psychology_rounded, size: 16, color: Color(0xFF7AA2F7)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2E3440) : const Color(0xFF1A1B26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUser ? const Color(0xFF7AA2F7).withValues(alpha: 0.4) : const Color(0xFF24283B),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Row(
                      children: [
                        Text(
                          langService.trEnDe('Dahili AI Asistanı', 'Offline AI Tutor', 'Lokaler KI-Assistent'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7AA2F7),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF7982A9)),
                          tooltip: langService.trEnDe('Tüm Yanıtı Kopyala', 'Copy Full Response', 'Gesamte Antwort kopieren'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  langService.trEnDe(
                                    'Yanıt panoya kopyalandı',
                                    'Response copied to clipboard',
                                    'Antwort in Zwischenablage kopiert',
                                  ),
                                ),
                              ),
                            );
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  if (!isUser) const SizedBox(height: 6),
                  _buildFormattedContent(message.text, isUser),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF3B4261),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFFC0CAF5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String text, bool isUser) {
    if (isUser) {
      return Text(
        text,
        style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white, height: 1.4),
      );
    }

    // Kod bloklarını (```c ... ```) ayrıştır
    final parts = <Widget>[];
    final regExp = RegExp(r'```(?:c|C)?\s*([\s\S]*?)```', multiLine: true);
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        final normalText = text.substring(lastIndex, match.start).trim();
        if (normalText.isNotEmpty) {
          parts.add(
            Text(
              normalText,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFC0CAF5), height: 1.45),
            ),
          );
        }
      }

      final codeContent = match.group(1)?.trim() ?? '';
      if (codeContent.isNotEmpty) {
        parts.add(_buildCodeBlock(codeContent));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        parts.add(
          Text(
            remaining,
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFC0CAF5), height: 1.45),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.isEmpty
          ? [
              Text(
                text,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFC0CAF5), height: 1.45),
              )
            ]
          : parts,
    );
  }

  Widget _buildCodeBlock(String code) {
    final langService = _langService;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10111A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF24283B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, size: 13, color: Color(0xFF7AA2F7)),
                const SizedBox(width: 6),
                Text(
                  langService.trEnDe('C Kodu', 'C Snippet', 'C-Code'),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7982A9)),
                ),
                const Spacer(),
                if (widget.onApplyCodeToEditor != null) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: Text(
                      langService.trEnDe('Editördeki Kodu Değiştir', 'Replace in Editor', 'Im Editor ersetzen'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9ECE6A),
                      foregroundColor: const Color(0xFF13141C),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => widget.onApplyCodeToEditor!(code),
                  ),
                  const SizedBox(width: 6),
                ],
                if (widget.onInsertCodeToCursor != null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 13),
                    label: Text(
                      langService.trEnDe('İmlece Ekle', 'Insert at Cursor', 'Am Cursor einfügen'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7AA2F7),
                      side: const BorderSide(color: Color(0xFF7AA2F7)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => widget.onInsertCodeToCursor!(code),
                  ),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF7982A9)),
                  tooltip: langService.trEnDe('Kodu Kopyala', 'Copy Code', 'Code kopieren'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          langService.trEnDe('Kod kopyalandı!', 'Code copied!', 'Code kopiert!'),
                        ),
                      ),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SelectableText(
              code,
              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFFC0CAF5), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final langService = _langService;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7AA2F7)),
          ),
          const SizedBox(width: 10),
          Text(
            langService.trEnDe(
              'Yapay zeka analiz ediyor ve düşünüyor...',
              'AI assistant is analyzing and reasoning...',
              'KI-Assistent analysiert und überlegt...',
            ),
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF7AA2F7), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final langService = _langService;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        border: Border(top: BorderSide(color: Color(0xFF24283B))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white),
              decoration: InputDecoration(
                hintText: langService.trEnDe(
                  'C dili, mantık veya hatalar hakkında soru sorun... (Örn: Pointer nedir?)',
                  'Ask about C concepts, logic, or errors... (e.g. What is a pointer?)',
                  'Fragen zu C-Konzepten, Logik oder Fehlern stellen... (z. B. Was ist ein Pointer?)',
                ),
                hintStyle: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF565F89)),
                filled: true,
                fillColor: const Color(0xFF13141C),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF24283B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF24283B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF7AA2F7)),
                ),
                isDense: true,
              ),
              onSubmitted: (val) => sendUserPrompt(val),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 14),
            label: Text(
              langService.trEnDe('Sor', 'Ask', 'Fragen'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7AA2F7),
              foregroundColor: const Color(0xFF13141C),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _isLoading ? null : () => sendUserPrompt(_promptController.text),
          ),
        ],
      ),
    );
  }
}
