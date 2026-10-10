import 'dart:async';
import 'dart:io';

typedef ContentGetter = String Function();

class AutoSaveService {
  Timer? _timer;
  final Map<String, ContentGetter> _providers = {};
  final Set<String> _dirtyFiles = {};
  bool isEnabled = true;
  final Duration delay = const Duration(milliseconds: 1500);

  void Function(String path, DateTime time)? onFileSaved;
  void Function(bool hasChanges)? onStatusChanged;

  bool get hasPendingChanges => _dirtyFiles.isNotEmpty;

  void registerFileProvider(String filePath, ContentGetter getter) {
    _providers[filePath] = getter;
  }

  void unregisterFile(String filePath) {
    _providers.remove(filePath);
    _dirtyFiles.remove(filePath);
  }

  void markDirty(String filePath) {
    _dirtyFiles.add(filePath);
    onStatusChanged?.call(true);

    if (isEnabled) {
      _timer?.cancel();
      _timer = Timer(delay, () {
        saveAllDirty();
      });
    }
  }

  void markClean(String filePath) {
    _dirtyFiles.remove(filePath);
    onStatusChanged?.call(_dirtyFiles.isNotEmpty);
  }

  void saveAllDirty() {
    if (_dirtyFiles.isEmpty) return;

    final toSave = List<String>.from(_dirtyFiles);
    for (final path in toSave) {
      saveFile(path);
    }
    onStatusChanged?.call(false);
  }

  bool saveFile(String filePath) {
    final getter = _providers[filePath];
    if (getter == null) return false;

    try {
      final content = getter();
      final file = File(filePath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(content);
      _dirtyFiles.remove(filePath);
      onFileSaved?.call(filePath, DateTime.now());
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
