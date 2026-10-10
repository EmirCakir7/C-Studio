enum ErrorSeverity { error, warning, info }

enum AutoFixType {
  none,
  addSemicolon,
  addIncludeStdio,
  addIncludeStdlib,
  addIncludeMath,
  addIncludeString,
  addMainFunction,
}

class ErrorDiagnosis {
  final String category;
  final String? categoryEn;
  final String title;
  final String? titleEn;
  final String explanation;
  final String? explanationEn;
  final String howToFix;
  final String? howToFixEn;
  final String goodExample;
  final String badExample;
  final bool canAutoFix;
  final AutoFixType fixType;
  final String autoFixDescription;
  final String? autoFixDescriptionEn;

  ErrorDiagnosis({
    this.category = 'Genel Hata',
    this.categoryEn,
    this.title = 'Derleme Hatası',
    this.titleEn,
    this.explanation = '',
    this.explanationEn,
    this.howToFix = '',
    this.howToFixEn,
    this.goodExample = '',
    this.badExample = '',
    this.canAutoFix = false,
    this.fixType = AutoFixType.none,
    this.autoFixDescription = '',
    this.autoFixDescriptionEn,
  });

  String getDisplayTitle(bool isTr) => isTr ? title : (titleEn ?? title);
  String getDisplayExplanation(bool isTr) => isTr ? explanation : (explanationEn ?? explanation);
  String getDisplayHowToFix(bool isTr) => isTr ? howToFix : (howToFixEn ?? howToFix);
  String getDisplayAutoFixDesc(bool isTr) => isTr ? autoFixDescription : (autoFixDescriptionEn ?? autoFixDescription);
}

class CompilerError {
  final String filePath;
  final String fileName;
  final int line;
  final int column;
  final ErrorSeverity severity;
  final String message;
  final String rawLine;
  final ErrorDiagnosis? diagnosis;

  CompilerError({
    required this.filePath,
    required this.fileName,
    required this.line,
    required this.column,
    required this.severity,
    required this.message,
    required this.rawLine,
    this.diagnosis,
  });

  bool get isWarning => severity == ErrorSeverity.warning;
}
