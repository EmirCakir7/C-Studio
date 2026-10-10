import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_assistant_service.dart';
import '../services/app_language_service.dart';
import 'settings_dialog.dart';

class AiPanel extends StatefulWidget {
  final String activeCode;
  final ValueGetter<String>? getActiveCode;
  final ValueChanged<String>? onApplyCodeToEditor;
  final ValueChanged<String>? onInsertCodeToCursor;

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
  final AiAssistantService _aiService = AiAssistantService();
  final AppLanguageService _langService = AppLanguageService();
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<AiMessage> get _messages => _aiService.messages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _langService.addListener(_onLanguageChanged);
    if (_aiService.messages.isEmpty) {
      final isTr = _aiService.isTurkish;
      _aiService.messages.add(
        AiMessage(
          text: isTr
              ? 'Merhaba! C-Studio Akıllı Kod Asistanına hoş geldiniz. 🚀\n\n'
                  'Editörünüzde açık olan C kodunuz hakkında soru sorabilir, koddaki hataları düzelttirebilir veya optimize ettirebilirsiniz.\n\n'
                  '💡 **İpucu:** Asistanın önerdiği kod bloğunun sağ üstündeki **"Editördeki Kodu Değiştir"** butonuna basarak doğrudan dosyanızı güncelleyebilirsiniz.'
              : 'Hello! Welcome to the C-Studio AI Assistant. 🚀\n\n'
                  'You can ask any questions about your C code, request bug fixes, or get help with algorithms.\n\n'
                  '💡 **Tip:** Click **"Replace in Editor"** on any suggested code snippet to apply it directly to your file.',
          isUser: false,
        ),
      );
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      if (_messages.length == 1 && !_messages.first.isUser) {
        final isTr = _aiService.isTurkish;
        _messages[0] = AiMessage(
          text: isTr
              ? 'Merhaba! C-Studio Akıllı Kod Asistanına hoş geldiniz. 🚀\n\n'
                  'Editörünüzde açık olan C kodunuz hakkında soru sorabilir, koddaki hataları düzelttirebilir veya optimize ettirebilirsiniz.\n\n'
                  '💡 **İpucu:** Asistanın önerdiği kod bloğunun sağ üstündeki **"Editördeki Kodu Değiştir"** butonuna basarak doğrudan dosyanızı güncelleyebilirsiniz.'
              : 'Hello! Welcome to the C-Studio AI Assistant. 🚀\n\n'
                  'You can ask any questions about your C code, request bug fixes, or get help with algorithms.\n\n'
                  '💡 **Tip:** Click **"Replace in Editor"** on any suggested code snippet to apply it directly to your file.',
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
        setState(() {
          _messages.add(
            AiMessage(
              text: _aiService.isTurkish ? '❌ Hata oluştu:\n$e' : '❌ Error occurred:\n$e',
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openSettings() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => const SettingsDialog(initialTab: 1),
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF13141C),
      child: Column(
        children: [
          // 1. Üst Başlık & Araç Çubuğu
          _buildHeaderBar(),

          // 2. Hızlı Komut Çipleri
          _buildQuickActionChips(),

          // 3. Mesaj Listesi
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // 4. Yükleniyor Göstergesi
          if (_isLoading) _buildLoadingIndicator(),

          // 5. Giriş ve Soru Çubuğu
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    final isLocal = _aiService.isLocal;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        border: Border(bottom: BorderSide(color: Color(0xFF24283B))),
      ),
      child: Row(
        children: [
          // Model Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: isLocal ? const Color(0xFF9ECE6A) : const Color(0xFF7AA2F7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLocal ? Icons.offline_bolt_rounded : Icons.auto_awesome,
                  color: const Color(0xFF13141C),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  isLocal ? 'Qwen 2.5 Coder 1.5B' : _aiService.selectedModel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF13141C)),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Dil Değiştirici Butonu (TR / EN)
          InkWell(
            onTap: () {
              final newLang = _aiService.isTurkish ? 'en' : 'tr';
              _langService.setUnifiedLanguage(newLang);
              _aiService.saveConfig(language: newLang);
              setState(() {
                _messages.add(
                  AiMessage(
                    text: newLang == 'tr'
                        ? '🇹🇷 Dil **Türkçe** olarak ayarlandı.'
                        : 'Language switched to **English**.',
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
                _aiService.isTurkish ? '🇹🇷 TR' : 'EN',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFC0CAF5)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Ayarlar Butonu
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF7982A9)),
            tooltip: _aiService.isTurkish ? 'Yapay Zeka Ayarları' : 'AI Settings',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),

          // Sohbeti Temizle
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF7982A9)),
            tooltip: _aiService.isTurkish ? 'Sohbeti Temizle' : 'Clear Chat',
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
    final isTr = _aiService.isTurkish;

    return Container(
      height: 32,
      color: const Color(0xFF16161E).withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip(
            icon: Icons.auto_fix_high_rounded,
            label: isTr ? 'Kodu İncele & Hataları Düzelt' : 'Fix Bugs & Provide Working Code',
            prompt: isTr
                ? 'Editörümde açık olan C kodundaki tüm mantık ve derleme hatalarını tespit et, neyin yanlış olduğunu açıkla ve düzeltilmiş tam çalışan C kodunu ```c ve ``` blokları arasında ver.'
                : 'Detect all errors and bugs in my open C code, explain what went wrong, and provide the fully working corrected C code inside ```c and ``` code blocks.',
          ),
          _buildChip(
            icon: Icons.menu_book_rounded,
            label: isTr ? 'Kodu Satır Satır Açıkla' : 'Explain Line by Line',
            prompt: isTr
                ? 'Editörümde açık olan C kodunun ne yaptığını, algoritmik mantığını ve fonksiyonlarını anlaşılır bir şekilde satır satır açıkla.'
                : 'Explain what my open C code does, its algorithmic logic, and functions line-by-line in a clear manner.',
          ),
          _buildChip(
            icon: Icons.memory_rounded,
            label: isTr ? 'Bellek & Pointer Kontrolü' : 'Memory & Pointer Check',
            prompt: isTr
                ? 'Editörümdeki C kodunun bellek yönetimini (malloc/free), göstericileri (pointer) ve dizi sınırlarını denetle, olası bellek sızıntılarını ve çözümlerini göster.'
                : 'Inspect memory management (malloc/free), pointers, and array bounds in my C code. Point out potential leaks and show fixes.',
          ),
          _buildChip(
            icon: Icons.speed_rounded,
            label: isTr ? 'Kodu Optimize Et' : 'Optimize Code',
            prompt: isTr
                ? 'Editörümdeki C kodunu daha temiz, performanslı ve modern standartlara uygun hale getirmek için optimize et ve optimize edilmiş çalışan kodu ```c ve ``` blokları arasında ver.'
                : 'Optimize my open C code for better performance, safety, and cleaner structure, and provide the improved code inside ```c and ``` blocks.',
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
        onPressed: _isLoading ? null : () => sendUserPrompt(prompt),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 650),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2248),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF7AA2F7).withValues(alpha: 0.3)),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white, height: 1.4),
          ),
        ),
      );
    }

    // AI Cevabı
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 750),
        decoration: BoxDecoration(
          color: const Color(0xFF16161E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF24283B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF7AA2F7), size: 14),
                const SizedBox(width: 6),
                Text(
                  _aiService.isTurkish ? 'Dahili AI Asistanı' : 'Offline AI Tutor',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7AA2F7),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF7982A9)),
                  tooltip: _aiService.isTurkish ? 'Tüm Yanıtı Kopyala' : 'Copy Full Response',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_aiService.isTurkish ? 'Yanıt panoya kopyalandı' : 'Response copied to clipboard')),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(color: Color(0xFF24283B), height: 16),
            _renderMarkdownText(msg.text),
          ],
        ),
      ),
    );
  }

  Widget _renderMarkdownText(String text) {
    final parts = <Widget>[];
    final lines = text.split('\n');

    bool inCodeBlock = false;
    final codeBuffer = StringBuffer();

    for (final line in lines) {
      if (line.trim().startsWith('```')) {
        if (!inCodeBlock) {
          inCodeBlock = true;
          codeBuffer.clear();
        } else {
          inCodeBlock = false;
          final code = codeBuffer.toString().trim();
          parts.add(_buildCodeBlock(code));
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuffer.writeln(line);
      } else {
        if (line.trim().isNotEmpty) {
          parts.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText(
                line,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFC0CAF5), height: 1.45),
              ),
            ),
          );
        } else {
          parts.add(const SizedBox(height: 6));
        }
      }
    }

    if (inCodeBlock) {
      parts.add(_buildCodeBlock(codeBuffer.toString().trim()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  Widget _buildCodeBlock(String code) {
    final isTr = _aiService.isTurkish;

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
                Text(isTr ? 'C Kodu' : 'C Snippet', style: const TextStyle(fontSize: 11, color: Color(0xFF7982A9))),
                const Spacer(),
                if (widget.onApplyCodeToEditor != null) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: Text(isTr ? 'Editördeki Kodu Değiştir' : 'Replace in Editor'),
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
                    label: Text(isTr ? 'İmlece Ekle' : 'Insert at Cursor'),
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
                  tooltip: isTr ? 'Kodu Kopyala' : 'Copy Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isTr ? 'Kod kopyalandı!' : 'Code copied!')),
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
    final isTr = _aiService.isTurkish;
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
            isTr
                ? 'Yapay zeka analiz ediyor ve düşünüyor...'
                : 'AI assistant is analyzing and reasoning...',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF7AA2F7), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final isTr = _aiService.isTurkish;
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
                hintText: isTr
                    ? 'C dili, mantık veya hatalar hakkında soru sorun... (Örn: Pointer nedir?)'
                    : 'Ask about C concepts, logic, or errors... (e.g. What is a pointer?)',
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
            label: Text(isTr ? 'Sor' : 'Ask', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
