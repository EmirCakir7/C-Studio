import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'app_path_service.dart';

class AppLanguageService extends ChangeNotifier {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal() {
    loadSettings();
  }

  // 1. Uygulama Arayüz Dili ('tr', 'en', 'de', 'custom')
  String _uiLanguage = 'tr';
  String get uiLanguage => _uiLanguage;
  String get currentLanguage => _uiLanguage;
  bool get isUiTurkish => _uiLanguage == 'tr';
  bool get isUiEnglish => _uiLanguage == 'en';
  bool get isUiGerman => _uiLanguage == 'de';

  // 2. Yapay Zeka Asistan Dili ('tr', 'en', 'de', 'custom')
  String _aiLanguage = 'tr';
  String get aiLanguage => _aiLanguage;
  bool get isAiTurkish => _aiLanguage == 'tr';
  bool get isAiEnglish => _aiLanguage == 'en';
  bool get isAiGerman => _aiLanguage == 'de';

  // 3. Kullanıcı Tanımlı Özel Dil (Custom Language Pack)
  String? _customLanguageName;
  String? get customLanguageName => _customLanguageName;
  bool get isCustomLanguage => _uiLanguage == 'custom';
  bool get hasCustomLanguage => _customTranslations.isNotEmpty && _customLanguageName != null;
  Map<String, String> _customTranslations = {};
  Map<String, String> get customTranslations => _customTranslations;

  // Etiketler: Türkçe ve Almancada bayrak var, İngilizcede kullanıcı isteği üzerine bayrak yok
  static const String turkishLabel = '🇹🇷 Türkçe';
  static const String englishLabel = 'English';
  static const String germanLabel = '🇩🇪 Deutsch';

  static const String turkishShortLabel = '🇹🇷 TR';
  static const String englishShortLabel = 'EN';
  static const String germanShortLabel = '🇩🇪 DE';

  /// Çok dilli metin seçici yardımcı fonksiyon (Özel dil desteğiyle)
  String trEnDe(String tr, String en, String de) {
    if (isCustomLanguage) {
      final custom = _customTranslations[en] ?? _customTranslations[tr];
      if (custom != null && custom.trim().isNotEmpty) {
        return custom;
      }
    }
    if (_uiLanguage == 'de') return de;
    if (_uiLanguage == 'en') return en;
    return tr;
  }

  File _getConfigFile() => AppPathService.configFile;

  File _getCustomLanguageFile() => AppPathService.customLanguageFile;

  void loadSettings() {
    try {
      final customFile = _getCustomLanguageFile();
      if (customFile.existsSync()) {
        final content = customFile.readAsStringSync();
        final data = jsonDecode(content);
        if (data is Map) {
          _customLanguageName = data['language_name']?.toString();
          if (data['translations'] is Map) {
            _customTranslations = (data['translations'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            );
          }
        }
      }
    } catch (_) {}

    try {
      final file = _getConfigFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content);
        if (data is Map) {
          if (data.containsKey('uiLanguage')) {
            final lang = data['uiLanguage'] as String;
            if (lang == 'tr' || lang == 'en' || lang == 'de' || (lang == 'custom' && hasCustomLanguage)) {
              _uiLanguage = lang;
            }
          }
          if (data.containsKey('aiLanguage')) {
            final lang = data['aiLanguage'] as String;
            if (lang == 'tr' || lang == 'en' || lang == 'de' || lang == 'custom') {
              _aiLanguage = lang;
            }
          }
        }
      }
    } catch (_) {}
  }

  void saveSettings() {
    try {
      final file = _getConfigFile();
      final data = {
        'uiLanguage': _uiLanguage,
        'aiLanguage': _aiLanguage,
        'customLanguageName': _customLanguageName,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      file.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }

  Future<bool> importCustomLanguageFile(String filePath, String languageName) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! Map) return false;

      final name = languageName.trim().isNotEmpty
          ? languageName.trim()
          : (data['language_name']?.toString() ?? 'Custom');

      final rawTranslations = data['translations'] is Map
          ? (data['translations'] as Map)
          : data;

      final Map<String, String> parsed = {};
      rawTranslations.forEach((key, value) {
        if (key != null && value != null && value.toString().trim().isNotEmpty) {
          parsed[key.toString()] = value.toString();
        }
      });

      if (parsed.isEmpty) return false;

      _customLanguageName = name;
      _customTranslations = parsed;
      _uiLanguage = 'custom';

      final customFile = _getCustomLanguageFile();
      final out = {
        'language_name': name,
        'translations': parsed,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await customFile.writeAsString(jsonEncode(out));

      saveSettings();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void setUiLanguage(String lang, {bool syncAiLanguage = true}) {
    bool changed = false;
    if (_uiLanguage != lang) {
      _uiLanguage = lang;
      changed = true;
    }
    if (syncAiLanguage && _aiLanguage != lang) {
      _aiLanguage = lang;
      changed = true;
    }
    if (changed) {
      saveSettings();
      notifyListeners();
    }
  }

  void setUnifiedLanguage(String lang) {
    _uiLanguage = lang;
    _aiLanguage = lang;
    saveSettings();
    notifyListeners();
  }

  void setAiLanguage(String lang) {
    if (_aiLanguage != lang) {
      _aiLanguage = lang;
      saveSettings();
      notifyListeners();
    }
  }

  String t(String key) {
    if (isCustomLanguage) {
      final custom = _customTranslations[key];
      if (custom != null && custom.trim().isNotEmpty) {
        return custom;
      }
    }
    return _strings[_uiLanguage]?[key] ?? _strings['en']?[key] ?? _strings['tr']?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _strings = {
    'tr': {
      'run': 'Çalıştır (F5)',
      'compile_only': 'Sadece Derle',
      'ai_assistant': 'AI Asistanı',
      'new_project': 'Yeni Proje',
      'open_project': 'Proje Aç',
      'settings': 'Ayarlar',
      'project_explorer': 'PROJE GEZGİNİ',
      'files': 'DOSYALAR',
      'new_file': 'Yeni Dosya',
      'save': 'Kaydet',
      'tab_terminal': 'Terminal & Çıktı',
      'tab_errors': 'Hatalar ve Akıllı Çözümler',
      'tab_ai': '🤖 AI Asistanı',
      'tab_logs': 'Derleme Kayıtları',
      'compiler': 'Derleyici',
      'line': 'Satır',
      'col': 'Sütun',
      'saved': 'Kaydedildi',
      'unsaved': 'Kaydedilmedi',
      'no_errors': 'Tebrikler! Kodunuzda hata veya uyarı bulunmuyor.',
      'press_f5': 'Programınızı F5 tuşu ile doğrudan derleyip çalıştırabilirsiniz.',
      'error_title': 'HATA VE ÇÖZÜM ANALİZİ',
      'why_happened': '❓ NEDEN OLDU?',
      'how_to_fix': '🛠️ NASIL DÜZELTİLİR?',
      'correct_example': '📝 DOĞRU KOD ÖRNEĞİ:',
      'auto_fix': 'Otomatik Düzelt',
      'ai_solve_explain': 'AI ile Çöz & Açıkla',
      'settings_title': 'C-Studio Ayarları',
      'settings_subtitle': 'Uygulama arayüz dili, yapay zeka motoru ve derleyici tercihleri',
      'tab_general': 'Genel',
      'tab_ai_settings': 'Yapay Zeka',
      'tab_compiler_settings': 'Derleyici',
      'ui_language': 'Uygulama Arayüz Dili',
      'ai_language': 'Yapay Zeka Asistan Dili',
      'ai_engine': 'Yapay Zeka Motoru',
      'offline_qwen': 'Dahili Çevrimdışı (Qwen 2.5 Coder)',
      'online_cloud': 'Çevrimiçi Bulut Motoru (API)',
      'cancel': 'İptal',
      'save_and_apply': 'Kaydet ve Uygula',
      'auto_save': 'Otomatik Kaydetme',
      'auto_save_desc': 'Yazarken kod değişikliklerini anlık kaydet',
      'font_size': 'Editör Yazı Boyutu',
      'special_keys': 'Hızlı Tuşlar',
      'special_keys_tooltip': 'Klavyede zor bulunan tuşlar paneli ({}, [], \\, |, ~, ->)',
      'about_developer': 'C-Studio Modern C IDE v1.2',
      'tutor_policy_note': 'Eğitim & Hoca Kuralı: Asistan sıfırdan hazır kod/ödev yazmaz; algoritma adımlarını ve hata çözümlerini öğretir.',
      'download_ai_model': '⬇️ AI Modelini İndir (~881 MB)',
      'downloading_ai_model': 'AI Modeli İndiriliyor...',
      'model_not_installed': 'Dahili Yapay Zeka Modeli Yüklü Değil',
      'model_not_installed_desc': 'Akıllı hata analizi ve kod danışmanı için Qwen 2.5 Coder modelini tek tıkla indirin.',
      'model_download_success': '✔ Model başarıyla indirildi ve aktif edildi!',
      'download_failed': 'İndirme başarısız oldu',
      'retry_download': 'Yeniden Dene',
    },
    'en': {
      'run': 'Run (F5)',
      'compile_only': 'Compile Only',
      'ai_assistant': 'AI Assistant',
      'new_project': 'New Project',
      'open_project': 'Open Project',
      'settings': 'Settings',
      'project_explorer': 'PROJECT EXPLORER',
      'files': 'FILES',
      'new_file': 'New File',
      'save': 'Save',
      'tab_terminal': 'Terminal & Output',
      'tab_errors': 'Errors & Smart Solutions',
      'tab_ai': '🤖 AI Assistant',
      'tab_logs': 'Build Logs',
      'compiler': 'Compiler',
      'line': 'Line',
      'col': 'Col',
      'saved': 'Saved',
      'unsaved': 'Unsaved',
      'no_errors': 'Great! No errors or warnings found in your code.',
      'press_f5': 'You can press F5 to compile and run your program directly.',
      'error_title': 'ERROR & SOLUTION ANALYSIS',
      'why_happened': '❓ WHY DID IT HAPPEN?',
      'how_to_fix': '🛠️ HOW TO FIX IT?',
      'correct_example': '📝 CORRECT CODE EXAMPLE:',
      'auto_fix': 'Auto Fix',
      'ai_solve_explain': 'Analyze & Explain with AI',
      'settings_title': 'C-Studio Settings',
      'settings_subtitle': 'Application UI language, AI engine, and compiler preferences',
      'tab_general': 'General',
      'tab_ai_settings': 'AI Assistant',
      'tab_compiler_settings': 'Compiler',
      'ui_language': 'Application UI Language',
      'ai_language': 'AI Assistant Language',
      'ai_engine': 'AI Engine',
      'offline_qwen': 'Built-in Offline (Qwen 2.5 Coder)',
      'online_cloud': 'Online Cloud Engine (API)',
      'cancel': 'Cancel',
      'save_and_apply': 'Save and Apply',
      'auto_save': 'Auto Save',
      'auto_save_desc': 'Automatically save file changes as you type',
      'font_size': 'Editor Font Size',
      'special_keys': 'Quick Keys',
      'special_keys_tooltip': 'Panel for hard-to-reach keyboard characters ({}, [], \\, |, ~, ->)',
      'about_developer': 'C-Studio Modern C IDE v1.2',
      'tutor_policy_note': 'Course Policy: The tutor does not write full code or homework from scratch; it teaches logic, algorithms, and debugging.',
      'download_ai_model': '⬇️ Download AI Model (~881 MB)',
      'downloading_ai_model': 'Downloading AI Model...',
      'model_not_installed': 'Offline AI Model Not Installed',
      'model_not_installed_desc': 'Download Qwen 2.5 Coder with 1-click for smart error diagnostics and offline coding assistance.',
      'model_download_success': '✔ Model downloaded and activated successfully!',
      'download_failed': 'Download failed',
      'retry_download': 'Retry',
    },
    'de': {
      'run': 'Ausführen (F5)',
      'compile_only': 'Nur kompilieren',
      'ai_assistant': 'KI-Assistent',
      'new_project': 'Neues Projekt',
      'open_project': 'Projekt öffnen',
      'settings': 'Einstellungen',
      'project_explorer': 'PROJEKT-EXPLORER',
      'files': 'DATEIEN',
      'new_file': 'Neue Datei',
      'save': 'Speichern',
      'tab_terminal': 'Terminal & Ausgabe',
      'tab_errors': 'Fehler & Intelligente Lösungen',
      'tab_ai': '🤖 KI-Assistent',
      'tab_logs': 'Kompilier-Protokolle',
      'compiler': 'Compiler',
      'line': 'Zeile',
      'col': 'Spalte',
      'saved': 'Gespeichert',
      'unsaved': 'Nicht gespeichert',
      'no_errors': 'Großartig! Keine Fehler oder Warnungen im Code gefunden.',
      'press_f5': 'Drücken Sie F5, um Ihr Programm direkt zu kompilieren und auszuführen.',
      'error_title': 'FEHLER- & LÖSUNGSANALYSE',
      'why_happened': '❓ WARUM IST DAS PASSIERT?',
      'how_to_fix': '🛠️ WIE WIRD ES BEHOBEN?',
      'correct_example': '📝 KORREKTES CODE-BEISPIEL:',
      'auto_fix': 'Automatisch beheben',
      'ai_solve_explain': 'Mit KI analysieren & erklären',
      'settings_title': 'C-Studio Einstellungen',
      'settings_subtitle': 'Oberflächensprache, KI-Engine und Compiler-Einstellungen',
      'tab_general': 'Allgemein',
      'tab_ai_settings': 'KI-Assistent',
      'tab_compiler_settings': 'Compiler',
      'ui_language': 'Benutzeroberflächensprache',
      'ai_language': 'KI-Assistentensprache',
      'ai_engine': 'KI-Engine',
      'offline_qwen': 'Integriert Offline (Qwen 2.5 Coder)',
      'online_cloud': 'Online-Cloud-Engine (API)',
      'cancel': 'Abbrechen',
      'save_and_apply': 'Speichern und Anwenden',
      'auto_save': 'Automatisches Speichern',
      'auto_save_desc': 'Änderungen während der Eingabe automatisch speichern',
      'font_size': 'Editor-Schriftgröße',
      'special_keys': 'Sondertasten',
      'special_keys_tooltip': 'Leiste für Tastatur-Sonderzeichen ({}, [], \\, |, ~, ->)',
      'about_developer': 'C-Studio Moderne C-IDE v1.2',
      'tutor_policy_note': 'Richtlinie: Der Assistent erklärt Fehler, beantwortet C-Fragen und hilft bei Algorithmen.',
      'download_ai_model': '⬇️ KI-Modell herunterladen (~881 MB)',
      'downloading_ai_model': 'KI-Modell wird heruntergeladen...',
      'model_not_installed': 'Offline-KI-Modell nicht installiert',
      'model_not_installed_desc': 'Laden Sie Qwen 2.5 Coder mit 1 Klick für intelligente Fehlerdiagnose und Offline-Hilfe herunter.',
      'model_download_success': '✔ Modell erfolgreich heruntergeladen und aktiviert!',
      'download_failed': 'Download fehlgeschlagen',
      'retry_download': 'Wiederholen',
    },
  };
}
