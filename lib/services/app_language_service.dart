import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class AppLanguageService extends ChangeNotifier {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal() {
    loadSettings();
  }

  // 1. Uygulama Arayüz Dili ('tr' veya 'en')
  String _uiLanguage = 'tr';
  String get uiLanguage => _uiLanguage;
  bool get isUiTurkish => _uiLanguage == 'tr';
  bool get isUiEnglish => _uiLanguage == 'en';

  // 2. Yapay Zeka Asistan Dili ('tr' veya 'en')
  String _aiLanguage = 'tr';
  String get aiLanguage => _aiLanguage;
  bool get isAiTurkish => _aiLanguage == 'tr';
  bool get isAiEnglish => _aiLanguage == 'en';

  // Etiketler: TÜRKÇEDE BAYRAK VAR, İNGİLİZCEDE KESİNLİKLE BAYRAK YOK
  static const String turkishLabel = '🇹🇷 Türkçe';
  static const String englishLabel = 'English'; // Kullanıcı isteği: İngilizcede bayrak olmasın

  static const String turkishShortLabel = '🇹🇷 TR';
  static const String englishShortLabel = 'EN'; // Kullanıcı isteği: İngilizcede bayrak olmasın

  File _getConfigFile() {
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
    final configDir = Directory(p.join(userProfile, '.cstudio'));
    if (!configDir.existsSync()) {
      configDir.createSync(recursive: true);
    }
    return File(p.join(configDir.path, 'app_settings.json'));
  }

  void loadSettings() {
    try {
      final file = _getConfigFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content);
        if (data is Map) {
          if (data.containsKey('uiLanguage')) {
            _uiLanguage = data['uiLanguage'] as String;
          }
          if (data.containsKey('aiLanguage')) {
            _aiLanguage = data['aiLanguage'] as String;
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
        'updatedAt': DateTime.now().toIso8601String(),
      };
      file.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
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
    return _strings[_uiLanguage]?[key] ?? _strings['tr']?[key] ?? key;
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
    },
  };
}
