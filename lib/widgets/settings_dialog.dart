import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../services/ai_assistant_service.dart';
import '../services/app_language_service.dart';
import '../services/compiler_service.dart';
import '../services/file_dialog_service.dart';
import 'ai_model_download_card.dart';

class SettingsDialog extends StatefulWidget {
  final int initialTab;

  const SettingsDialog({super.key, this.initialTab = 0});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AiAssistantService _aiService = AiAssistantService();
  final AppLanguageService _langService = AppLanguageService();
  final CompilerService _compilerService = CompilerService();

  late String _selectedUiLanguage;
  late String _selectedAiLanguage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _selectedUiLanguage = _langService.uiLanguage;
    _selectedAiLanguage = _langService.aiLanguage;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveAndApply() {
    _langService.setUiLanguage(_selectedUiLanguage, syncAiLanguage: false);
    _langService.setAiLanguage(_selectedAiLanguage);
    Navigator.of(context).pop(true);
  }

  Future<void> _handleImportCustomLanguage() async {
    final path = await FileDialogService.pickCustomLanguageFile();
    if (path == null) return;

    try {
      final file = File(path);
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! Map) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _langService.trEnDe('Geçersiz dil dosyası formatı!', 'Invalid language file format!', 'Ungültiges Sprachdateiformat!'),
              ),
              backgroundColor: const Color(0xFFF7768E),
            ),
          );
        }
        return;
      }

      String suggestedName = '';
      if (data.containsKey('language_name') && data['language_name'] != null) {
        suggestedName = data['language_name'].toString();
      } else {
        suggestedName = p.basenameWithoutExtension(path).replaceAll('.cstudio-lang', '');
      }

      final textController = TextEditingController(text: suggestedName);

      if (!mounted) return;

      // Ask for language name in English as requested by user
      final languageName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16161E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF24283B)),
          ),
          title: Row(
            children: [
              const Icon(Icons.language_rounded, color: Color(0xFF7AA2F7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Custom Language Name',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the display name for this language (e.g., Español, Français, Italiano):',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC0CAF5)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF13141C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'e.g. Español',
                  hintStyle: const TextStyle(color: Color(0xFF565F89)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF7982A9))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7AA2F7),
                foregroundColor: const Color(0xFF13141C),
              ),
              onPressed: () {
                final name = textController.text.trim();
                Navigator.of(ctx).pop(name.isEmpty ? suggestedName : name);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      );

      if (languageName == null || languageName.isEmpty) return;

      final success = await _langService.importCustomLanguageFile(path, languageName);
      if (success) {
        setState(() {
          _selectedUiLanguage = 'custom';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _langService.trEnDe(
                  '✔ "$languageName" dili başarıyla uygulandı!',
                  '✔ Language "$languageName" applied successfully!',
                  '✔ Sprache "$languageName" erfolgreich angewendet!',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF9ECE6A),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing language: $e'),
            backgroundColor: const Color(0xFFF7768E),
          ),
        );
      }
    }
  }

  void _openLanguageCreatorTool() {
    try {
      final exeCandidates = [
        p.join(Directory.current.path, 'C-Studio_Language_Creator.exe'),
        p.join(Directory.current.path, 'tools', 'language_creator', 'C-Studio_Language_Creator.exe'),
        p.join(Directory.current.path, 'tools', 'language_translator', 'C-Studio_Language_Creator.exe'),
      ];

      for (final exePath in exeCandidates) {
        if (File(exePath).existsSync()) {
          Process.start(exePath, []);
          return;
        }
      }

      final htmlCandidates = [
        p.join(Directory.current.path, 'C-Studio_Language_Pack_Creator.html'),
        p.join(Directory.current.path, 'tools', 'language_translator', 'C-Studio_Language_Pack_Creator.html'),
      ];

      for (final c in htmlCandidates) {
        if (File(c).existsSync()) {
          Process.start('explorer.exe', [c]);
          return;
        }
      }

      Process.start('explorer.exe', [htmlCandidates.first]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1B26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24283B), width: 1),
      ),
      child: Container(
        width: 660,
        height: 520,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7AA2F7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF7AA2F7), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _langService.trEnDe('C-Studio Ayarları', 'C-Studio Settings', 'C-Studio Einstellungen'),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      _langService.trEnDe(
                        'Arayüz dili, yapay zeka asistanı ve derleyici tercihleri',
                        'Interface language, AI assistant, and compiler preferences',
                        'Oberflächensprache, KI-Assistent und Compiler-Einstellungen',
                      ),
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF7982A9)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Sekme Çubuğu (Tab Bar)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13141C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF24283B)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1F2335),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFF7AA2F7).withValues(alpha: 0.5)),
                ),
                labelColor: const Color(0xFF7AA2F7),
                unselectedLabelColor: const Color(0xFF7982A9),
                labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    text: _langService.trEnDe('Genel', 'General', 'Allgemein'),
                  ),
                  Tab(
                    icon: const Icon(Icons.psychology_rounded, size: 16),
                    text: _langService.trEnDe('Yapay Zeka', 'AI Assistant', 'KI-Assistent'),
                  ),
                  Tab(
                    icon: const Icon(Icons.memory_rounded, size: 16),
                    text: _langService.trEnDe('Derleyici', 'Compiler', 'Compiler'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Sekme İçerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(),
                  _buildAiTab(),
                  _buildCompilerTab(),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Alt Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    _langService.trEnDe('İptal', 'Cancel', 'Abbrechen'),
                    style: const TextStyle(color: Color(0xFF7982A9)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(_langService.trEnDe('Kaydet ve Uygula', 'Save and Apply', 'Speichern und Anwenden')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AA2F7),
                    foregroundColor: const Color(0xFF13141C),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: _saveAndApply,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: GENEL AYARLAR
  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: _langService.trEnDe('Uygulama Arayüz Dili', 'Application UI Language', 'Benutzeroberflächensprache'),
            subtitle: _langService.trEnDe(
              'Menülerin, butonların ve durum çubuğunun görüntüleneceği dil',
              'The language displayed on menus, buttons, and status bar',
              'Die für Menüs, Schaltflächen und Statusleiste verwendete Sprache',
            ),
            icon: Icons.language_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLanguageOptionCard(
                label: AppLanguageService.turkishLabel,
                isSelected: _selectedUiLanguage == 'tr',
                onTap: () {
                  setState(() {
                    _selectedUiLanguage = 'tr';
                    _selectedAiLanguage = 'tr';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildLanguageOptionCard(
                label: AppLanguageService.englishLabel,
                isSelected: _selectedUiLanguage == 'en',
                onTap: () {
                  setState(() {
                    _selectedUiLanguage = 'en';
                    _selectedAiLanguage = 'en';
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildLanguageOptionCard(
                label: AppLanguageService.germanLabel,
                isSelected: _selectedUiLanguage == 'de',
                onTap: () {
                  setState(() {
                    _selectedUiLanguage = 'de';
                    _selectedAiLanguage = 'de';
                  });
                },
              ),
              if (_langService.hasCustomLanguage || _selectedUiLanguage == 'custom') ...[
                const SizedBox(width: 8),
                _buildLanguageOptionCard(
                  label: '🌐 ${_langService.customLanguageName ?? "Custom"}',
                  isSelected: _selectedUiLanguage == 'custom',
                  onTap: () {
                    setState(() {
                      _selectedUiLanguage = 'custom';
                      _selectedAiLanguage = 'custom';
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF13141C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF24283B)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBB9AF7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.file_upload_outlined, color: Color(0xFFBB9AF7), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _langService.trEnDe(
                          'Özel Dil Paketi (.cstudio-lang / .json)',
                          'Custom Language Pack (.cstudio-lang / .json)',
                          'Benutzerdefiniertes Sprachpaket (.cstudio-lang / .json)',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC0CAF5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _langService.trEnDe(
                          'Kendi dil dosyanızı içe aktarın veya çeviri aracını açın',
                          'Import your own language file or open the translation tool',
                          'Importieren Sie Ihre Sprachdatei oder öffnen Sie das Übersetzungstool',
                        ),
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF565F89)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _openLanguageCreatorTool,
                  icon: const Icon(Icons.open_in_browser_rounded, size: 14),
                  label: Text(_langService.trEnDe('Çeviri Aracı', 'Creator Tool', 'Editor-Tool')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7AA2F7),
                    side: const BorderSide(color: Color(0xFF7AA2F7)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: _handleImportCustomLanguage,
                  icon: const Icon(Icons.file_open_rounded, size: 14),
                  label: Text(_langService.trEnDe('İçe Aktar...', 'Import File...', 'Importieren...')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBB9AF7),
                    foregroundColor: const Color(0xFF1A1B26),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(
            title: _langService.trEnDe('Otomatik Kaydetme', 'Auto-Save', 'Automatisches Speichern'),
            subtitle: _langService.trEnDe(
              'Yazarken kod dosyalarını otomatik olarak arka planda kaydeder',
              'Automatically saves code files in background as you type',
              'Speichert Codedateien während der Eingabe automatisch im Hintergrund',
            ),
            icon: Icons.save_rounded,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF13141C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF24283B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.autorenew_rounded, size: 18, color: Color(0xFF9ECE6A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _langService.trEnDe(
                      'Her tuş vuruşundan sonra otomatik kaydet',
                      'Auto-save after each modification',
                      'Nach jeder Änderung automatisch speichern',
                    ),
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC0CAF5)),
                  ),
                ),
                Switch(
                  value: true,
                  onChanged: (val) {},
                  activeThumbColor: const Color(0xFF7AA2F7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(
            title: _langService.trEnDe('Hakkında', 'About', 'Über'),
            subtitle: _langService.trEnDe(
              'C-Studio Modern C IDE v1.2 (Portable Windows Edition)\nÖğrenciler ve yazılımcılar için akıllı C dili geliştirme ortamı.',
              'C-Studio Modern C IDE v1.2 (Portable Windows Edition)\nSmart C language development environment for students and developers.',
              'C-Studio Moderne C-IDE v1.2 (Portable Windows Edition)\nSmarte C-Entwicklungsumgebung für Studenten und Entwickler.',
            ),
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  // TAB 2: YAPAY ZEKA AYARLARI
  Widget _buildAiTab() {
    final isLocalSupported = _aiService.isLocalAiAvailable;
    final localModels = _aiService.localAiService.findAvailableModels();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: _langService.trEnDe('Yapay Zeka Asistanı Dili', 'AI Assistant Language', 'KI-Assistentensprache'),
            subtitle: _langService.trEnDe(
              'Yapay zekanın kod hatalarını açıklayacağı ve sohbet edeceği dil (Arayüz dilinden bağımsızdır)',
              'The language used by the AI tutor to explain errors and chat (Independent of UI language)',
              'Die Sprache, in der die KI Fehler erklärt und antwortet (Unabhängig von der UI-Sprache)',
            ),
            icon: Icons.translate_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLanguageOptionCard(
                label: AppLanguageService.turkishLabel,
                isSelected: _selectedAiLanguage == 'tr',
                onTap: () => setState(() => _selectedAiLanguage = 'tr'),
              ),
              const SizedBox(width: 8),
              _buildLanguageOptionCard(
                label: AppLanguageService.englishLabel,
                isSelected: _selectedAiLanguage == 'en',
                onTap: () => setState(() => _selectedAiLanguage = 'en'),
              ),
              const SizedBox(width: 8),
              _buildLanguageOptionCard(
                label: AppLanguageService.germanLabel,
                isSelected: _selectedAiLanguage == 'de',
                onTap: () => setState(() => _selectedAiLanguage = 'de'),
              ),
              if (_langService.hasCustomLanguage || _selectedAiLanguage == 'custom') ...[
                const SizedBox(width: 8),
                _buildLanguageOptionCard(
                  label: '🌐 ${_langService.customLanguageName ?? "Custom"}',
                  isSelected: _selectedAiLanguage == 'custom',
                  onTap: () => setState(() => _selectedAiLanguage = 'custom'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Asistan Kuralları Banner'ı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7AA2F7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF7AA2F7).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF7AA2F7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _langService.trEnDe(
                      'Asistan koddaki hataları (Nerede, Neden, Nasıl) açıklar, C sorularını yanıtlar ve koda istediğiniz eklemeleri yapar. Kodlama dışı konulara cevap vermez.',
                      'The assistant explains errors (Where, Why, How), answers C questions, and adds requested features. Non-coding topics are declined.',
                      'Der Assistent erklärt Fehler (Wo, Warum, Wie), beantwortet C-Fragen und fügt Code hinzu. Themenfremde Fragen werden abgelehnt.',
                    ),
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7AA2F7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader(
            title: _langService.trEnDe('Yapay Zeka Motoru', 'AI Engine', 'KI-Engine'),
            subtitle: _langService.trEnDe('Dahili çevrimdışı yerel model bilgileri', 'Built-in offline local model information', 'Informationen zum integrierten Offline-Modell'),
            icon: Icons.psychology_rounded,
          ),
          const SizedBox(height: 8),

          _buildEngineCard(
            title: _langService.trEnDe('Dahili Çevrimdışı (Qwen 2.5 Coder 1.5B)', 'Built-in Offline (Qwen 2.5 Coder 1.5B)', 'Integriert Offline (Qwen 2.5 Coder 1.5B)'),
            badge: _langService.trEnDe('TAMAMEN ÇEVRİMDIŞI', 'FULLY OFFLINE', 'VOLLSTÄNDIG OFFLINE'),
            badgeColor: const Color(0xFF9ECE6A),
            icon: Icons.offline_bolt_rounded,
            isSelected: true,
            onTap: () {},
            children: [
              Text(
                _langService.trEnDe(
                  'İnternet, harici API anahtarı veya hesap gerekmez. Tüm işlemler doğrudan bilgisayarınızda yerel olarak çalıştırılır.',
                  'No internet, external API key, or account required. All inferences run 100% locally on your machine.',
                  'Kein Internet, externer API-Schlüssel oder Konto erforderlich. Alle Berechnungen laufen lokal auf Ihrem Computer.',
                ),
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFA9B1D6), height: 1.3),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF13141C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLocalSupported
                      ? '✓ Model: ${localModels.isNotEmpty ? localModels.first.path.split(RegExp(r"[\\/]")).last : "qwen2.5-coder-1.5b-instruct-q3_k_m.gguf"}'
                      : _langService.trEnDe(
                          '✗ Model dosyası ai/models/ klasöründe bulunamadı.',
                          '✗ Model file not found in ai/models/ directory.',
                          '✗ Modelldatei im Ordner ai/models/ nicht gefunden.',
                        ),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: isLocalSupported ? const Color(0xFF9ECE6A) : const Color(0xFFF7768E),
                  ),
                ),
              ),
              if (!isLocalSupported) ...[
                const SizedBox(height: 10),
                AiModelDownloadCard(
                  compact: true,
                  onDownloadCompleted: () {
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // TAB 3: DERLEYİCİ AYARLARI
  Widget _buildCompilerTab() {
    final active = _compilerService.activeCompiler;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: _langService.trEnDe('Algılanan C Derleyicisi', 'Detected C Compiler', 'Erkannter C-Compiler'),
            subtitle: _langService.trEnDe(
              'C programlarını derleyen ve çalıştıran motor',
              'The toolchain that compiles and executes C source files',
              'Die Toolchain, die C-Quelldateien kompiliert und ausführt',
            ),
            icon: Icons.memory_rounded,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF13141C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF24283B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF9ECE6A), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      active?.name ?? 'Tiny C Compiler 64-bit',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9ECE6A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _langService.trEnDe('Dahili & Portatif', 'Built-in & Portable', 'Integriert & Portabel'),
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF9ECE6A), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Exe: ${active?.exePath ?? "compiler/tcc.exe"}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF7982A9)),
                ),
                const SizedBox(height: 8),
                Text(
                  _langService.trEnDe(
                    '✓ cstudio_runtime.h tamponlama yaması aktif: printf/scanf doğrudan terminale anında akar.',
                    '✓ cstudio_runtime.h buffering patch active: printf/scanf flush immediately.',
                    '✓ cstudio_runtime.h Puffer-Patch aktiv: printf/scanf werden sofort im Terminal ausgegeben.',
                  ),
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF73DACA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7AA2F7)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF7982A9))),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageOptionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1F2335) : const Color(0xFF13141C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFF24283B),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFFC0CAF5),
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 15,
                color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFF565F89),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngineCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2335) : const Color(0xFF14151F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFF24283B),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFF7982A9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFFC0CAF5),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 16,
                  color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFF565F89),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}
