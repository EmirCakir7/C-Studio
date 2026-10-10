import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_language_service.dart';

class SpecialKeyItem {
  final String label;
  final String insertText;
  final int cursorOffset; // Imlecin eklenen metin sonundan geriye kaç karakter kayacağı
  final String? tooltip;
  final String? tooltipEn;
  final Color? color;
  final bool isAccent;

  const SpecialKeyItem({
    required this.label,
    required this.insertText,
    this.cursorOffset = 0,
    this.tooltip,
    this.tooltipEn,
    this.color,
    this.isAccent = false,
  });

  String getDisplayTooltip(bool isTr) {
    if (isTr) return tooltip ?? label;
    return tooltipEn ?? tooltip ?? label;
  }
}

class SpecialKeysBar extends StatelessWidget {
  final void Function(String text, {int cursorOffset}) onInsert;
  final VoidCallback onClose;

  const SpecialKeysBar({
    super.key,
    required this.onInsert,
    required this.onClose,
  });

  static const List<SpecialKeyItem> _keys = [
    // 1. Süslü Parantezler & Köşeli Parantezler
    SpecialKeyItem(label: '{ }', insertText: '{\n    \n}', cursorOffset: -2, tooltip: 'Süslü Parantez Bloğu (AltGr + 7/0)', tooltipEn: 'Curly Braces Block { }', isAccent: true),
    SpecialKeyItem(label: '{', insertText: '{', tooltip: 'Açık Süslü Parantez (AltGr + 7)', tooltipEn: 'Opening Curly Brace {'),
    SpecialKeyItem(label: '}', insertText: '}', tooltip: 'Kapalı Süslü Parantez (AltGr + 0)', tooltipEn: 'Closing Curly Brace }'),
    SpecialKeyItem(label: '[ ]', insertText: '[]', cursorOffset: -1, tooltip: 'Köşeli Parantez Çifti (AltGr + 8/9)', tooltipEn: 'Square Brackets Pair []', isAccent: true),
    SpecialKeyItem(label: '[', insertText: '[', tooltip: 'Açık Köşeli Parantez (AltGr + 8)', tooltipEn: 'Opening Square Bracket ['),
    SpecialKeyItem(label: ']', insertText: ']', tooltip: 'Kapalı Köşeli Parantez (AltGr + 9)', tooltipEn: 'Closing Square Bracket ]'),
    
    // 2. Ters Eğik Çizgi & Boru & Tilde
    SpecialKeyItem(label: '\\', insertText: '\\', tooltip: 'Ters Eğik Çizgi (AltGr + ? / Backslash)', tooltipEn: 'Backslash \\', isAccent: true),
    SpecialKeyItem(label: '|', insertText: '|', tooltip: 'Boru / Pipe (AltGr + -)', tooltipEn: 'Pipe |', isAccent: true),
    SpecialKeyItem(label: '~', insertText: '~', tooltip: 'Tilde (AltGr + Ü)', tooltipEn: 'Tilde ~', isAccent: true),
    SpecialKeyItem(label: '^', insertText: '^', tooltip: 'Şapka / Caret (Shift + 3)', tooltipEn: 'Caret ^'),
    SpecialKeyItem(label: '#', insertText: '#', tooltip: 'Preprocessor Diyez (AltGr + 3)', tooltipEn: 'Preprocessor Hash #', isAccent: true),

    // 3. Noktalı virgül, Tırnaklar & Ok Operatörü
    SpecialKeyItem(label: ';', insertText: ';', tooltip: 'Noktalı Virgül (Shift + ,)', tooltipEn: 'Semicolon ;', isAccent: true),
    SpecialKeyItem(label: '" "', insertText: '""', cursorOffset: -1, tooltip: 'Çift Tırnak Metin', tooltipEn: 'Double Quotes ""'),
    SpecialKeyItem(label: '\' \'', insertText: '\'\'', cursorOffset: -1, tooltip: 'Tek Tırnak Karakter', tooltipEn: 'Single Quotes \'\''),
    SpecialKeyItem(label: '->', insertText: '->', tooltip: 'Yapı İşaretçi Oku (Struct pointer arrow)', tooltipEn: 'Struct Pointer Arrow ->', isAccent: true),

    // 4. C Operatörleri ve Sembolleri
    SpecialKeyItem(label: '&', insertText: '&', tooltip: 'Adres / Ve Operatörü (Shift + 6)', tooltipEn: 'Address-of / Bitwise AND &'),
    SpecialKeyItem(label: '*', insertText: '*', tooltip: 'Pointer / Çarpma', tooltipEn: 'Pointer Dereference / Multiply *'),
    SpecialKeyItem(label: '%', insertText: '%', tooltip: 'Format Belirteci / Modulo (Shift + 5)', tooltipEn: 'Format Specifier / Modulo %'),
    SpecialKeyItem(label: '!', insertText: '!', tooltip: 'Değil / Not (Shift + 1)', tooltipEn: 'Logical NOT !'),
    SpecialKeyItem(label: '&&', insertText: ' && ', tooltip: 'Mantıksal VE', tooltipEn: 'Logical AND &&'),
    SpecialKeyItem(label: '||', insertText: ' || ', tooltip: 'Mantıksal VEYA', tooltipEn: 'Logical OR ||'),
    SpecialKeyItem(label: '==', insertText: ' == ', tooltip: 'Eşitlik Kontrolü', tooltipEn: 'Equality Check =='),
    SpecialKeyItem(label: '!=', insertText: ' != ', tooltip: 'Eşit Değildir', tooltipEn: 'Not Equal !='),
    SpecialKeyItem(label: '<=', insertText: ' <= ', tooltip: 'Küçük Eşit', tooltipEn: 'Less Than or Equal <='),
    SpecialKeyItem(label: '>=', insertText: ' >= ', tooltip: 'Büyük Eşit', tooltipEn: 'Greater Than or Equal >='),
    
    // 5. Yorum ve Satır Sonu
    SpecialKeyItem(label: '/* */', insertText: '/*  */', cursorOffset: -3, tooltip: 'Çok Satırlı Yorum', tooltipEn: 'Multi-line Comment /* */'),
    SpecialKeyItem(label: '//', insertText: '// ', tooltip: 'Tek Satır Yorum', tooltipEn: 'Single-line Comment //'),
    SpecialKeyItem(label: '\\n', insertText: '\\n', tooltip: 'Alt Satır Karakteri', tooltipEn: 'Newline Character \\n'),
  ];

  @override
  Widget build(BuildContext context) {
    final isTr = AppLanguageService().isUiTurkish;

    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFF13141C),
        border: Border(
          bottom: BorderSide(color: Color(0xFF24283B), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Sol İkon ve Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.keyboard_outlined, size: 15, color: Color(0xFF7AA2F7)),
                const SizedBox(width: 5),
                Text(
                  isTr ? 'Hızlı Tuşlar:' : 'Quick Keys:',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7982A9),
                  ),
                ),
              ],
            ),
          ),

          // Tuşlar Listesi (Yatay Kaydırılabilir)
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              itemCount: _keys.length,
              separatorBuilder: (context, index) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final k = _keys[index];
                return Tooltip(
                  message: k.getDisplayTooltip(isTr),
                  waitDuration: const Duration(milliseconds: 300),
                  child: InkWell(
                    onTap: () => onInsert(k.insertText, cursorOffset: k.cursorOffset),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: k.isAccent ? const Color(0xFF1F2335) : const Color(0xFF1A1B26),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: k.isAccent
                              ? const Color(0xFF7AA2F7).withValues(alpha: 0.4)
                              : const Color(0xFF24283B),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        k.label,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: k.isAccent ? const Color(0xFF7DCFFF) : const Color(0xFFC0CAF5),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Kapatma Butonu (X)
          Tooltip(
            message: isTr ? 'Hızlı Tuşları Gizle' : 'Hide Quick Keys',
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF7982A9)),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
