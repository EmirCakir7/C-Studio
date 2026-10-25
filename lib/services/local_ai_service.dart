import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/compiler_error.dart';

enum LocalAiState {
  stopped,
  starting,
  running,
  error,
}

class LocalAiService extends ChangeNotifier {
  static final LocalAiService _instance = LocalAiService._internal();
  factory LocalAiService() => _instance;
  LocalAiService._internal();

  Process? _serverProcess;
  int _port = 8089;
  LocalAiState _state = LocalAiState.stopped;
  String _statusMessage = 'Yapay zeka kapalı';
  String? _lastError;
  String? _activeModelPath;
  String? _serverExePath;
  DateTime? _startingStartTime;

  LocalAiState get state => _state;
  bool get isRunning => _state == LocalAiState.running && _serverProcess != null;
  bool get isStarting => _state == LocalAiState.starting;
  bool get isStopped => _state == LocalAiState.stopped;
  bool get hasError => _state == LocalAiState.error;
  String get statusMessage => _statusMessage;
  String? get lastError => _lastError;
  int get port => _port;

  int get startupElapsedSeconds => _startingStartTime != null
      ? DateTime.now().difference(_startingStartTime!).inSeconds
      : 0;

  String? get activeModelName => _activeModelPath != null ? p.basename(_activeModelPath!) : null;

  String get activeModelDisplayName {
    if (_activeModelPath != null) {
      return getModelDisplayName(_activeModelPath!);
    }
    final models = findAvailableModels();
    if (models.isNotEmpty) {
      return getModelDisplayName(models.first.path);
    }
    return 'Qwen 2.5 Coder';
  }

  /// Model dosya adından kullanıcı dostu etiket üretir
  static String getModelDisplayName(String? fileNameOrPath) {
    if (fileNameOrPath == null) return 'Qwen 2.5 Coder';
    final name = p.basename(fileNameOrPath).toLowerCase();
    if (name.contains('7b')) return 'Qwen 2.5 Coder 7B';
    if (name.contains('3b')) return 'Qwen 2.5 Coder 3B';
    if (name.contains('1.5b')) return 'Qwen 2.5 Coder 1.5B';
    if (name.contains('deepseek')) return 'DeepSeek Coder';
    return p.basenameWithoutExtension(fileNameOrPath);
  }

  /// llama-server.exe yolunu bulur
  String? findServerExe() {
    if (_serverExePath != null && File(_serverExePath!).existsSync()) {
      return _serverExePath;
    }

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
    final candidates = [
      p.join(exeDir, 'ai', 'runtime', 'llama-server.exe'),
      p.join(exeDir, 'ai', 'llama-server.exe'),
      p.join(Directory.current.path, 'ai', 'runtime', 'llama-server.exe'),
      p.join(Directory.current.path, 'ai', 'llama-server.exe'),
      p.join(userProfile, 'Desktop', 'C-Studio-7B', 'ai', 'runtime', 'llama-server.exe'),
      p.join(userProfile, 'Desktop', 'C-Studio', 'ai', 'runtime', 'llama-server.exe'),
      p.join(userProfile, 'OneDrive', 'Masaüstü', 'C-Studio-7B', 'ai', 'runtime', 'llama-server.exe'),
      p.join(userProfile, 'OneDrive', 'Masaüstü', 'C-Studio', 'ai', 'runtime', 'llama-server.exe'),
    ];

    for (final cand in candidates) {
      if (File(cand).existsSync()) {
        _serverExePath = cand;
        return cand;
      }
    }
    return null;
  }

  /// Mevcut .gguf modellerini listeler (7B > 3B > 1.5B öncelikli)
  List<File> findAvailableModels() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
    final searchDirs = [
      p.join(exeDir, 'ai', 'models'),
      p.join(exeDir, 'ai'),
      p.join(Directory.current.path, 'ai', 'models'),
      p.join(Directory.current.path, 'ai'),
      p.join(userProfile, 'Desktop', 'C-Studio-7B', 'ai', 'models'),
      p.join(userProfile, 'Desktop', 'C-Studio', 'ai', 'models'),
      p.join(userProfile, 'OneDrive', 'Masaüstü', 'C-Studio-7B', 'ai', 'models'),
      p.join(userProfile, 'OneDrive', 'Masaüstü', 'C-Studio', 'ai', 'models'),
    ];

    final found = <String, File>{};
    for (final dirPath in searchDirs) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        try {
          for (final entity in dir.listSync()) {
            if (entity is File && entity.path.toLowerCase().endsWith('.gguf')) {
              // Yarıda kalmış .part dosyalarını atla
              if (!entity.path.endsWith('.part')) {
                found[p.basename(entity.path)] = entity;
              }
            }
          }
        } catch (_) {}
      }
    }

    final list = found.values.toList();
    // Sıralama: 7B > 3B > 1.5B > diğerleri
    list.sort((a, b) {
      final na = p.basename(a.path).toLowerCase();
      final nb = p.basename(b.path).toLowerCase();
      int scoreA = na.contains('7b') ? 3 : (na.contains('3b') ? 2 : (na.contains('1.5b') ? 1 : 0));
      int scoreB = nb.contains('7b') ? 3 : (nb.contains('3b') ? 2 : (nb.contains('1.5b') ? 1 : 0));
      return scoreB.compareTo(scoreA);
    });

    return list;
  }

  bool isLocalAiSupported() {
    final server = findServerExe();
    final models = findAvailableModels();
    return server != null && models.isNotEmpty;
  }

  /// Yerel AI sunucusunu arka planda başlatır
  Future<bool> startServer({String? specificModelPath}) async {
    if (isRunning) return true;
    if (_state == LocalAiState.starting) {
      while (_state == LocalAiState.starting) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return isRunning;
    }

    _state = LocalAiState.starting;
    _statusMessage = 'Yapay zeka sunucusu hazırlanıyor...';
    _lastError = null;
    _startingStartTime = DateTime.now();
    notifyListeners();

    Timer? elapsedTimer;
    elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == LocalAiState.starting) {
        final sec = DateTime.now().difference(_startingStartTime!).inSeconds;
        _statusMessage = 'Model belleğe alınıyor... ($sec sn)';
        notifyListeners();
      } else {
        timer.cancel();
      }
    });

    try {
      final serverExe = findServerExe();
      if (serverExe == null) {
        throw Exception('llama-server.exe bulunamadı!');
      }

      String? modelPath = specificModelPath;
      if (modelPath == null || !File(modelPath).existsSync()) {
        final models = findAvailableModels();
        if (models.isEmpty) {
          throw Exception('GGUF model dosyası bulunamadı!');
        }
        modelPath = models.first.path;
      }

      _activeModelPath = modelPath;
      final modelDisp = getModelDisplayName(modelPath);
      _statusMessage = '$modelDisp belleğe yükleniyor...';
      notifyListeners();

      // Port çakışmasını önlemek için 8089'dan başlayarak müsait ilk portu bul
      _port = await _findAvailablePort(8089);

      final serverDir = File(serverExe).parent.path;
      final args = [
        '-m', modelPath,
        '--port', _port.toString(),
        '--host', '127.0.0.1',
        '-c', '2048', // 2048 context window (öğrenci kodları için ideal)
        '-t', (Platform.numberOfProcessors > 4 ? 4 : Platform.numberOfProcessors).toString(),
      ];

      _serverProcess = await Process.start(
        serverExe,
        args,
        workingDirectory: serverDir,
        mode: ProcessStartMode.normal,
      );

      _serverProcess!.stdout.transform(utf8.decoder).listen((data) {
        // Log istenirse burada dinlenebilir
      });

      _serverProcess!.stderr.transform(utf8.decoder).listen((data) {
        // Log istenirse burada dinlenebilir
      });

      _serverProcess!.exitCode.then((code) {
        if (_serverProcess != null) {
          _serverProcess = null;
          _state = LocalAiState.stopped;
          _statusMessage = 'Sunucu durduruldu';
          notifyListeners();
        }
      });

      // 7B model yüklenmesi disk ve donanıma göre 30-50 saniye sürebilir
      final ready = await _waitForReady(const Duration(seconds: 50));
      elapsedTimer.cancel();

      if (!ready) {
        stopServer();
        throw Exception('Yerel yapay zeka sunucusu zamanında yanıt vermedi.');
      }

      _state = LocalAiState.running;
      _statusMessage = '$modelDisp hazır';
      notifyListeners();
      return true;
    } catch (e) {
      elapsedTimer.cancel();
      if (_serverProcess != null) {
        try {
          _serverProcess!.kill();
        } catch (_) {}
        _serverProcess = null;
      }
      _state = LocalAiState.error;
      _lastError = e.toString();
      _statusMessage = 'Başlatma hatası: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _waitForReady(Duration timeout) async {
    final end = DateTime.now().add(timeout);
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 600);

    while (DateTime.now().isBefore(end)) {
      if (_serverProcess == null) {
        client.close();
        return false;
      }
      try {
        final req = await client.getUrl(Uri.parse('http://127.0.0.1:$_port/health'));
        final res = await req.close();
        if (res.statusCode == 200) {
          client.close();
          return true;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 350));
    }
    client.close();
    return false;
  }

  Future<int> _findAvailablePort(int startingPort) async {
    for (int port = startingPort; port < startingPort + 50; port++) {
      try {
        final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
        await serverSocket.close();
        return port;
      } catch (_) {
        // Port kullanımda, bir sonrakini dene
      }
    }
    return startingPort;
  }

  void stopServer() {
    if (_serverProcess != null) {
      try {
        _serverProcess!.kill();
      } catch (_) {}
      _serverProcess = null;
    }
    _state = LocalAiState.stopped;
    _statusMessage = 'Yapay zeka durduruldu (RAM serbest bırakıldı)';
    notifyListeners();
  }

  String _cleanAiResponse(String rawText, String userPrompt) {
    if (rawText.trim().isEmpty) return '';

    String text = rawText.trim();
    final pTrim = userPrompt.trim();
    if (pTrim.isNotEmpty && text.endsWith(pTrim)) {
      text = text.substring(0, text.length - pTrim.length).trim();
    }

    // Tekrarlayan satır döngülerini temizle
    final lines = text.split('\n');
    final cleanLines = <String>[];
    String? lastLine;
    int repeatCount = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && trimmed == lastLine) {
        repeatCount++;
        if (repeatCount <= 2) {
          cleanLines.add(line);
        }
      } else {
        lastLine = trimmed.isNotEmpty ? trimmed : null;
        repeatCount = 1;
        cleanLines.add(line);
      }
    }

    return cleanLines.join('\n').trim();
  }

  /// Yerel modele soru gönderir (OpenAI uyumlu endpoint)
  Future<String> sendPrompt({
    required String prompt,
    List<Map<String, String>>? history,
    String? currentCode,
    String? compilerOutput,
    String? systemInstruction,
  }) async {
    if (!isRunning) {
      final started = await startServer();
      if (!started) {
        throw Exception(_lastError ?? 'Yerel yapay zeka sunucusu başlatılamadı.');
      }
    }

    final sys = systemInstruction ??
        'Sen C-Studio Akıllı C Programlama Asistanısın. '
        'Kullanıcıya her zaman samimi, öğretici, net ve detaylı açıklamalar yap. '
        'Kodun mantığını, hataların nedenini ve C kurallarını detaylıca anlat. '
        'Gerekli yerlerde düzeltilmiş C kodunu ```c ... ``` blokları içinde sun.';

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

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': sys},
    ];

    if (history != null && history.isNotEmpty) {
      final recent = history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final m in recent) {
        final r = m['role'] ?? 'user';
        final c = m['content'] ?? '';
        if (c.trim().isNotEmpty) {
          messages.add({'role': r, 'content': c});
        }
      }
    }

    messages.add({'role': 'user', 'content': userContent});

    final payload = {
      'messages': messages,
      'temperature': 0.4,
      'top_p': 0.9,
      'repeat_penalty': 1.15,
      'repeat_last_n': 256,
      'frequency_penalty': 0.3,
      'presence_penalty': 0.3,
      'max_tokens': 1024,
      'stop': ['<|im_end|>', '<|endoftext|>', '<|im_start|>'],
      'stream': false,
    };

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 45);

    try {
      final req = await client.postUrl(Uri.parse('http://127.0.0.1:$_port/v1/chat/completions'));
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.add(utf8.encode(jsonEncode(payload)));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode != 200) {
        throw Exception('Yerel AI Hatası (${res.statusCode}): $body');
      }

      final data = jsonDecode(body);
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Modelden boş yanıt alındı.');
      }

      final msg = choices.first['message']?['content'] as String?;
      return _cleanAiResponse(msg ?? '', prompt);
    } finally {
      client.close();
    }
  }

  Future<String> explainAndFixError({
    required String code,
    required CompilerError error,
  }) async {
    final prompt = 'Aşağıdaki C kodunda derleyici şu hatayı verdi:\n'
        'Dosya: ${error.fileName}, Satır: ${error.line}, Sütun: ${error.column}\n'
        'Hata Mesajı: ${error.message}\n'
        'Derleyici Çıktısı: ${error.rawLine}\n\n'
        'Lütfen bu hatayı analiz et, nedenini açıkla ve düzeltilmiş çalışan tam C kodunu ```c ve ``` blokları arasında ver.';

    return sendPrompt(prompt: prompt, currentCode: code, compilerOutput: error.rawLine);
  }
}
