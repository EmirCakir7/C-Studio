import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPathService {
  static String? _documentsPath;
  static String? _configPath;
  static String? _projectsPath;

  /// Uygulama başlarken asenkron olarak çağrılır
  static Future<void> init() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
      _documentsPath = p.join(userProfile, 'Documents');
      _configPath = p.join(userProfile, '.cstudio');
      _projectsPath = p.join(userProfile, 'Documents', 'CStudio_Projeleri');
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        _documentsPath = dir.path;
        _configPath = p.join(dir.path, '.cstudio');
        _projectsPath = p.join(dir.path, 'CStudio_Projeleri');
      } catch (_) {
        final tmp = Directory.systemTemp.path;
        _documentsPath = tmp;
        _configPath = p.join(tmp, '.cstudio');
        _projectsPath = p.join(tmp, 'CStudio_Projeleri');
      }
    }

    // Klasörleri garanti oluştur
    try {
      final pDir = Directory(_projectsPath!);
      if (!pDir.existsSync()) pDir.createSync(recursive: true);

      final cDir = Directory(_configPath!);
      if (!cDir.existsSync()) cDir.createSync(recursive: true);
    } catch (_) {}
  }

  static String get documentsDirectory {
    if (_documentsPath != null) return _documentsPath!;
    final userProfile = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
    return Platform.isWindows ? p.join(userProfile, 'Documents') : userProfile;
  }

  static String get configDirectory {
    if (_configPath != null) return _configPath!;
    final userProfile = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
    return p.join(userProfile, '.cstudio');
  }

  static String get projectsDirectory {
    if (_projectsPath != null) return _projectsPath!;
    final userProfile = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
    return Platform.isWindows
        ? p.join(userProfile, 'Documents', 'CStudio_Projeleri')
        : p.join(userProfile, 'CStudio_Projeleri');
  }

  static File get configFile => File(p.join(configDirectory, 'app_settings.json'));
  static File get customLanguageFile => File(p.join(configDirectory, 'custom_language.json'));
  static File get aiConfigFile => File(p.join(configDirectory, 'ai_config.json'));
}
