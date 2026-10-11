import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'local_ai_service.dart';

class AiModelDownloaderService extends ChangeNotifier {
  static final AiModelDownloaderService _instance = AiModelDownloaderService._internal();
  factory AiModelDownloaderService() => _instance;
  AiModelDownloaderService._internal();

  static const String modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q3_k_m.gguf';
  static const String modelFileName = 'qwen2.5-coder-1.5b-instruct-q3_k_m.gguf';

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  double _progress = 0.0;
  double get progress => _progress;

  int _downloadedBytes = 0;
  int get downloadedBytes => _downloadedBytes;

  int _totalBytes = 924456000; // ~881.6 MB fallback
  int get totalBytes => _totalBytes;

  String _speedText = '';
  String get speedText => _speedText;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HttpClient? _activeClient;
  IOSink? _activeSink;
  File? _currentPartFile;

  /// Modellerin kaydedileceği hedef dizini belirler
  Directory getTargetDirectory() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      Directory(p.join(exeDir, 'ai', 'models')),
      Directory(p.join(Directory.current.path, 'ai', 'models')),
    ];

    for (final d in candidates) {
      if (d.existsSync()) return d;
    }

    // Klasör mevcut değilse oluştur
    final defaultDir = Directory(p.join(Directory.current.path, 'ai', 'models'));
    try {
      defaultDir.createSync(recursive: true);
      return defaultDir;
    } catch (_) {
      return candidates.first;
    }
  }

  File getTargetModelFile() {
    final dir = getTargetDirectory();
    return File(p.join(dir.path, modelFileName));
  }

  bool isModelAlreadyDownloaded() {
    final target = getTargetModelFile();
    if (target.existsSync() && target.lengthSync() > 100 * 1024 * 1024) {
      return true;
    }
    final models = LocalAiService().findAvailableModels();
    return models.isNotEmpty;
  }

  Future<bool> startDownload() async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _isCompleted = false;
    _progress = 0.0;
    _downloadedBytes = 0;
    _errorMessage = null;
    _speedText = '';
    notifyListeners();

    final targetDir = getTargetDirectory();
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final targetFile = File(p.join(targetDir.path, modelFileName));
    final partFile = File(p.join(targetDir.path, '$modelFileName.part'));
    _currentPartFile = partFile;

    final client = HttpClient();
    _activeClient = client;

    try {
      Uri currentUri = Uri.parse(modelUrl);
      HttpClientResponse? response;

      // Hugging Face CDN yönlendirmelerini (redirects) takip et
      for (int i = 0; i < 6; i++) {
        final request = await client.getUrl(currentUri);
        request.headers.set(HttpHeaders.userAgentHeader, 'C-Studio-Model-Downloader/1.2');
        request.headers.set('Accept', '*/*');
        request.followRedirects = false;

        response = await request.close();

        if (response.isRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location != null) {
            currentUri = currentUri.resolve(location);
            continue;
          }
        }
        break;
      }

      if (response == null || response.statusCode != 200) {
        throw Exception('HTTP ${response?.statusCode ?? 500}: Model indirilemedi.');
      }

      if (response.contentLength > 0) {
        _totalBytes = response.contentLength;
      }

      final sink = partFile.openWrite();
      _activeSink = sink;

      int bytesSinceLastSample = 0;
      DateTime lastSampleTime = DateTime.now();

      await for (final chunk in response) {
        if (!_isDownloading) {
          // İptal edildi
          break;
        }

        sink.add(chunk);
        _downloadedBytes += chunk.length;
        bytesSinceLastSample += chunk.length;

        final now = DateTime.now();
        final elapsed = now.difference(lastSampleTime).inMilliseconds;

        if (elapsed >= 500) {
          final speedBytesPerSec = (bytesSinceLastSample / (elapsed / 1000));
          final speedMb = speedBytesPerSec / (1024 * 1024);
          _speedText = '${speedMb.toStringAsFixed(1)} MB/s';

          if (_totalBytes > 0) {
            _progress = (_downloadedBytes / _totalBytes).clamp(0.0, 1.0);
          }

          bytesSinceLastSample = 0;
          lastSampleTime = now;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();
      _activeSink = null;

      if (!_isDownloading) {
        if (partFile.existsSync()) partFile.deleteSync();
        return false;
      }

      // İndirme tamamlandı: .part dosyasını kalıcı dosyaya dönüştür
      if (targetFile.existsSync()) {
        targetFile.deleteSync();
      }
      partFile.renameSync(targetFile.path);

      _progress = 1.0;
      _isDownloading = false;
      _isCompleted = true;
      _speedText = '';

      // LocalAiService'i yeniden tetikle
      LocalAiService().findAvailableModels();

      notifyListeners();
      return true;
    } catch (e) {
      _isDownloading = false;
      _errorMessage = e.toString();
      _speedText = '';

      try {
        if (_activeSink != null) {
          await _activeSink!.close();
          _activeSink = null;
        }
        if (partFile.existsSync()) {
          partFile.deleteSync();
        }
      } catch (_) {}

      notifyListeners();
      return false;
    } finally {
      client.close();
      _activeClient = null;
    }
  }

  void cancelDownload() {
    if (!_isDownloading) return;

    _isDownloading = false;
    _speedText = '';
    _errorMessage = null;

    try {
      _activeClient?.close(force: true);
      _activeSink?.close();
      if (_currentPartFile != null && _currentPartFile!.existsSync()) {
        _currentPartFile!.deleteSync();
      }
    } catch (_) {}

    notifyListeners();
  }
}
