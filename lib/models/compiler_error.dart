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
  final String? categoryDe;
  final String title;
  final String? titleEn;
  final String? titleDe;
  final String explanation;
  final String? explanationEn;
  final String? explanationDe;
  final String howToFix;
  final String? howToFixEn;
  final String? howToFixDe;
  final String goodExample;
  final String badExample;
  final bool canAutoFix;
  final AutoFixType fixType;
  final String autoFixDescription;
  final String? autoFixDescriptionEn;
  final String? autoFixDescriptionDe;

  ErrorDiagnosis({
    this.category = 'Genel Hata',
    this.categoryEn,
    this.categoryDe,
    this.title = 'Derleme Hatası',
    this.titleEn,
    this.titleDe,
    this.explanation = '',
    this.explanationEn,
    this.explanationDe,
    this.howToFix = '',
    this.howToFixEn,
    this.howToFixDe,
    this.goodExample = '',
    this.badExample = '',
    this.canAutoFix = false,
    this.fixType = AutoFixType.none,
    this.autoFixDescription = '',
    this.autoFixDescriptionEn,
    this.autoFixDescriptionDe,
  });

  String getDisplayTitle([dynamic arg]) {
    if (arg is String) {
      if (arg == 'de') return titleDe ?? titleEn ?? title;
      if (arg == 'en') return titleEn ?? title;
      return title;
    }
    final isTr = arg is bool ? arg : true;
    return isTr ? title : (titleEn ?? title);
  }

  String getDisplayExplanation([dynamic arg]) {
    if (arg is String) {
      if (arg == 'de') return explanationDe ?? explanationEn ?? explanation;
      if (arg == 'en') return explanationEn ?? explanation;
      return explanation;
    }
    final isTr = arg is bool ? arg : true;
    return isTr ? explanation : (explanationEn ?? explanation);
  }

  String getDisplayHowToFix([dynamic arg]) {
    if (arg is String) {
      if (arg == 'de') return howToFixDe ?? howToFixEn ?? howToFix;
      if (arg == 'en') return howToFixEn ?? howToFix;
      return howToFix;
    }
    final isTr = arg is bool ? arg : true;
    return isTr ? howToFix : (howToFixEn ?? howToFix);
  }

  String getDisplayAutoFixDesc([dynamic arg]) {
    if (arg is String) {
      if (arg == 'de') return autoFixDescriptionDe ?? autoFixDescriptionEn ?? autoFixDescription;
      if (arg == 'en') return autoFixDescriptionEn ?? autoFixDescription;
      return autoFixDescription;
    }
    final isTr = arg is bool ? arg : true;
    return isTr ? autoFixDescription : (autoFixDescriptionEn ?? autoFixDescription);
  }
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
