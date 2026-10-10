import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/compiler_error.dart';
import 'local_ai_service.dart';
import 'app_language_service.dart';
import 'compiler_service.dart';

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

  // Sağlayıcı: Her zaman Dahili Çevrimdışı ('local')
  String get provider => 'local';
  bool get isLocal => true;
  bool get isCloud => false;

  // Dil: 'tr' (Türkçe) veya 'en' (English) - AppLanguageService ile merkezi senkronize
  String get language => AppLanguageService().aiLanguage;
  bool get isTurkish => AppLanguageService().isAiTurkish;
  bool get isEnglish => AppLanguageService().isAiEnglish;

  String get apiKey => '';
  bool get hasApiKey => false;
  String get selectedCloudModel => '';

  String get selectedModel => _localAiService.activeModelName ?? 'qwen2.5-coder-1.5b';

  bool get isLocalAiAvailable => _localAiService.isLocalAiSupported();

  bool get isReady => isLocalAiAvailable;

  File _getConfigFile() {
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
    final configDir = Directory(p.join(userProfile, '.cstudio'));
    if (!configDir.existsSync()) {
      configDir.createSync(recursive: true);
    }
    return File(p.join(configDir.path, 'ai_config.json'));
  }

  void loadConfig() {
    try {
      final file = _getConfigFile();
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content);
        if (data is Map) {
          if (data.containsKey('language')) {
            final lang = data['language'] as String;
            AppLanguageService().setAiLanguage(lang);
          }
        }
      }
    } catch (_) {}
  }

  void saveConfig({String? provider, String? apiKey, String? cloudModel, String? language}) {
    if (language != null) AppLanguageService().setAiLanguage(language);

    try {
      final file = _getConfigFile();
      final data = {
        'provider': 'local',
        'language': AppLanguageService().aiLanguage,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      file.writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }

  void setProvider(String prov) {}

  void setLanguage(String lang) {
    AppLanguageService().setAiLanguage(lang);
    saveConfig(language: lang);
  }

  void saveApiKey(String key, {String? model}) {}

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
      return isTurkish
          ? 'Ben C-Studio Akıllı Kod Asistanıyım. Yalnızca C programlama dili, yazılım geliştirme ve algoritmalarla ilgili konularda yardımcı olabilirim. C kodunuz veya programlama sorularınızı yanıtlamaktan memnuniyet duyarım! 🚀'
          : 'I am C-Studio AI Assistant. I can only assist with C programming, software development, and algorithms. Feel free to ask any coding questions! 🚀';
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

    // 1. Yerel Çevrimdışı Yapay Zeka Modu
    if (!isLocalAiAvailable) {
      throw Exception(
        isTurkish
            ? 'Dahili Yerel Yapay Zeka dosyaları bulunamadı!\n'
                'Lütfen C-Studio klasöründe ai/runtime/llama-server.exe ve ai/models/*.gguf dosyalarının olduğundan emin olun.'
            : 'Local AI engine files not found!\n'
                'Please make sure ai/runtime/llama-server.exe and ai/models/*.gguf exist in the C-Studio directory.',
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
        : 'In the following C code, the compiler reported this error:\n'
            'File: ${error.fileName}, Line: ${error.line}, Column: ${error.column}\n'
            'Error Message: ${error.message}\n'
            'Raw Compiler Output: ${error.rawLine}\n\n'
            'Please analyze this error:\n'
            '1. Why did this error occur? (Explain simply and clearly)\n'
            '2. How to fix it?\n'
            '3. Show the complete corrected code inside ```c and ``` blocks.';

    return sendPrompt(prompt: prompt, currentCode: code);
  }
}
