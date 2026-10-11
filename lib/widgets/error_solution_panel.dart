import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/compiler_error.dart';
import '../services/app_language_service.dart';

class ErrorSolutionPanel extends StatelessWidget {
  final List<CompilerError> errors;
  final CompilerError? selectedError;
  final Function(CompilerError) onSelectError;
  final Function(CompilerError) onApplyAutoFix;
  final Function(CompilerError)? onAskAi;

  const ErrorSolutionPanel({
    super.key,
    required this.errors,
    this.selectedError,
    required this.onSelectError,
    required this.onApplyAutoFix,
    this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguageService().uiLanguage;
    final langService = AppLanguageService();

    if (errors.isEmpty) {
      return Container(
        color: const Color(0xFF13141C),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF9ECE6A), size: 40),
            const SizedBox(height: 12),
            Text(
              langService.trEnDe(
                'Tebrikler! Kodunuzda hata bulunmuyor.',
                'Great! No errors or warnings found.',
                'Großartig! Keine Fehler oder Warnungen gefunden.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9ECE6A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              langService.trEnDe(
                'F5 tuşuna basarak programınızı çalıştırabilirsiniz.',
                'Press F5 to compile and run your code.',
                'Drücken Sie F5, um Ihren Code zu kompilieren und auszuführen.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF565F89)),
            ),
          ],
        ),
      );
    }

    final curErr = selectedError ?? errors.first;

    return Container(
      color: const Color(0xFF13141C),
      child: Column(
        children: [
          // 1. Üst Hata Listesi Çubuğu (Chips)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF16161E),
              border: Border(bottom: BorderSide(color: Color(0xFF24283B))),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: errors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final err = errors[index];
                final isSelected = err == curErr;
                final isWarning = err.isWarning;

                return InkWell(
                  onTap: () => onSelectError(err),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isWarning ? const Color(0xFFE0AF68).withValues(alpha: 0.2) : const Color(0xFFF7768E).withValues(alpha: 0.2))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? (isWarning ? const Color(0xFFE0AF68) : const Color(0xFFF7768E))
                            : const Color(0xFF24283B),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isWarning ? Icons.warning_amber_rounded : Icons.cancel_rounded,
                          size: 13,
                          color: isWarning ? const Color(0xFFE0AF68) : const Color(0xFFF7768E),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${err.fileName}:${err.line}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: isSelected ? Colors.white : const Color(0xFF7982A9),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Seçili Hatanın Detaylı Çözüm Kartı
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: _buildErrorCard(context, curErr, langService, lang),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, CompilerError err, AppLanguageService langService, String lang) {
    final diag = err.diagnosis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık ve Rozet
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: err.isWarning ? const Color(0xFFE0AF68).withValues(alpha: 0.15) : const Color(0xFFF7768E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                err.isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
                color: err.isWarning ? const Color(0xFFE0AF68) : const Color(0xFFF7768E),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diag != null
                        ? diag.getDisplayTitle(lang)
                        : (err.isWarning
                            ? langService.trEnDe('Derleme Uyarısı', 'Compiler Warning', 'Compiler-Warnung')
                            : langService.trEnDe('Derleme Hatası', 'Compiler Error', 'Compiler-Fehler')),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${err.fileName} • ${langService.trEnDe("Satır", "Line", "Zeile")} ${err.line}, ${langService.trEnDe("Sütun", "Col", "Spalte")} ${err.column}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: const Color(0xFF7AA2F7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Butonlar
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onAskAi != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFBB9AF7)),
                label: Text(
                  langService.trEnDe(
                    'Yapay Zekaya Sor (Açıkla & Çöz)',
                    'Ask AI (Explain & Fix)',
                    'KI fragen (Erklären & Beheben)',
                  ),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFBB9AF7), fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E2248),
                  side: const BorderSide(color: Color(0xFFBB9AF7), width: 1.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => onAskAi!(err),
              ),
            if (diag?.canAutoFix == true)
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on_rounded, size: 14),
                label: Text(
                  diag!.getDisplayAutoFixDesc(lang),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7AA2F7),
                  foregroundColor: const Color(0xFF1A1B26),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => onApplyAutoFix(err),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // Ham Hata Mesajı
        Text(
          langService.trEnDe('📋 DERLEYİCİ MESAJI:', '📋 COMPILER MESSAGE:', '📋 COMPILER-MELDUNG:'),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7982A9),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1017),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF24283B)),
          ),
          child: Text(
            err.message,
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFFF7768E), height: 1.3),
          ),
        ),

        const SizedBox(height: 12),

        // Neden Oldu
        if (diag != null && diag.explanation.isNotEmpty) ...[
          Text(
            langService.trEnDe('❓ NEDEN OLDU?', '❓ WHY DID IT HAPPEN?', '❓ WARUM IST DAS PASSIERT?'),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7DCFFF),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16161E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF24283B)),
            ),
            child: Text(
              diag.getDisplayExplanation(lang),
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFC0CAF5), height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Nasıl Düzeltilir
        if (diag != null && diag.howToFix.isNotEmpty) ...[
          Text(
            langService.trEnDe('🛠️ NASIL DÜZELTİLİR?', '🛠️ HOW TO FIX IT?', '🛠️ WIE WIRD ES BEHOBEN?'),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9ECE6A),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16161E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF24283B)),
            ),
            child: Text(
              diag.getDisplayHowToFix(lang),
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFC0CAF5), height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Örnek Kod Karşılaştırması
        if (diag != null && (diag.badExample.isNotEmpty || diag.goodExample.isNotEmpty)) ...[
          Text(
            langService.trEnDe('💡 ÖRNEK KOD:', '💡 EXAMPLE CODE:', '💡 BEISPIEL-CODE:'),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0AF68),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          if (diag.badExample.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF231C28),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF7768E).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    langService.trEnDe('❌ Hatalı Kullanım:', '❌ Incorrect Usage:', '❌ Fehlerhafte Verwendung:'),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFF7768E)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    diag.badExample,
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFFF7768E)),
                  ),
                ],
              ),
            ),
          if (diag.goodExample.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF192428),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF9ECE6A).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    langService.trEnDe('✅ Doğru Kullanım:', '✅ Correct Usage:', '✅ Korrekte Verwendung:'),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF9ECE6A)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    diag.goodExample,
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF9ECE6A)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
