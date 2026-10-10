import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_language_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/compiler_service.dart';

class SettingsDialog extends StatefulWidget {
  final int initialTab;
  const SettingsDialog({super.key, this.initialTab = 0});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppLanguageService _langService = AppLanguageService();
  final AiAssistantService _aiService = AiAssistantService();
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
    // 1. Dilleri kaydet
    _langService.setUiLanguage(_selectedUiLanguage);
    _langService.setAiLanguage(_selectedAiLanguage);

    // 2. AI ayarlarını kaydet
    _aiService.saveConfig(
      provider: 'local',
      language: _selectedAiLanguage,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = _selectedUiLanguage == 'tr';

    return Dialog(
      backgroundColor: const Color(0xFF16161E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24283B)),
      ),
      child: Container(
        width: 640,
        height: 560,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Üst Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7AA2F7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF7AA2F7).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.settings_rounded, color: Color(0xFF7AA2F7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr ? 'C-Studio Ayarları' : 'C-Studio Settings',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        isTr
                            ? 'Uygulama arayüz dili, yapay zeka motoru ve derleyici tercihleri'
                            : 'Application UI language, AI engine, and compiler preferences',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF7982A9)),
                      ),
                    ],
                  ),
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
                  Tab(icon: const Icon(Icons.tune_rounded, size: 16), text: isTr ? 'Genel' : 'General'),
                  Tab(icon: const Icon(Icons.psychology_rounded, size: 16), text: isTr ? 'Yapay Zeka' : 'AI Assistant'),
                  Tab(icon: const Icon(Icons.memory_rounded, size: 16), text: isTr ? 'Derleyici' : 'Compiler'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Sekme İçerikleri
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(isTr),
                  _buildAiTab(isTr),
                  _buildCompilerTab(isTr),
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
                  child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Color(0xFF7982A9))),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(isTr ? 'Kaydet ve Uygula' : 'Save and Apply'),
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
  Widget _buildGeneralTab(bool isTr) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: isTr ? 'Uygulama Arayüz Dili' : 'Application UI Language',
            subtitle: isTr
                ? 'Menülerin, butonların ve durum çubuğunun görüntüleneceği dil'
                : 'The language displayed on menus, buttons, and status bar',
            icon: Icons.language_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLanguageOptionCard(
                label: AppLanguageService.turkishLabel, // 🇹🇷 Türkçe (Bayrak VAR)
                isSelected: _selectedUiLanguage == 'tr',
                onTap: () {
                  setState(() {
                    _selectedUiLanguage = 'tr';
                    _selectedAiLanguage = 'tr';
                  });
                },
              ),
              const SizedBox(width: 12),
              _buildLanguageOptionCard(
                label: AppLanguageService.englishLabel, // English (Kesinlikle bayrak YOK)
                isSelected: _selectedUiLanguage == 'en',
                onTap: () {
                  setState(() {
                    _selectedUiLanguage = 'en';
                    _selectedAiLanguage = 'en';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(
            title: isTr ? 'Otomatik Kaydetme' : 'Auto-Save',
            subtitle: isTr
                ? 'Yazarken kod dosyalarını otomatik olarak arka planda kaydeder'
                : 'Automatically saves code files in background as you type',
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
                    isTr ? 'Her tuş vuruşundan sonra otomatik kaydet' : 'Auto-save after each modification',
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
            title: isTr ? 'Hakkında' : 'About',
            subtitle: isTr
                ? 'C-Studio Modern C IDE v1.2 (Portable Windows Edition)\nÖğrenciler ve yazılımcılar için akıllı C dili geliştirme ortamı.'
                : 'C-Studio Modern C IDE v1.2 (Portable Windows Edition)\nSmart C language development environment for students and developers.',
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  // TAB 2: YAPAY ZEKA AYARLARI
  Widget _buildAiTab(bool isTr) {
    final isLocalSupported = _aiService.isLocalAiAvailable;
    final localModels = _aiService.localAiService.findAvailableModels();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Yapay Zeka Dili (Uygulama dilinden bağımsız!)
          _buildSectionHeader(
            title: isTr ? 'Yapay Zeka Asistanı Dili' : 'AI Assistant Language',
            subtitle: isTr
                ? 'Yapay zekanın kod hatalarını açıklayacağı ve sohbet edeceği dil (Arayüz dilinden bağımsızdır)'
                : 'The language used by the AI tutor to explain errors and chat (Independent of UI language)',
            icon: Icons.translate_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLanguageOptionCard(
                label: AppLanguageService.turkishLabel, // 🇹🇷 Türkçe (Bayrak VAR)
                isSelected: _selectedAiLanguage == 'tr',
                onTap: () => setState(() => _selectedAiLanguage = 'tr'),
              ),
              const SizedBox(width: 12),
              _buildLanguageOptionCard(
                label: AppLanguageService.englishLabel, // English (Kesinlikle bayrak YOK)
                isSelected: _selectedAiLanguage == 'en',
                onTap: () => setState(() => _selectedAiLanguage = 'en'),
              ),
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
                    isTr
                        ? 'Asistan koddaki hataları (Nerede, Neden, Nasıl) açıklar, C sorularını yanıtlar ve koda istediğiniz eklemeleri yapar. Kodlama dışı konulara cevap vermez.'
                        : 'The assistant explains errors (Where, Why, How), answers C questions, and adds requested features. Non-coding topics are declined.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7AA2F7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Dahili Yapay Zeka Motoru Bilgisi
          _buildSectionHeader(
            title: isTr ? 'Yapay Zeka Motoru' : 'AI Engine',
            subtitle: isTr ? 'Dahili çevrimdışı yerel model bilgileri' : 'Built-in offline local model information',
            icon: Icons.psychology_rounded,
          ),
          const SizedBox(height: 8),

          // Dahili Yerel Model Kartı
          _buildEngineCard(
            title: isTr ? 'Dahili Çevrimdışı (Qwen 2.5 Coder 1.5B)' : 'Built-in Offline (Qwen 2.5 Coder 1.5B)',
            badge: isTr ? 'TAMAMEN ÇEVRİMDIŞI' : 'FULLY OFFLINE',
            badgeColor: const Color(0xFF9ECE6A),
            icon: Icons.offline_bolt_rounded,
            isSelected: true,
            onTap: () {},
            children: [
              Text(
                isTr
                    ? 'İnternet, harici API anahtarı veya hesap gerekmez. Tüm işlemler doğrudan bilgisayarınızda yerel olarak çalıştırılır.'
                    : 'No internet, external API key, or account required. All inferences run 100% locally on your machine.',
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
                      : (isTr ? '✗ Model dosyası ai/models/ klasöründe bulunamadı.' : '✗ Model file not found in ai/models/ directory.'),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: isLocalSupported ? const Color(0xFF9ECE6A) : const Color(0xFFF7768E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 3: DERLEYİCİ AYARLARI
  Widget _buildCompilerTab(bool isTr) {
    final active = _compilerService.activeCompiler;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: isTr ? 'Algılanan C Derleyicisi' : 'Detected C Compiler',
            subtitle: isTr
                ? 'C programlarını derleyen ve çalıştıran motor'
                : 'The toolchain that compiles and executes C source files',
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
                        isTr ? 'Dahili & Portatif' : 'Built-in & Portable',
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
                  isTr
                      ? '✓ cstudio_runtime.h tamponlama yaması aktif: printf/scanf doğrudan terminale anında akar.'
                      : '✓ cstudio_runtime.h buffering patch active: printf/scanf flush immediately.',
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFFC0CAF5),
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 16,
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
