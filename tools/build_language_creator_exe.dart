import 'dart:convert';
import 'dart:io';

void main() async {
  print('Building C-Studio Language Creator standalone executable...');

  final htmlFile = File('C-Studio_Language_Pack_Creator.html');
  if (!htmlFile.existsSync()) {
    print('Error: C-Studio_Language_Pack_Creator.html not found!');
    exit(1);
  }

  var htmlContent = htmlFile.readAsStringSync();

  // Enhance HTML with direct server endpoints (Apply to C-Studio, Save Locally)
  final enhancedScript = '''
    // Native .exe Server integration
    async function saveLocallyDirectly(pack, filename) {
      try {
        const res = await fetch('/api/save', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ filename: filename, content: JSON.stringify(pack, null, 2) })
        });
        if (res.ok) {
          const data = await res.json();
          if (data.success) {
            showToast('✔ Saved locally: ' + filename);
          }
        }
      } catch (_) {}
    }

    async function applyDirectlyToCStudio() {
      const langName = document.getElementById('lang-name-input').value.trim() || 'Custom Language';
      const langCode = document.getElementById('lang-code-input').value.trim() || 'custom';

      const translationMap = {};
      CATALOG.forEach(cat => {
        cat.items.forEach(item => {
          const val = userTranslations[item.en] ?? userTranslations[item.key] ?? '';
          if (val.trim()) {
            translationMap[item.en] = val.trim();
            translationMap[item.key] = val.trim();
          }
        });
      });

      const pack = {
        language_name: langName,
        language_code: langCode,
        created_by: "C-Studio Language Creator",
        created_at: new Date().toISOString(),
        translations: translationMap
      };

      try {
        const res = await fetch('/api/apply-direct', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(pack)
        });
        if (res.ok) {
          const data = await res.json();
          if (data.success) {
            showToast('⚡ Applied "' + langName + '" directly to C-Studio!');
            return;
          }
        }
      } catch (_) {}

      // Fallback: export pack
      exportLanguagePack();
    }

    function closeAppWindow() {
      fetch('/api/exit').catch(() => {});
      window.close();
    }
  ''';

  // Inject enhancedScript before </script>
  htmlContent = htmlContent.replaceFirst('window.onload = init;', '$enhancedScript\n    window.onload = init;');

  // Inject "Apply Directly to C-Studio" button in header
  final newButtons = '''
      <button class="btn btn-accent" onclick="applyDirectlyToCStudio()">⚡ Apply to C-Studio</button>
      <button class="btn btn-primary" onclick="exportLanguagePack()">💾 Export Pack (.cstudio-lang)</button>
  ''';
  htmlContent = htmlContent.replaceFirst(
    '<button class="btn btn-primary" onclick="exportLanguagePack()">💾 Export Pack (.cstudio-lang)</button>',
    newButtons
  );

  // Also update exportLanguagePack to trigger saveLocallyDirectly
  htmlContent = htmlContent.replaceFirst(
    'showToast(`✔ "\${filename}" exported successfully!`);',
    'saveLocallyDirectly(pack, filename);\n      showToast(`✔ "\${filename}" exported successfully!`);'
  );

  // Write updated HTML to file
  htmlFile.writeAsStringSync(htmlContent);
  File('tools/language_translator/C-Studio_Language_Pack_Creator.html').writeAsStringSync(htmlContent);

  // Encode HTML to base64 so there are zero string escaping issues in Dart code
  final bytes = utf8.encode(htmlContent);
  final base64Html = base64Encode(bytes);

  final dartSource = '''// C-Studio Language Creator - Standalone Executable
import 'dart:convert';
import 'dart:io';

const String _base64Html = '$base64Html';

void main(List<String> args) async {
  print('');
  print('======================================================================');
  print('  🌐 C-Studio Language Pack Creator (Portable Windows Edition)');
  print('======================================================================');

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  final url = 'http://127.0.0.1:\$port';

  print('  • Application Server running at: \$url');
  print('  • Opening window...');
  print('  • Press Ctrl+C in this console to terminate.');
  print('======================================================================');
  print('');

  final decodedHtml = utf8.decode(base64Decode(_base64Html));

  server.listen((HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    if (path == '/' || path == '/index.html') {
      request.response.headers.contentType = ContentType.html;
      request.response.write(decodedHtml);
      await request.response.close();
      return;
    }

    if (path == '/api/save' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final data = jsonDecode(body);
        final filename = data['filename'] ?? 'custom.cstudio-lang';
        final content = data['content'] ?? '';

        final file = File(filename);
        await file.writeAsString(content);

        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'success': true,
          'path': file.absolute.path,
          'message': 'File saved successfully to \${file.absolute.path}'
        }));
      } catch (e) {
        request.response.statusCode = 500;
        request.response.write(jsonEncode({'success': false, 'error': e.toString()}));
      }
      await request.response.close();
      return;
    }

    if (path == '/api/apply-direct' && request.method == 'POST') {
      try {
        final body = await utf8.decodeStream(request);
        final data = jsonDecode(body);
        final name = data['language_name'] ?? 'Custom';
        final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\\\';
        final configDir = Directory('\$userProfile\\\\.cstudio');
        if (!configDir.existsSync()) {
          configDir.createSync(recursive: true);
        }

        final customFile = File('\${configDir.path}\\\\custom_language.json');
        await customFile.writeAsString(jsonEncode(data));

        final settingsFile = File('\${configDir.path}\\\\app_settings.json');
        Map<String, dynamic> settings = {};
        if (settingsFile.existsSync()) {
          try {
            settings = jsonDecode(await settingsFile.readAsString());
          } catch (_) {}
        }
        settings['ui_language'] = 'custom';
        await settingsFile.writeAsString(jsonEncode(settings));

        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'success': true,
          'message': 'Applied "\$name" directly to C-Studio!'
        }));
      } catch (e) {
        request.response.statusCode = 500;
        request.response.write(jsonEncode({'success': false, 'error': e.toString()}));
      }
      await request.response.close();
      return;
    }

    if (path == '/api/exit') {
      request.response.write('OK');
      await request.response.close();
      exit(0);
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Not Found');
    await request.response.close();
  });

  _launchBrowser(url);
}

void _launchBrowser(String url) async {
  final candidates = [
    r'C:\\Program Files (x86)\\Microsoft\\EdgeCore\\Optimized\\msedge.exe',
    r'C:\\Program Files (x86)\\Microsoft\\EdgeCore\\155.0.4283.45\\msedge.exe',
    r'C:\\Program Files (x86)\\Microsoft\\EdgeCore\\154.0.4258.62\\msedge.exe',
    r'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    r'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    r'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  ];

  for (final c in candidates) {
    if (File(c).existsSync()) {
      try {
        await Process.start(c, ['--app=\$url', '--window-size=1240,840']);
        return;
      } catch (_) {}
    }
  }

  try {
    await Process.start('explorer.exe', [url]);
  } catch (_) {
    await Process.start('cmd.exe', ['/c', 'start', url]);
  }
}
''';

  final mainDart = File('tools/language_creator/main.dart');
  mainDart.writeAsStringSync(dartSource);
  print('Generated tools/language_creator/main.dart');

  // Compile to EXE
  print('Compiling to C-Studio_Language_Creator.exe...');
  final result = await Process.run('dart', [
    'compile',
    'exe',
    'tools/language_creator/main.dart',
    '-o',
    'C-Studio_Language_Creator.exe'
  ]);

  if (result.exitCode != 0) {
    print('Compilation failed!');
    print(result.stdout);
    print(result.stderr);
    exit(1);
  }

  print('Compilation succeeded! Output: C-Studio_Language_Creator.exe');

  // Copy to tools/language_creator/ and tools/language_translator/
  final exe = File('C-Studio_Language_Creator.exe');
  if (exe.existsSync()) {
    exe.copySync('tools/language_creator/C-Studio_Language_Creator.exe');
    exe.copySync('tools/language_translator/C-Studio_Language_Creator.exe');
    print('Copied to tools/ directories. Size: \${(exe.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');
  }
}
