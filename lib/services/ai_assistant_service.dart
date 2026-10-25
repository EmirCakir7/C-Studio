import 'dart:convert';
import 'dart:io';
import '../models/compiler_error.dart';
import 'local_ai_service.dart';
import 'app_language_service.dart';
import 'compiler_service.dart';
import 'smart_error_advisor.dart';
import 'app_path_service.dart';

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal() {
    loadConfig();
  }

  final LocalAiService _localAiService = LocalAiService();
  LocalAiService get localAiService => _localAiService;
  final CompilerService _compilerService = CompilerService();

  /// Kalıcı mesaj listesi (Sekme değişimlerinde asla silinmez)
  final List<AiMessage> messages = [];

  // Sağlayıcı: 'local' (Dahili Çevrimdışı Qwen) veya 'gemini' (Google Gemini API)
  String _provider = 'local';
  String _geminiApiKey = '';
  String _geminiModel = 'gemini-3.8-flash';

  String get provider => _provider;
  bool get isLocal => _provider == 'local';
  bool get isCloud => _provider == 'gemini';
  bool get isGemini => _provider == 'gemini';

  String get language => AppLanguageService().aiLanguage;
  bool get isTurkish => AppLanguageService().isAiTurkish;
  bool get isEnglish => AppLanguageService().isAiEnglish;
  bool get isGerman => AppLanguageService().isAiGerman;

  String get geminiApiKey => _geminiApiKey;
  String get geminiModel => _geminiModel;
  bool get hasGeminiApiKey => _geminiApiKey.trim().isNotEmpty;

  String get apiKey => _geminiApiKey;
  bool get hasApiKey => hasGeminiApiKey;
  String get selectedCloudModel => _geminiModel;

  String get selectedModel {
    if (isGemini) {
      if (_geminiModel == 'gemini-3.8-flash') return 'Gemini 3.8 Flash';
      if (_geminiModel == 'gemini-3.8-pro') return 'Gemini 3.8 Pro';
      if (_geminiModel == 'gemini-3.6-flash') return 'Gemini 3.6 Flash';
      return _geminiModel;
    }
    return Platform.isWindows
        ? _localAiService.activeModelDisplayName
        : 'C-Studio AI Mobile (Smart C Engine)';
  }

  bool get isLocalAiAvailable => Platform.isWindows ? _localAiService.isLocalAiSupported() : true;

  bool get isReady {
    if (isGemini) {
      return hasGeminiApiKey;
    }
    return isLocalAiAvailable;
  }

  File _getConfigFile() => AppPathService.aiConfigFile;

  void loadConfig() {
    try {
      final file = _getConfigFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content);
        if (data is Map) {
          if (data.containsKey('provider')) {
            _provider = data['provider'] as String;
          }
          if (data.containsKey('geminiApiKey')) {
            _geminiApiKey = data['geminiApiKey'] as String;
          } else if (data.containsKey('apiKey')) {
            _geminiApiKey = data['apiKey'] as String;
          }
          if (data.containsKey('geminiModel')) {
            _geminiModel = data['geminiModel'] as String;
          } else if (data.containsKey('cloudModel')) {
            _geminiModel = data['cloudModel'] as String;
          }
          if (data.containsKey('language')) {
            final lang = data['language'] as String;
            AppLanguageService().setAiLanguage(lang);
          }
        }
      }
    } catch (_) {}
  }

  void saveConfig({String? provider, String? apiKey, String? cloudModel, String? language}) {
    if (provider != null) _provider = provider;
    if (apiKey != null) _geminiApiKey = apiKey.trim();
    if (cloudModel != null) _geminiModel = cloudModel;
    if (language != null) AppLanguageService().setAiLanguage(language);

    try {
      final file = _getConfigFile();
      final data = {
        'provider': _provider,
        'geminiApiKey': _geminiApiKey,
        'geminiModel': _geminiModel,
        'language': AppLanguageService().aiLanguage,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      file.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }

  void setProvider(String prov) {
    _provider = prov;
    saveConfig(provider: prov);
  }

  void setLanguage(String lang) {
    AppLanguageService().setAiLanguage(lang);
    saveConfig(language: lang);
  }

  void saveApiKey(String key, {String? model}) {
    _geminiApiKey = key.trim();
    if (model != null) _geminiModel = model;
    saveConfig(apiKey: _geminiApiKey, cloudModel: _geminiModel);
  }

  /// Google Gemini API bağlantısını test eder
  Future<bool> testGeminiConnection({String? apiKey, String? model}) async {
    final key = (apiKey ?? _geminiApiKey).trim();
    final mod = model ?? _geminiModel;
    if (key.isEmpty) return false;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$mod:generateContent?key=$key',
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);

    try {
      final req = await client.postUrl(url);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': 'Ping'}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 5,
        }
      };
      req.add(utf8.encode(jsonEncode(payload)));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 200) {
        return true;
      }
      try {
        final errJson = jsonDecode(body);
        final errMsg = errJson['error']?['message'] ?? body;
        throw Exception(errMsg);
      } catch (_) {
        throw Exception('HTTP ${res.statusCode}: $body');
      }
    } finally {
      client.close();
    }
  }

  /// Kodlama ve yazılım dışı konuları tespit eder
  static bool isNonCodingTopic(String prompt) {
    final lower = prompt.toLowerCase().trim();
    if (lower.isEmpty) return false;

    // Kodlama / C / yazılımla ilgili kelimeler varsa ASLA reddetme
    final codingKeywords = [
      'c', 'kod', 'code', 'hata', 'error', 'fonksiyon', 'function', 'void', 'int',
      'float', 'double', 'char', 'string', 'pointer', 'işaretçi', 'isaretci',
      'array', 'dizi', 'bellek', 'memory', 'malloc', 'free', 'struct', 'typedef',
      'printf', 'scanf', 'include', 'main', 'for', 'while', 'if', 'else', 'switch',
      'case', 'break', 'return', 'derle', 'compile', 'tcc', 'gcc', 'algoritma',
      'döngü', 'dongu', 'koşul', 'kosul', 'değişken', 'degisken', 'ekle', 'düzelt',
      'duzelt', 'çöz', 'coz', 'yaz', 'program', 'satır', 'satir', 'sütun', 'sutun',
      'çalış', 'calis', 'çıktı', 'cikti', 'terminal', 'ekran', 'değer', 'deger',
      'adres', '&', '*', ';', '{', '}', 'parametre', 'ödev', 'odev', 'soru', 'nasıl'
    ];

    for (final kw in codingKeywords) {
      if (lower.contains(kw)) return false;
    }

    // Kodlama dışı bariz konular (yemek, spor, hava durumu, siyaset vb.)
    final nonCodingKeywords = [
      'pizza', 'yemek', 'tarif', 'futbol', 'maç', 'mac', 'skor', 'hava', 'yağmur',
      'güneş', 'siyaset', 'parti', 'seçim', 'müzik', 'şarkı', 'film', 'dizi',
      'aşk', 'burç', 'astroloji', 'dolar', 'euro', 'altın', 'borsa'
    ];

    for (final nw in nonCodingKeywords) {
      if (lower.contains(nw)) return true;
    }

    return false;
  }

  /// Akıllı asistan talimatları (Kullanıcının 4 Temel Kuralı)
  String getEffectiveSystemInstruction({String? customInstruction}) {
    if (customInstruction != null && customInstruction.isNotEmpty) {
      return customInstruction;
    }

    if (isTurkish) {
      return 'Sen C-Studio Akıllı Kod Asistanısın. C programlama dili ve yazılım geliştirme alanında uzman bir asistansın.\n'
          'Daima samimi, net ve akıcı Türkçe ile yanıt ver.\n\n'
          'Aşağıdaki 4 temel kurala KESİNLİKLE uy:\n'
          '1. HATA VE DÜZELTME:\n'
          '   - Kullanıcı koddaki hatalarla ilgili soru sorduğunda veya kodda bir hata varsa mutlaka şu 3 başlıkla açıkla:\n'
          '     • Nerede: Hatanın hangi dosyada, kaçıncı satırda ve hangi kod parçasında olduğunu açıkça belirt.\n'
          '     • Neden: Hatanın neden kaynaklandığını, C dilindeki kuralını (noktalı virgül eksikliği, scanf için & bellek adresi gerekliliği, tür uyuşmazlığı vb.) detaylıca anlat.\n'
          '     • Nasıl Düzeltildiği: Hatayı gidermek için ne yapıldığını adım adım anlat ve ardından düzeltilmiş tam ve çalışan C kodunu ```c ve ``` blokları arasında eksiksiz ver.\n'
          '2. C DİLİ BİLGİ VE SORU-CEVAP:\n'
          '   - C programlama dili ile ilgili bir kavram (pointer, struct, döngüler, diziler, bellek yönetimi, algoritmalar vb.) sorulduğunda veya bilgi istendiğinde, konuyu adım adım, öğretici ve örneklerle açıkla.\n'
          '3. KODA EKLEME VE GELİŞTİRME:\n'
          '   - Kullanıcı koda ekleme yapılmasını istediğinde (örneğin döngü ekle, kullanıcıdan girdi al, fonksiyon yaz vb.), istenen eklemeleri koda entegre et ve güncellenmiş çalışan tam C kodunu ```c ve ``` blokları arasında ver.\n'
          '4. KODLAMA VE YAZILIM DIŞI KONULARI REDDETME:\n'
          '   - Kodlama ve yazılım dışındaki konulara (günlük sohbet, spor, yemek, siyaset vb.) KESİNLİKLE CEVAP VERME. Sadece "Ben C-Studio Akıllı Kod Asistanıyım. Yalnızca C programlama dili ve yazılım geliştirme konularında yardımcı olabilirim." cevabını ver.';
    } else if (isGerman) {
      return 'Du bist der C-Studio KI-Code-Assistent, ein Experte für C-Programmierung und Softwareentwicklung.\n'
          'Antworte immer auf klarem, präzisem und verständlichem Deutsch.\n\n'
          'Befolge strikt diese 4 Grundregeln:\n'
          '1. FEHLERANALYSE & BEHEBUNG:\n'
          '   - Wenn nach Fehlern gefragt wird oder ein Fehler im Code vorliegt, erkläre ihn anhand dieser 3 Punkte:\n'
          '     • Wo: Datei, Zeilennummer und den genauen Codeausschnitt nennen.\n'
          '     • Warum: Die Ursache und die verletzte C-Sprachregel genau erklären.\n'
          '     • Wie behoben: Die Lösung Schritt für Schritt erklären und den vollständigen funktionierenden C-Code in ```c und ``` Blöcken bereitstellen.\n'
          '2. C-WISSEN & FRAGEN:\n'
          '   - Bei Fragen zu C-Konzepten (Pointer, Structs, Schleifen, Speicherverwaltung usw.) schrittweise und mit Beispielen erklären.\n'
          '3. CODE-ERWEITERUNGEN:\n'
          '   - Wenn der Benutzer Erweiterungen wünscht, integriere sie und gib den vollständigen aktualisierten Code in ```c und ``` Blöcken aus.\n'
          '4. THEMEN FREMDER BEREICHE ABLEHNEN:\n'
          '   - Antworte NICHT auf themenfremde Fragen. Antworte ausschließlich mit:\n'
          '     "Ich bin der C-Studio KI-Code-Assistent. Ich kann nur bei Fragen zur C-Programmierung und Softwareentwicklung helfen."';
    } else {
      return 'You are C-Studio AI, an expert C programming assistant and software tutor.\n'
          'Always respond in clear, fluent English.\n\n'
          'Follow these 4 core rules strictly:\n'
          '1. ERROR DETECTION & FIXING:\n'
          '   - When asked about errors or when an error is present, respond with:\n'
          '     • Where: State the file, line number, and exact code snippet.\n'
          '     • Why: Explain the root cause and the C language rule violated.\n'
          '     • How It Was Fixed: Explain the fix step by step, and provide the complete working C code inside ```c and ``` blocks.\n'
          '2. C LANGUAGE KNOWLEDGE & QUESTIONS:\n'
          '   - When asked about C concepts or general programming questions, explain clearly with step-by-step guidance and examples.\n'
          '3. CODE MODIFICATIONS & FEATURE ADDITIONS:\n'
          '   - When the user asks to add features or modify code, integrate the changes and provide the complete updated working C code inside ```c and ``` blocks.\n'
          '4. REFUSE NON-CODING TOPICS:\n'
          '   - Do NOT answer any non-programming topics. Respond only with:\n'
          '     "I am C-Studio AI. I can only assist with C programming, software development, and algorithms."';
    }
  }

  Future<String> sendPrompt({
    required String prompt,
    List<AiMessage>? history,
    String? currentCode,
    String? systemInstruction,
  }) async {
    // 0. Kodlama / yazılım dışı konu kontrolü
    if (isNonCodingTopic(prompt)) {
      if (isTurkish) {
        return 'Ben C-Studio Akıllı Kod Asistanıyım. Yalnızca C programlama dili, yazılım geliştirme ve algoritmalarla ilgili konularda yardımcı olabilirim. C kodunuz veya programlama sorularınızı yanıtlamaktan memnuniyet duyarım! 🚀';
      } else if (isGerman) {
        return 'Ich bin der C-Studio KI-Code-Assistent. Ich kann nur bei Fragen zur C-Programmierung, Softwareentwicklung und Algorithmen helfen. Gerne beantworte ich Ihre Programmierfragen! 🚀';
      } else {
        return 'I am C-Studio AI Assistant. I can only assist with C programming, software development, and algorithms. Feel free to ask any coding questions! 🚀';
      }
    }

    final sys = getEffectiveSystemInstruction(customInstruction: systemInstruction);

    // Hızlı C derleyicisi sözdizimi kontrolü (varsa)
    String? compilerCheck;
    if (currentCode != null && currentCode.trim().isNotEmpty) {
      try {
        compilerCheck = await _compilerService.checkSyntax(currentCode);
      } catch (_) {}
    }

    // Konuşma geçmişi dönüştür
    final historyList = <Map<String, String>>[];
    if (history != null && history.isNotEmpty) {
      final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final m in recent) {
        historyList.add({
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        });
      }
    }

    // 1. Google Gemini API (Bulut - Hızlı & Ücretsiz)
    if (isGemini) {
      return await _sendGeminiPrompt(
        prompt: prompt,
        history: historyList,
        currentCode: currentCode,
        compilerOutput: compilerCheck,
        systemInstruction: sys,
      );
    }

    // 2. Android / Mobil Yapay Zeka Desteği
    if (!Platform.isWindows) {
      return await _generateMobileAiResponse(
        prompt: prompt,
        currentCode: currentCode,
        compilerOutput: compilerCheck,
      );
    }

    // 3. Windows Yerel Çevrimdışı Yapay Zeka Modu (Qwen)
    if (!isLocalAiAvailable) {
      throw Exception(
        isTurkish
            ? 'Dahili Yerel Yapay Zeka dosyaları bulunamadı!\n'
                'Lütfen C-Studio klasöründe ai/runtime/llama-server.exe ve ai/models/*.gguf dosyalarının olduğundan emin olun veya Ayarlar > Yapay Zeka sekmesinden Google Gemini API modunu seçin.'
            : (isGerman
                ? 'Lokale KI-Dateien nicht gefunden! Wählen Sie den Gemini API-Modus in den Einstellungen.'
                : 'Local AI engine files not found! Select Gemini API in Settings or download local model.'),
      );
    }

    final compInfo = compilerCheck;

    return await _localAiService.sendPrompt(
      prompt: prompt,
      history: historyList,
      currentCode: currentCode,
      compilerOutput: compInfo,
      systemInstruction: sys,
    );
  }

  Future<String> _sendGeminiPrompt({
    required String prompt,
    List<Map<String, String>>? history,
    String? currentCode,
    String? compilerOutput,
    String? systemInstruction,
  }) async {
    if (_geminiApiKey.trim().isEmpty) {
      throw Exception(
        isTurkish
            ? 'Google Gemini API Anahtarı eksik!\nLütfen Ayarlar > Yapay Zeka sekmesinden API anahtarınızı girin.'
            : (isGerman
                ? 'Google Gemini API-Schlüssel fehlt!\nBitte geben Sie Ihren Schlüssel in Einstellungen > KI ein.'
                : 'Google Gemini API key missing!\nPlease enter your key in Settings > AI tab.'),
      );
    }

    final sys = systemInstruction ?? getEffectiveSystemInstruction();
    final buffer = StringBuffer();
    if (currentCode != null && currentCode.trim().isNotEmpty) {
      buffer.writeln('Editördeki C Kodu:\n```c\n$currentCode\n```\n');
    }
    if (compilerOutput != null && compilerOutput.trim().isNotEmpty) {
      buffer.writeln('Derleyici Çıktısı:\n$compilerOutput\n');
    }
    buffer.writeln('Kullanıcının Sorusu / İstemi:\n$prompt\n');
    buffer.writeln('Lütfen bu soruya detaylı, öğretici ve açıklayıcı bir yanıt ver.');

    final userContent = buffer.toString().trim();
    final contents = <Map<String, dynamic>>[];

    if (history != null && history.isNotEmpty) {
      final recent = history.length > 8 ? history.sublist(history.length - 8) : history;
      for (final m in recent) {
        final r = (m['role'] == 'user') ? 'user' : 'model';
        final c = m['content'] ?? '';
        if (c.trim().isNotEmpty) {
          contents.add({
            'role': r,
            'parts': [
              {'text': c}
            ]
          });
        }
      }
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userContent}
      ]
    });

    final payload = {
      'systemInstruction': {
        'parts': [
          {'text': sys}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 2048,
        'topP': 0.9,
      }
    };

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey',
    );

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 35);

    try {
      final req = await client.postUrl(url);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.add(utf8.encode(jsonEncode(payload)));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode != 200) {
        try {
          final errJson = jsonDecode(body);
          final msg = errJson['error']?['message'] ?? body;
          throw Exception('Gemini API Hatası (${res.statusCode}): $msg');
        } catch (_) {
          throw Exception('Gemini API Hatası (${res.statusCode}): $body');
        }
      }

      final data = jsonDecode(body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception(isTurkish ? 'Gemini yanıt üretemedi.' : 'Gemini generated no response.');
      }

      final parts = candidates.first['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception(isTurkish ? 'Gemini boş içerik döndürdü.' : 'Gemini returned empty content.');
      }

      final text = parts.map((p) => p['text'] ?? '').join();
      return text.trim();
    } finally {
      client.close();
    }
  }

  Future<String> _generateMobileAiResponse({
    required String prompt,
    String? currentCode,
    String? compilerOutput,
  }) async {
    final lower = prompt.toLowerCase();

    // 1. Derleme hatası varsa veya soruluyorsa
    if (compilerOutput != null && compilerOutput.isNotEmpty) {
      final errors = SmartErrorAdvisor.parseErrors(compilerOutput, 'main.c');
      if (errors.isNotEmpty) {
        final err = errors.first;
        final diagnosis = err.diagnosis;
        String fixedCode = currentCode ?? '';
        if (currentCode != null) {
          fixedCode = SmartErrorAdvisor.applyAutoFix(currentCode, err);
        }
        if (isTurkish) {
          final expl = diagnosis?.getDisplayExplanation('tr') ?? err.message;
          final fix = diagnosis?.getDisplayHowToFix('tr') ?? "İlgili sözdizimi kuralı düzeltildi.";
          return '🔍 **Hata Tespiti ve Çözümü:**\n\n'
              '• **Nerede:** Satır ${err.line}, Sütun ${err.column} (${err.fileName})\n'
              '• **Neden:** $expl\n'
              '• **Nasıl Düzeltildiği:** $fix\n\n'
              'Düzeltilmiş tam ve çalışan C kodu:\n\n'
              '```c\n$fixedCode\n```';
        } else if (isGerman) {
          final expl = diagnosis?.getDisplayExplanation('de') ?? err.message;
          final fix = diagnosis?.getDisplayHowToFix('de') ?? "Syntaxregel korrigiert.";
          return '🔍 **Fehleranalyse & Behebung:**\n\n'
              '• **Wo:** Zeile ${err.line}, Spalte ${err.column} (${err.fileName})\n'
              '• **Warum:** $expl\n'
              '• **Wie behoben:** $fix\n\n'
              'Vollständiger korrigierter C-Code:\n\n'
              '```c\n$fixedCode\n```';
        } else {
          final expl = diagnosis?.getDisplayExplanation('en') ?? err.message;
          final fix = diagnosis?.getDisplayHowToFix('en') ?? "Syntax rule corrected.";
          return '🔍 **Error Diagnosis & Fix:**\n\n'
              '• **Where:** Line ${err.line}, Column ${err.column} (${err.fileName})\n'
              '• **Why:** $expl\n'
              '• **How It Was Fixed:** $fix\n\n'
              'Fixed working C code:\n\n'
              '```c\n$fixedCode\n```';
        }
      }
    }

    // 2. Pointer / İşaretçi Soruları
    if (lower.contains('pointer') || lower.contains('işaretçi') || lower.contains('isaretci') || lower.contains('zeiger')) {
      if (isTurkish) {
        return '💡 **C Dilinde Pointer (İşaretçiler):**\n\n'
            'Pointer, bellekteki bir değişkenin adresini (referansını) tutan özel bir değişkendir.\n\n'
            '• `&` operatörü: Bir değişkenin bellek adresini verir (Örn: `&sayi`).\n'
            '• `*` operatörü: Tanımlarken işaretçi belirtir, kullanımda ise o adresteki değere erişir (dereference).\n\n'
            '```c\n#include <stdio.h>\n\nint main() {\n    int sayi = 42;\n    int *ptr = &sayi; // ptr, sayi degiskeninin adresini tutar\n\n    printf("Deger: %d\\n", sayi);\n    printf("Adres: %p\\n", (void*)ptr);\n    printf("Pointer uzerinden deger: %d\\n", *ptr);\n\n    *ptr = 100; // Pointer uzerinden degeri degistir\n    printf("Guncel Deger: %d\\n", sayi);\n\n    return 0;\n}\n```';
      } else if (isGerman) {
        return '💡 **Zeiger (Pointers) in C:**\n\n'
            'Ein Zeiger speichert die Speicheradresse einer Variablen.\n\n'
            '• `&`: Adress-Operator (liefert die Adresse).\n'
            '• `*`: Dereferenzierungs-Operator (greift auf den Wert an der Adresse zu).\n\n'
            '```c\n#include <stdio.h>\n\nint main() {\n    int zahl = 42;\n    int *ptr = &zahl;\n\n    printf("Wert: %d\\n", zahl);\n    printf("Adresse: %p\\n", (void*)ptr);\n    printf("Wert via Zeiger: %d\\n", *ptr);\n\n    *ptr = 100;\n    printf("Neuer Wert: %d\\n", zahl);\n    return 0;\n}\n```';
      } else {
        return '💡 **Pointers in C:**\n\n'
            'A pointer is a variable that stores the memory address of another variable.\n\n'
            '• `&`: Address-of operator (returns address).\n'
            '• `*`: Dereference operator (accesses value at address).\n\n'
            '```c\n#include <stdio.h>\n\nint main() {\n    int num = 42;\n    int *ptr = &num;\n\n    printf("Value: %d\\n", num);\n    printf("Address: %p\\n", (void*)ptr);\n    printf("Value via pointer: %d\\n", *ptr);\n\n    *ptr = 100;\n    printf("Updated value: %d\\n", num);\n    return 0;\n}\n```';
      }
    }

    // 3. Döngü / Loop Soruları
    if (lower.contains('döngü') || lower.contains('dongu') || lower.contains('loop') || lower.contains('schleife') || lower.contains('for') || lower.contains('while')) {
      if (isTurkish) {
        return '🔄 **C Dilinde Döngüler (Loops):**\n\n'
            'C dilinde üç temel döngü vardır: `for`, `while` ve `do-while`.\n\n'
            '```c\n#include <stdio.h>\n\nint main() {\n    // 1. For dongusu\n    printf("--- For Dongusu ---\\n");\n    for (int i = 1; i <= 5; i++) {\n        printf("%d ", i);\n    }\n    printf("\\n\\n");\n\n    // 2. While dongusu\n    printf("--- While Dongusu ---\\n");\n    int j = 1;\n    while (j <= 5) {\n        printf("%d ", j);\n        j++;\n    }\n    printf("\\n");\n\n    return 0;\n}\n```';
      } else {
        return '🔄 **Loops in C:**\n\n'
            'C provides three primary loops: `for`, `while`, and `do-while`.\n\n'
            '```c\n#include <stdio.h>\n\nint main() {\n    // For loop\n    printf("For loop: ");\n    for (int i = 1; i <= 5; i++) {\n        printf("%d ", i);\n    }\n    printf("\\n");\n    return 0;\n}\n```';
      }
    }

    // 4. Genel C Kodlama / Geliştirme Yanıtı
    if (currentCode != null && currentCode.trim().isNotEmpty) {
      if (isTurkish) {
        return '🚀 **C-Studio Akıllı Kod Asistanı:**\n\n'
            'İsteğinizi inceledim. Kodunuzu geliştirmek veya çalıştırmak için araç çubuğundaki **Derle & Çalıştır (F5)** butonunu kullanabilirsiniz.\n\n'
            'İşte önerilen çalışan C kodu:\n\n'
            '```c\n$currentCode\n```';
      } else {
        return '🚀 **C-Studio Smart Assistant:**\n\n'
            'Here is the current working C code for your request. You can press **Build & Run (F5)** to compile and execute:\n\n'
            '```c\n$currentCode\n```';
      }
    }

    if (isTurkish) {
      return '🚀 **C-Studio Akıllı Kod Asistanı:**\n\n'
          'C programlama ile ilgili sorularınızı sorabilir, koddaki hataların çözümlerini öğrenebilir veya yeni algoritmalar isteyebilirsiniz. Başlamak için editöre kodunuzu yazın ve F5 ile derleyin!';
    } else {
      return '🚀 **C-Studio Smart Assistant:**\n\n'
          'Ask me any C programming question, debug code errors, or request algorithms. Write your code in the editor and press F5 to compile!';
    }
  }

  Future<String> explainAndFixError({
    required String code,
    required CompilerError error,
  }) async {
    final prompt = isTurkish
        ? 'Aşağıdaki C kodunda derleyici şu hatayı verdi:\n'
            'Dosya: ${error.fileName}, Satır: ${error.line}, Sütun: ${error.column}\n'
            'Hata Mesajı: ${error.message}\n'
            'Ham Derleyici Çıktısı: ${error.rawLine}\n\n'
            'Lütfen bu hatayı analiz et:\n'
            '1. Bu hata neden kaynaklandı? (Sade ve anlaşılır şekilde açıkla)\n'
            '2. Hatayı düzeltmek için ne yapılmalı?\n'
            '3. Hatanın düzeltilmiş tam halini ```c ve ``` blokları arasında göster.'
        : (isGerman
            ? 'Im folgenden C-Code hat der Compiler diesen Fehler gemeldet:\n'
                'Datei: ${error.fileName}, Zeile: ${error.line}, Spalte: ${error.column}\n'
                'Fehlermeldung: ${error.message}\n'
                'Compiler-Ausgabe: ${error.rawLine}\n\n'
                'Bitte analysiere diesen Fehler:\n'
                '1. Warum ist dieser Fehler aufgetreten? (Einfach und klar erklären)\n'
                '2. Wie wird der Fehler behoben?\n'
                '3. Zeige den vollstaendigen korrigierten C-Code in ```c und ``` Bloecken.'
            : 'In the following C code, the compiler reported this error:\n'
                'File: ${error.fileName}, Line: ${error.line}, Column: ${error.column}\n'
                'Error Message: ${error.message}\n'
                'Raw Compiler Output: ${error.rawLine}\n\n'
                'Please analyze this error:\n'
                '1. Why did this error occur? (Explain simply and clearly)\n'
                '2. How to fix it?\n'
                '3. Show the complete corrected code inside ```c and ``` blocks.');

    return sendPrompt(prompt: prompt, currentCode: code);
  }
}
