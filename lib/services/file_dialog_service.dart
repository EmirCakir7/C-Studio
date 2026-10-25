import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class FileDialogService {
  static Future<String?> pickCFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['c', 'h', 'txt'],
      );
      if (result.isNotEmpty && result.first.path != null) {
        return result.first.path;
      }
    } catch (_) {}

    // Windows fallback
    if (Platform.isWindows) {
      try {
        const psCommand = '''
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.Filter = "C Kaynak Dosyalari (*.c;*.h)|*.c;*.h|Tum Dosyalar (*.*)|*.*"
\$dialog.Title = "C Dosyasi Ice Aktar / Ac"
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Output \$dialog.FileName
}
''';
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
        if (res.exitCode == 0) {
          final path = (res.stdout as String).trim();
          if (path.isNotEmpty && File(path).existsSync()) {
            return path;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> saveCFile({String defaultFileName = 'program.c', String content = ''}) async {
    try {
      final uri = await FilePicker.saveFile(
        fileName: defaultFileName,
        bytes: Uint8List.fromList(utf8.encode(content)),
        dialogTitle: 'Save C File / C Dosyası Kaydet',
        type: FileType.custom,
        allowedExtensions: ['c', 'h'],
      );
      if (uri != null) {
        try {
          return uri.toFilePath();
        } catch (_) {
          return uri.path;
        }
      }
    } catch (_) {}

    // Windows fallback
    if (Platform.isWindows) {
      try {
        final psCommand = '''
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
\$dialog = New-Object System.Windows.Forms.SaveFileDialog
\$dialog.Filter = "C Kaynak Dosyasi (*.c)|*.c|C Baslik Dosyasi (*.h)|*.h|Tum Dosyalar (*.*)|*.*"
\$dialog.FileName = "$defaultFileName"
\$dialog.Title = "C Dosyasini Disa Aktar / Kaydet"
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Output \$dialog.FileName
}
''';
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
        if (res.exitCode == 0) {
          final path = (res.stdout as String).trim();
          if (path.isNotEmpty) {
            return path;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> pickDirectory({String? title}) async {
    try {
      final result = await FilePicker.getDirectoryPath(
        dialogTitle: title ?? 'C Projesi Klasorunu Secin',
      );
      if (result != null && result.isNotEmpty && Directory(result).existsSync()) {
        return result;
      }
    } catch (_) {}

    // Windows fallback
    if (Platform.isWindows) {
      try {
        final desc = title ?? "C Projesi Klasorunu Secin";
        final psCommand = '''
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
\$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
\$dialog.Description = "$desc"
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Output \$dialog.SelectedPath
}
''';
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
        if (res.exitCode == 0) {
          final path = (res.stdout as String).trim();
          if (path.isNotEmpty && Directory(path).existsSync()) {
            return path;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> pickCustomLanguageFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cstudio-lang', 'json', 'txt'],
      );
      if (result.isNotEmpty && result.first.path != null) {
        return result.first.path;
      }
    } catch (_) {}

    // Windows fallback
    if (Platform.isWindows) {
      try {
        const psCommand = '''
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
\$dialog = New-Object System.Windows.Forms.OpenFileDialog
\$dialog.Filter = "C-Studio Language Pack (*.cstudio-lang;*.json)|*.cstudio-lang;*.json|All Files (*.*)|*.*"
\$dialog.Title = "Select Language Pack / Dil Paketi Secin"
if (\$dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Output \$dialog.FileName
}
''';
        final res = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
        if (res.exitCode == 0) {
          final path = (res.stdout as String).trim();
          if (path.isNotEmpty && File(path).existsSync()) {
            return path;
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
