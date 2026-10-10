import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../models/compiler_error.dart';
import '../services/app_language_service.dart';

class ErrorSolutionPanel extends StatelessWidget {
  final List<CompilerError> errors;
  final CompilerError? selectedError;
  final ValueChanged<CompilerError> onErrorSelected;
  final ValueChanged<CompilerError> onApplyAutoFix;
  final ValueChanged<CompilerError>? onAskAi;

  const ErrorSolutionPanel({
    super.key,
    required this.errors,
    required this.selectedError,
    required this.onErrorSelected,
    required this.onApplyAutoFix,
    this.onAskAi,
  });

  @override
  Widget build(BuildContext context) {
    final isTr = AppLanguageService().isUiTurkish;

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
              isTr ? 'Tebrikler! Kodunuzda hata bulunmuyor.' : 'Great! No errors or warnings found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9ECE6A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isTr
                  ? 'F5 tuşuna basarak programınızı çalıştırabilirsiniz.'
                  : 'Press F5 to compile and run your code.',
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst: Hata Seçim Listesi (Çoklu hata durumunda kaydırılabilir çipler)
          if (errors.length > 1) ...[
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: const Color(0xFF16161E),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: errors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final err = errors[index];
                  final isSelected = curErr == err;
                  return InkWell(
                    onTap: () => onErrorSelected(err),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7AA2F7).withValues(alpha: 0.2)
                            : const Color(0xFF1F2335),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFF292E42),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            err.isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded,
                            size: 13,
                            color: err.isWarning ? const Color(0xFFE0AF68) : const Color(0xFFF7768E),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${p.basename(err.fileName)}:${err.line}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFFC0CAF5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Color(0xFF24283B), height: 1),
          ],

          // Alt: Seçili Hata ve Çözüm Detayları
          Expanded(
            child: _buildSolutionCard(curErr),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionCard(CompilerError err) {
    final diag = err.diagnosis;
    final isTr = AppLanguageService().isUiTurkish;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık satırı
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (err.isWarning ? const Color(0xFFE0AF68) : const Color(0xFFF7768E)).withValues(alpha: 0.15),
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
                          ? diag.getDisplayTitle(isTr)
                          : (err.isWarning
                              ? (isTr ? 'Derleme Uyarısı' : 'Compiler Warning')
                              : (isTr ? 'Derleme Hatası' : 'Compiler Error')),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${err.fileName} • ${isTr ? "Satır" : "Line"} ${err.line}, ${isTr ? "Sütun" : "Col"} ${err.column}',
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
                    isTr ? 'Yapay Zekaya Sor (Açıkla & Çöz)' : 'Ask AI (Explain & Fix)',
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
                    diag!.getDisplayAutoFixDesc(isTr),
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
            isTr ? '📋 DERLEYİCİ MESAJI:' : '📋 COMPILER MESSAGE:',
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
              isTr ? '❓ NEDEN OLDU?' : '❓ WHY DID IT HAPPEN?',
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
                diag.getDisplayExplanation(isTr),
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFC0CAF5), height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Nasıl Düzeltilir
          if (diag != null && diag.howToFix.isNotEmpty) ...[
            Text(
              isTr ? '🛠️ NASIL DÜZELTİLİR?' : '🛠️ HOW TO FIX IT?',
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
                diag.getDisplayHowToFix(isTr),
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFC0CAF5), height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Örnek Kod
          if (diag != null && diag.goodExample.isNotEmpty) ...[
            Text(
              isTr ? '📝 DOĞRU KOD ÖRNEĞİ:' : '📝 CORRECT CODE EXAMPLE:',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE0AF68),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1017),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF24283B)),
              ),
              child: Text(
                diag.goodExample,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: const Color(0xFF9ECE6A),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
