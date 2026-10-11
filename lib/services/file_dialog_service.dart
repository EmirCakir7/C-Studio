import 'dart:io';

class FileDialogService {
  static Future<String?> pickCFile() async {
    if (!Platform.isWindows) return null;
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
      final result = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty && File(path).existsSync()) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> saveCFile({String defaultFileName = 'program.c'}) async {
    if (!Platform.isWindows) return null;
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
      final result = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> pickDirectory({String? title}) async {
    if (!Platform.isWindows) return null;
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
      final result = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty && Directory(path).existsSync()) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> pickCustomLanguageFile() async {
    if (!Platform.isWindows) return null;
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
      final result = await Process.run('powershell', ['-NoProfile', '-Command', psCommand]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty && File(path).existsSync()) {
          return path;
        }
      }
    } catch (_) {}
    return null;
  }
}
