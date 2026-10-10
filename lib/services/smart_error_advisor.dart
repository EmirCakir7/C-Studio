import 'package:path/path.dart' as p;
import '../models/compiler_error.dart';

class SmartErrorAdvisor {
  static List<CompilerError> parseErrors(String output, String defaultFilePath) {
    final List<CompilerError> errors = [];
    if (output.trim().isEmpty) return errors;

    final lines = output.split(RegExp(r'\r?\n'));

    // Pattern 1: file.c:line:col: error/warning: message
    final reg1 = RegExp(r'^(.+?):(\d+):(\d+):\s*(error|warning|fatal error):\s*(.+)$', caseSensitive: false);
    // Pattern 2: file.c:line: error/warning: message
    final reg2 = RegExp(r'^(.+?):(\d+):\s*(error|warning):\s*(.+)$', caseSensitive: false);
    // Pattern 3: tcc/gcc: error: message
    final reg3 = RegExp(r'^(tcc|gcc|ld):\s*(error|warning):\s*(.+)$', caseSensitive: false);
    // Pattern 4: undefined symbol 'main'
    final reg4 = RegExp('undefined\\s+(symbol|reference to)\\s+[\'"]?([a-zA-Z0-9_]+)[\'"]?', caseSensitive: false);
    // Pattern 5: file.c: error/warning: message (satır numarası olmayanlar)
    final reg5 = RegExp(r'^(.+?):\s*(error|warning|fatal error):\s*(.+)$', caseSensitive: false);

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final m1 = reg1.firstMatch(line);
      if (m1 != null) {
        final filePath = m1.group(1)!.trim();
        final l = int.tryParse(m1.group(2)!) ?? 1;
        final c = int.tryParse(m1.group(3)!) ?? 1;
        final type = m1.group(4)!.toLowerCase();
        final msg = m1.group(5)!.trim();
        final err = CompilerError(
          filePath: filePath,
          fileName: p.basename(filePath),
          line: l,
          column: c,
          severity: type.contains('warning') ? ErrorSeverity.warning : ErrorSeverity.error,
          message: msg,
          rawLine: line,
        );
        errors.add(CompilerError(
          filePath: err.filePath,
          fileName: err.fileName,
          line: err.line,
          column: err.column,
          severity: err.severity,
          message: err.message,
          rawLine: err.rawLine,
          diagnosis: diagnose(err),
        ));
        continue;
      }

      final m2 = reg2.firstMatch(line);
      if (m2 != null) {
        final filePath = m2.group(1)!.trim();
        final l = int.tryParse(m2.group(2)!) ?? 1;
        final type = m2.group(3)!.toLowerCase();
        final msg = m2.group(4)!.trim();
        final err = CompilerError(
          filePath: filePath,
          fileName: p.basename(filePath),
          line: l,
          column: 1,
          severity: type.contains('warning') ? ErrorSeverity.warning : ErrorSeverity.error,
          message: msg,
          rawLine: line,
        );
        errors.add(CompilerError(
          filePath: err.filePath,
          fileName: err.fileName,
          line: err.line,
          column: err.column,
          severity: err.severity,
          message: err.message,
          rawLine: err.rawLine,
          diagnosis: diagnose(err),
        ));
        continue;
      }

      final m3 = reg3.firstMatch(line);
      if (m3 != null) {
        final msg = m3.group(3)!.trim();
        final err = CompilerError(
          filePath: defaultFilePath,
          fileName: p.basename(defaultFilePath),
          line: 1,
          column: 1,
          severity: ErrorSeverity.error,
          message: msg,
          rawLine: line,
        );
        errors.add(CompilerError(
          filePath: err.filePath,
          fileName: err.fileName,
          line: err.line,
          column: err.column,
          severity: err.severity,
          message: err.message,
          rawLine: err.rawLine,
          diagnosis: diagnose(err),
        ));
        continue;
      }

      final m4 = reg4.firstMatch(line);
      if (m4 != null) {
        final err = CompilerError(
          filePath: defaultFilePath,
          fileName: p.basename(defaultFilePath),
          line: 1,
          column: 1,
          severity: ErrorSeverity.error,
          message: line,
          rawLine: line,
        );
        errors.add(CompilerError(
          filePath: err.filePath,
          fileName: err.fileName,
          line: err.line,
          column: err.column,
          severity: err.severity,
          message: err.message,
          rawLine: err.rawLine,
          diagnosis: diagnose(err),
        ));
        continue;
      }

      final m5 = reg5.firstMatch(line);
      if (m5 != null) {
        final filePath = m5.group(1)!.trim();
        final type = m5.group(2)!.toLowerCase();
        final msg = m5.group(3)!.trim();
        final err = CompilerError(
          filePath: filePath.contains('\\') || filePath.contains('/') ? filePath : defaultFilePath,
          fileName: p.basename(filePath),
          line: 1,
          column: 1,
          severity: type.contains('warning') ? ErrorSeverity.warning : ErrorSeverity.error,
          message: msg,
          rawLine: line,
        );
        errors.add(CompilerError(
          filePath: err.filePath,
          fileName: err.fileName,
          line: err.line,
          column: err.column,
          severity: err.severity,
          message: err.message,
          rawLine: err.rawLine,
          diagnosis: diagnose(err),
        ));
        continue;
      }
    }

    // Hiçbir regex yakalayamazsa ama çıktı varsa, boş dönmek yerine genel hata ekle
    if (errors.isEmpty && output.trim().isNotEmpty) {
      final err = CompilerError(
        filePath: defaultFilePath,
        fileName: p.basename(defaultFilePath),
        line: 1,
        column: 1,
        severity: ErrorSeverity.error,
        message: output.trim(),
        rawLine: output.trim(),
      );
      errors.add(CompilerError(
        filePath: err.filePath,
        fileName: err.fileName,
        line: err.line,
        column: err.column,
        severity: err.severity,
        message: err.message,
        rawLine: err.rawLine,
        diagnosis: diagnose(err),
      ));
    }

    return errors;
  }

  static ErrorDiagnosis diagnose(CompilerError error) {
    final msg = error.message.toLowerCase();
    final raw = error.rawLine.toLowerCase();

    // 0. 'main' tanımlaması çakışması
    if (msg.contains("defined twice") || msg.contains("redefinition of 'main'")) {
      return ErrorDiagnosis(
        category: 'Fonksiyon / Başlangıç Çakışması',
        categoryEn: 'Function / Entry Point Conflict',
        title: "'main' Fonksiyonu Birden Fazla Kez Tanımlanmış",
        titleEn: "'main' Function Defined Multiple Times",
        explanation: "C dilinde bir programda yalnızca 1 adet 'main()' başlangıç fonksiyonu bulunabilir. "
            "Projenizdeki birden fazla kaynak dosyası (.c) 'main' fonksiyonu içeriyor.",
        explanationEn: "In C, a program can only have exactly 1 'main()' entry point. "
            "Multiple source files (.c) in your project contain a 'main' function.",
        howToFix: "1. Çalıştırmak istediğiniz aktif dosyada 'main()' fonksiyonunu tutun.\n"
            "2. Diğer .c dosyalarındaki 'main' fonksiyonunun adını değiştirin veya projeden kaldırın.",
        howToFixEn: "1. Keep 'main()' only in the active file you want to run.\n"
            "2. Rename or remove 'main' from other .c files.",
        canAutoFix: false,
      );
    }

    // 0.1 Kapatılmamış metin (string)
    if (msg.contains("missing terminating") || msg.contains("newline in constant") || msg.contains("unterminated")) {
      return ErrorDiagnosis(
        category: 'Sözdizimi (Syntax)',
        categoryEn: 'Syntax',
        title: 'Kapatılmamış Metin (String) İfadesi',
        titleEn: 'Unterminated String Literal',
        explanation: 'Çift tırnak (") ile başlatılan metin kapatılmadan satır sonlandırılmış veya alt satıra geçilmiş.',
        explanationEn: 'A string literal starting with double quotes (") was not closed before the end of the line.',
        howToFix: '1. Hata satırındaki metnin bittiği yere çift tırnak (") ekleyin.\n'
            '2. printf veya diğer metin ifadelerini tek satırda yazın.',
        howToFixEn: '1. Add a closing double quote (") where the string ends.\n'
            '2. Keep string literals on a single line.',
        canAutoFix: false,
      );
    }

    // 1. Noktalı virgül (;) eksik
    if (msg.contains("';' expected") ||
        msg.contains("; expected") ||
        msg.contains("expected ';'") ||
        msg.contains("missing ';'") ||
        msg.contains("expected ';' before")) {
      return ErrorDiagnosis(
        category: 'Sözdizimi (Syntax)',
        categoryEn: 'Syntax',
        title: 'Noktalı Virgül (;) Unutulmuş',
        titleEn: 'Missing Semicolon (;)',
        explanation: 'C programlama dilinde her komut/ifade noktalı virgül (;) ile bitmelidir. '
            'Derleyici ${error.line}. satırda veya hemen önceki satırda noktalı virgül bekliyor.',
        explanationEn: 'In C, every statement must end with a semicolon (;). '
            'The compiler expects a semicolon on or before line ${error.line}.',
        howToFix: '1. ${error.line}. satırı veya hemen bir önceki satırın sonunu kontrol edin.\n'
            '2. Komutun sonuna ";" karakterini ekleyin.',
        howToFixEn: '1. Check the end of line ${error.line} or the previous line.\n'
            '2. Add ";" at the end of the statement.',
        badExample: 'int sayi = 10\nprintf("%d", sayi);',
        goodExample: 'int sayi = 10; // Doğru noktalı virgül\nprintf("%d", sayi);',
        canAutoFix: true,
        fixType: AutoFixType.addSemicolon,
        autoFixDescription: '${error.line}. satır veya önceki satırın sonuna ";" ekle',
        autoFixDescriptionEn: 'Add ";" to the end of line ${error.line} or previous line',
      );
    }

    // 2. Parantez eksik
    if (msg.contains("')' expected") || msg.contains("expected ')'")) {
      return ErrorDiagnosis(
        category: 'Sözdizimi (Syntax)',
        categoryEn: 'Syntax',
        title: "Kapanış Parantezi ')' Eksik",
        titleEn: "Missing Closing Parenthesis ')'",
        explanation: "Açılan bir parantez '(' kapatılmamış veya fonksiyon çağrısında parantez eksik kalmış.",
        explanationEn: "An opened parenthesis '(' was not closed or is missing in a function call/condition.",
        howToFix: "${error.line}. satırdaki parantezleri kontrol edin ve eksik olan ')' karakterini ekleyin.",
        howToFixEn: "Check parentheses on line ${error.line} and add the missing ')'.",
        badExample: "if (sayi > 5 {\n    ...\n}",
        goodExample: "if (sayi > 5) {\n    ...\n}",
        canAutoFix: false,
      );
    }

    if (msg.contains("'}' expected") || msg.contains("expected '}'")) {
      return ErrorDiagnosis(
        category: 'Sözdizimi (Syntax)',
        categoryEn: 'Syntax',
        title: "Süslü Parantez '}' Eksik",
        titleEn: "Missing Closing Brace '}'",
        explanation: "Fonksiyonun veya blok yapısının (if, for, while) gövdesini kapatan '}' süslü parantezi unutulmuş.",
        explanationEn: "The closing brace '}' for a function body or control block (if, for, while) is missing.",
        howToFix: "Açılan her '{' bloğunun karşılığında bir '}' bulunduğundan emin olun.",
        howToFixEn: "Ensure every opened '{' block has a matching closing '}'.",
        badExample: "int main() {\n    printf(\"test\");\n// '}' unutuldu",
        goodExample: "int main() {\n    printf(\"test\");\n    return 0;\n}",
        canAutoFix: false,
      );
    }

    // 3. Türkçe karakter veya tanınmayan sembol
    if (msg.contains("unrecognized character") || msg.contains("stray") || msg.contains("invalid character")) {
      return ErrorDiagnosis(
        category: 'Karakter Kodlama',
        categoryEn: 'Character Encoding',
        title: 'Geçersiz Karakter (Türkçe Harf Uyarısı)',
        titleEn: 'Invalid Character / Non-ASCII Symbol',
        explanation: 'C dili değişken ve fonksiyon isimlerinde Türkçe karakterleri (ş, ğ, ı, ö, ü, ç, İ) tanımaz. '
            'Ayrıca kopyalanan kodlarda yanlış tırnak veya ters bölü işareti bulunuyor olabilir.',
        explanationEn: 'C does not support non-ASCII characters in identifiers. '
            'Also check for invalid quotation marks or symbols.',
        howToFix: '1. Değişken isimlerinde Türkçe karakter yerine İngilizce karakter kullanın (örn: "yaş" yerine "yas", "sayı" yerine "sayi").\n'
            '2. Standart çift tırnak (") karakteri kullanın.',
        howToFixEn: '1. Use standard ASCII characters for variable and function names (e.g., "age" instead of non-ASCII).\n'
            '2. Use standard double quotes (").',
        badExample: 'int sayı = 5; // C\'de geçersiz harf',
        goodExample: 'int sayi = 5; // Doğru kullanım',
        canAutoFix: false,
      );
    }

    // 4. stdio.h eksik
    if (msg.contains("printf") ||
        msg.contains("scanf") ||
        msg.contains("puts") ||
        msg.contains("gets") ||
        msg.contains("getchar") ||
        msg.contains("putchar") ||
        msg.contains("fopen") ||
        msg.contains("fclose")) {
      if (msg.contains("implicit declaration") ||
          msg.contains("undefined symbol") ||
          msg.contains("undefined reference") ||
          msg.contains("undeclared")) {
        return ErrorDiagnosis(
          category: 'Kütüphane Eksikliği',
          categoryEn: 'Missing Header',
          title: 'Girdi/Çıktı Kütüphanesi (#include <stdio.h>) Eksik',
          titleEn: 'Standard I/O Library (#include <stdio.h>) Missing',
          explanation: "Kullandığınız 'printf', 'scanf' gibi fonksiyonlar C'nin standart girdi/çıktı kütüphanesindedir. "
              "Derleyicinin bu fonksiyonları tanıması için başlık dosyasının dahil edilmesi gerekir.",
          explanationEn: "'printf', 'scanf', and related I/O functions require the <stdio.h> header to be included.",
          howToFix: "Dosyanın en üstüne `#include <stdio.h>` satırını ekleyin.",
          howToFixEn: "Add `#include <stdio.h>` at the very top of your file.",
          badExample: "int main() {\n    printf(\"Merhaba!\"); // Hata: printf bilinmiyor\n}",
          goodExample: "#include <stdio.h>\n\nint main() {\n    printf(\"Merhaba!\");\n    return 0;\n}",
          canAutoFix: true,
          fixType: AutoFixType.addIncludeStdio,
          autoFixDescription: "Dosyanın başına '#include <stdio.h>' ekle",
          autoFixDescriptionEn: "Add '#include <stdio.h>' to top of file",
        );
      }
    }

    // 5. stdlib.h eksik
    if (msg.contains("malloc") ||
        msg.contains("free") ||
        msg.contains("calloc") ||
        msg.contains("realloc") ||
        msg.contains("system") ||
        msg.contains("exit") ||
        msg.contains("rand") ||
        msg.contains("atoi")) {
      return ErrorDiagnosis(
        category: 'Kütüphane Eksikliği',
        categoryEn: 'Missing Header',
        title: 'Standart Yardımcı Kütüphane (#include <stdlib.h>) Eksik',
        titleEn: 'Standard Utility Library (#include <stdlib.h>) Missing',
        explanation: "Kullandığınız 'malloc', 'free', 'system', 'rand' veya 'atoi' fonksiyonları <stdlib.h> kütüphanesine aittir.",
        explanationEn: "'malloc', 'free', 'system', 'rand', or 'exit' functions belong to <stdlib.h>.",
        howToFix: "Dosyanın en üstüne `#include <stdlib.h>` satırını ekleyin.",
        howToFixEn: "Add `#include <stdlib.h>` at the very top of your file.",
        badExample: "int *dizi = (int*)malloc(10 * sizeof(int)); // Hata!",
        goodExample: "#include <stdlib.h>\n\nint *dizi = (int*)malloc(10 * sizeof(int));",
        canAutoFix: true,
        fixType: AutoFixType.addIncludeStdlib,
        autoFixDescription: "Dosyanın başına '#include <stdlib.h>' ekle",
        autoFixDescriptionEn: "Add '#include <stdlib.h>' to top of file",
      );
    }

    // 6. math.h eksik
    if (msg.contains("sqrt") ||
        msg.contains("pow") ||
        msg.contains("sin") ||
        msg.contains("cos") ||
        msg.contains("tan") ||
        msg.contains("fabs") ||
        msg.contains("ceil") ||
        msg.contains("floor")) {
      return ErrorDiagnosis(
        category: 'Kütüphane Eksikliği',
        categoryEn: 'Missing Header',
        title: 'Matematik Kütüphanesi (#include <math.h>) Eksik',
        titleEn: 'Math Library (#include <math.h>) Missing',
        explanation: "Karekök (sqrt), üs alma (pow) veya trigonometri fonksiyonları <math.h> kütüphanesindedir.",
        explanationEn: "sqrt, pow, sin, cos, and other mathematical functions require <math.h>.",
        howToFix: "Dosyanın en üstüne `#include <math.h>` satırını ekleyin.",
        howToFixEn: "Add `#include <math.h>` at the very top of your file.",
        badExample: "double kok = sqrt(16.0); // Hata!",
        goodExample: "#include <math.h>\n\ndouble kok = sqrt(16.0); // 4.0",
        canAutoFix: true,
        fixType: AutoFixType.addIncludeMath,
        autoFixDescription: "Dosyanın başına '#include <math.h>' ekle",
        autoFixDescriptionEn: "Add '#include <math.h>' to top of file",
      );
    }

    // 7. string.h eksik
    if (msg.contains("strcpy") ||
        msg.contains("strlen") ||
        msg.contains("strcmp") ||
        msg.contains("strcat") ||
        msg.contains("strncpy") ||
        msg.contains("memset") ||
        msg.contains("memcpy")) {
      return ErrorDiagnosis(
        category: 'Kütüphane Eksikliği',
        categoryEn: 'Missing Header',
        title: 'Metin/String Kütüphanesi (#include <string.h>) Eksik',
        titleEn: 'String Library (#include <string.h>) Missing',
        explanation: "Karakter dizisi fonksiyonları (strlen, strcpy, strcmp vb.) için <string.h> gereklidir.",
        explanationEn: "String functions (strlen, strcpy, strcmp, etc.) require <string.h>.",
        howToFix: "Dosyanın en üstüne `#include <string.h>` satırını ekleyin.",
        howToFixEn: "Add `#include <string.h>` at the very top of your file.",
        badExample: "char str[20]; strcpy(str, \"test\"); // Hata!",
        goodExample: "#include <string.h>\n\nchar str[20]; strcpy(str, \"test\");",
        canAutoFix: true,
        fixType: AutoFixType.addIncludeString,
        autoFixDescription: "Dosyanın başına '#include <string.h>' ekle",
        autoFixDescriptionEn: "Add '#include <string.h>' to top of file",
      );
    }

    // 8. main fonksiyonu eksik
    if (raw.contains("main") && (raw.contains("undefined") || raw.contains("entry point") || raw.contains("winmain"))) {
      return ErrorDiagnosis(
        category: 'Giriş Noktası',
        categoryEn: 'Entry Point',
        title: "'main' Fonksiyonu Bulunamadı",
        titleEn: "'main' Function Not Found",
        explanation: "C programları çalışmaya daima 'main' fonksiyonundan başlar. Programınızda bu fonksiyon eksik veya adı hatalı yazılmış.",
        explanationEn: "C programs must start execution from a 'main' function. It is missing or misspelled.",
        howToFix: "Dosyanıza `int main(void) { ... return 0; }` fonksiyonunu ekleyin.",
        howToFixEn: "Add `int main(void) { ... return 0; }` to your file.",
        badExample: "// main fonksiyonu yok veya adı 'Main' (büyük harfle) yazılmış",
        goodExample: "#include <stdio.h>\n\nint main(void) {\n    printf(\"Program basariyla calisti!\\n\");\n    return 0;\n}",
        canAutoFix: true,
        fixType: AutoFixType.addMainFunction,
        autoFixDescription: "Standart 'main' fonksiyon şablonunu ekle",
        autoFixDescriptionEn: "Add standard 'main' function template",
      );
    }

    // 9. scanf adres operatörü eksik
    if ((msg.contains("format") && msg.contains("expects") && msg.contains("pointer")) ||
        (msg.contains("expects argument of type") && msg.contains("*"))) {
      return ErrorDiagnosis(
        category: 'Girdi/Çıktı Hatası',
        categoryEn: 'Input/Output Error',
        title: "'scanf' Fonksiyonunda '&' (Adres) İşleci Unutulmuş",
        titleEn: "Missing '&' (Address-Of) Operator in 'scanf'",
        explanation: "`scanf` fonksiyonu değişkenin değerini değil, bellekteki adresini ister. Bu yüzden normal değişkenlerin önüne '&' konulmalıdır.",
        explanationEn: "'scanf' requires memory pointers to store values. Standard variables need a leading '&'.",
        howToFix: "scanf çağrısında değişkenin başına '&' koyun (örneğin: `scanf(\"%d\", &sayi);`).",
        howToFixEn: "Add '&' before the variable in scanf (e.g. `scanf(\"%d\", &sayi);`).",
        badExample: "int sayi;\nscanf(\"%d\", sayi); // HATA! Program çökebilir",
        goodExample: "int sayi;\nscanf(\"%d\", &sayi); // DOĞRU",
        canAutoFix: false,
      );
    }

    // 10. Tanımsız değişken (undeclared)
    if (msg.contains("undeclared") || msg.contains("not declared") || msg.contains("identifier")) {
      return ErrorDiagnosis(
        category: 'Değişken Tanımlama',
        categoryEn: 'Variable Declaration',
        title: 'Tanımsız Değişken veya Fonksiyon',
        titleEn: 'Undeclared Variable or Function',
        explanation: "Kullanılmak istenen değişken veya fonksiyon daha önce bildirilmemiş. "
            "C dilinde büyük/küçük harf duyarlılığı (Case-Sensitivity) vardır; yazım farkı olabilir.",
        explanationEn: "The variable or function has not been declared before use. C is case-sensitive.",
        howToFix: "1. Değişken adının yazımını kontrol edin (Büyük/küçük harf farkı).\n"
            "2. Değişkeni kullanmadan önce tipini belirterek tanımlayın (Örn: `int x = 0;`).\n"
            "3. Fonksiyon ise prototipinin yukarıda yazıldığından emin olun.",
        howToFixEn: "1. Check spelling and case.\n"
            "2. Declare the variable with its type before using it (e.g., `int x = 0;`).\n"
            "3. Ensure function prototypes are declared.",
        badExample: "sayi = 10; // Hata: 'sayi' tanımlanmamış",
        goodExample: "int sayi = 10; // Doğru tanım",
        canAutoFix: false,
      );
    }

    // Varsayılan tanı
    return ErrorDiagnosis(
      category: 'Derleme Mesajı',
      categoryEn: 'Compiler Message',
      title: error.isWarning ? 'Derleme Uyarısı' : 'Derleme Hatası',
      titleEn: error.isWarning ? 'Compiler Warning' : 'Compiler Error',
      explanation: "Derleyici '${error.message}' mesajını bildirdi. Satır ${error.line}, Sütun ${error.column} üzerindeki kodu inceleyin.",
      explanationEn: "The compiler reported: '${error.message}'. Inspect code at Line ${error.line}, Column ${error.column}.",
      howToFix: "1. Hata satırındaki parantezleri ve değişken isimlerini kontrol edin.\n"
          "2. Tanımsız fonksiyon veya eksik kütüphane olup olmadığına bakın.",
      howToFixEn: "1. Check syntax, parentheses, and variable names around the line.\n"
          "2. Ensure all needed headers are included.",
      canAutoFix: false,
    );
  }

  static String applyAutoFix(String code, CompilerError error) {
    if (error.diagnosis == null || !error.diagnosis!.canAutoFix || code.isEmpty) {
      return code;
    }

    switch (error.diagnosis!.fixType) {
      case AutoFixType.addSemicolon:
        return _fixAddSemicolon(code, error.line);

      case AutoFixType.addIncludeStdio:
        return _fixAddInclude(code, '<stdio.h>');

      case AutoFixType.addIncludeStdlib:
        return _fixAddInclude(code, '<stdlib.h>');

      case AutoFixType.addIncludeMath:
        return _fixAddInclude(code, '<math.h>');

      case AutoFixType.addIncludeString:
        return _fixAddInclude(code, '<string.h>');

      case AutoFixType.addMainFunction:
        return _fixAddMain(code);

      default:
        return code;
    }
  }

  static String _fixAddInclude(String code, String header) {
    final inc = '#include $header';
    if (code.contains(inc)) return code;
    return '$inc\n$code';
  }

  static String _fixAddSemicolon(String code, int lineIndex1Based) {
    final lines = code.split(RegExp(r'\r?\n'));
    final target = lineIndex1Based - 1;

    // Hedef satır
    if (target >= 0 && target < lines.length) {
      final cur = lines[target].trimRight();
      if (!cur.endsWith(';') && !cur.endsWith('{') && !cur.endsWith('}')) {
        lines[target] = '$cur;';
        return lines.join('\n');
      }
    }

    // Bir önceki satır
    final prev = target - 1;
    if (prev >= 0 && prev < lines.length) {
      final cur = lines[prev].trimRight();
      if (!cur.endsWith(';') && !cur.endsWith('{') && !cur.endsWith('}')) {
        lines[prev] = '$cur;';
        return lines.join('\n');
      }
    }

    return code;
  }

  static String _fixAddMain(String code) {
    return '$code\n\nint main(void) {\n    printf("Merhaba Dunya!\\n");\n    return 0;\n}\n';
  }
}
