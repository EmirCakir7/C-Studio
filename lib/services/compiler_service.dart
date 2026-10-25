import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class CompilerInfo {
  final String name;
  final String exePath;
  final String type;
  final bool isPortable;

  CompilerInfo({
    required this.name,
    required this.exePath,
    required this.type,
    required this.isPortable,
  });

  @override
  String toString() => '$name ${isPortable ? "(Dahili Portatif)" : (exePath == "wandbox" ? "(Cloud)" : "(Sistem)")}';
}

class CompilationResult {
  final bool success;
  final int exitCode;
  final String output;
  final String outputExe;
  final String programOutput;

  CompilationResult({
    required this.success,
    required this.exitCode,
    required this.output,
    required this.outputExe,
    this.programOutput = '',
  });
}

class CompilerService {
  final List<CompilerInfo> availableCompilers = [];
  CompilerInfo? activeCompiler;
  String _lastProgramOutput = '';
  String get lastProgramOutput => _lastProgramOutput;

  CompilerService() {
    detectCompilers();
  }

  void detectCompilers() {
    availableCompilers.clear();

    if (Platform.isWindows) {
      // 1. Dahili Tiny C Compiler (tcc.exe)
      final scriptDir = File(Platform.resolvedExecutable).parent.path;
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
      final candidates = [
        p.join(scriptDir, 'compiler', 'tcc.exe'),
        p.join(Directory.current.path, 'compiler', 'tcc.exe'),
        p.join(userProfile, 'OneDrive', 'Masaüstü', 'C-Studio', 'compiler', 'tcc.exe'),
        p.join(userProfile, 'Desktop', 'C-Studio', 'compiler', 'tcc.exe'),
      ];

      for (final cand in candidates) {
        if (File(cand).existsSync()) {
          final tcc = CompilerInfo(
            name: 'Tiny C Compiler 64-bit',
            exePath: cand,
            type: 'TCC',
            isPortable: true,
          );
          availableCompilers.add(tcc);
          activeCompiler = tcc;
          break;
        }
      }

      // 2. Sistem GCC / Clang kontrolü
      final pathEnv = Platform.environment['PATH'] ?? '';
      final dirs = pathEnv.split(';');
      for (final dir in dirs) {
        final gccPath = p.join(dir.trim(), 'gcc.exe');
        if (File(gccPath).existsSync()) {
          final gcc = CompilerInfo(
            name: 'GNU GCC (${p.basename(p.dirname(gccPath))})',
            exePath: gccPath,
            type: 'GCC',
            isPortable: false,
          );
          availableCompilers.add(gcc);
          activeCompiler ??= gcc;
          break;
        }
      }
    }

    // Android ve Genel Bulut GNU GCC Derleyicisi
    final cloudGcc = CompilerInfo(
      name: 'GNU GCC (C-Studio Cloud Runner)',
      exePath: 'wandbox',
      type: 'GCC',
      isPortable: false,
    );
    availableCompilers.add(cloudGcc);

    if (activeCompiler == null || !Platform.isWindows) {
      activeCompiler = cloudGcc;
    }
  }

  /// Verilen C kodunu hızlıca derleyerek sözdizimi hatalarını döner
  Future<String?> checkSyntax(String cCode) async {
    if (activeCompiler == null) return null;

    if (activeCompiler!.exePath == 'wandbox' || !Platform.isWindows) {
      // Çevrimdışı temel sözdizimi doğrulaması
      final fallback = _offlineFallback(cCode, '');
      if (!fallback.success) return fallback.output;
      return null;
    }

    if (!File(activeCompiler!.exePath).existsSync()) return null;

    try {
      final tempDir = Directory.systemTemp.createTempSync('cstudio_syntax_');
      final tempFile = File(p.join(tempDir.path, 'check.c'));
      tempFile.writeAsStringSync(cCode);
      final dummyExe = p.join(tempDir.path, 'check.exe');

      final result = await compile(
        sourceFiles: [tempFile.path],
        outputExePath: dummyExe,
      );

      try {
        if (File(dummyExe).existsSync()) File(dummyExe).deleteSync();
        tempDir.deleteSync(recursive: true);
      } catch (_) {}

      if (!result.success && result.output.trim().isNotEmpty) {
        final cleanMsg = result.output
            .replaceAll(tempFile.path, 'main.c')
            .replaceAll(tempDir.path, '')
            .trim();
        return cleanMsg;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CompilationResult> compile({
    required List<String> sourceFiles,
    required String outputExePath,
    String extraFlags = '-Wall',
    String stdin = '',
  }) async {
    if (activeCompiler == null) {
      return CompilationResult(
        success: false,
        exitCode: -1,
        output: 'HATA: Aktif C derleyicisi yapılandırılmamış.',
        outputExe: outputExePath,
      );
    }

    if (sourceFiles.isEmpty) {
      return CompilationResult(
        success: false,
        exitCode: -1,
        output: 'HATA: Derlenecek kaynak dosyası belirtilmedi.',
        outputExe: outputExePath,
      );
    }

    // Android veya Wandbox Cloud Modu
    if (activeCompiler!.exePath == 'wandbox' || !Platform.isWindows) {
      return await _compileCloud(
        sourceFiles: sourceFiles,
        outputExePath: outputExePath,
        stdin: stdin,
      );
    }

    // Windows Masaüstü Yerel TCC / GCC Modu
    if (!File(activeCompiler!.exePath).existsSync()) {
      return CompilationResult(
        success: false,
        exitCode: -1,
        output: 'HATA: C derleyicisi bulunamadı!\nLütfen compiler/tcc.exe dosyasının mevcut olduğunu kontrol edin.',
        outputExe: outputExePath,
      );
    }

    final args = <String>[];
    for (final src in sourceFiles) {
      args.add(src);
    }

    final compilerDir = p.dirname(activeCompiler!.exePath);
    final runtimeHelper = p.join(compilerDir, 'cstudio_runtime.h');
    if (File(runtimeHelper).existsSync()) {
      final safePath = runtimeHelper.replaceAll('\\', '/');
      args.addAll(['-include', safePath]);
    }

    args.addAll(['-o', outputExePath]);
    if (extraFlags.isNotEmpty) {
      args.addAll(extraFlags.split(' '));
    }

    final workDir = p.dirname(sourceFiles.first);

    try {
      final res = await Process.run(
        activeCompiler!.exePath,
        args,
        workingDirectory: workDir,
        runInShell: false,
      );

      final stdout = (res.stdout as String).trim();
      final stderr = (res.stderr as String).trim();
      final outCombined = [if (stdout.isNotEmpty) stdout, if (stderr.isNotEmpty) stderr].join('\n');

      final success = res.exitCode == 0 && File(outputExePath).existsSync();

      return CompilationResult(
        success: success,
        exitCode: res.exitCode,
        output: outCombined,
        outputExe: outputExePath,
      );
    } catch (e) {
      return CompilationResult(
        success: false,
        exitCode: -1,
        output: 'Derleme sırasında hata oluştu: $e',
        outputExe: outputExePath,
      );
    }
  }

  Future<CompilationResult> _compileCloud({
    required List<String> sourceFiles,
    required String outputExePath,
    String stdin = '',
  }) async {
    final sb = StringBuffer();
    for (final src in sourceFiles) {
      if (File(src).existsSync()) {
        sb.writeln(File(src).readAsStringSync());
      }
    }
    final code = sb.toString();

    try {
      final uri = Uri.parse('https://wandbox.org/api/compile.json');
      final body = jsonEncode({
        'code': code,
        'compiler': 'gcc-head',
        if (stdin.isNotEmpty) 'stdin': stdin,
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          final statusStr = data['status']?.toString() ?? '0';
          final exitCode = int.tryParse(statusStr) ?? (statusStr == '0' ? 0 : 1);
          final compError = data['compiler_error']?.toString() ?? '';
          final compOutput = data['compiler_output']?.toString() ?? '';
          final compMsg = data['compiler_message']?.toString() ?? '';
          final progOutput = data['program_output']?.toString() ?? data['program_message']?.toString() ?? '';

          _lastProgramOutput = progOutput;

          final errDetails = [
            if (compError.isNotEmpty) compError,
            if (compOutput.isNotEmpty) compOutput,
            if (compMsg.isNotEmpty && compError.isEmpty && compOutput.isEmpty) compMsg,
          ].join('\n').trim();

          final cleanOutput = errDetails
              .replaceAll('prog.cc', p.basename(sourceFiles.first))
              .replaceAll('prog.c', p.basename(sourceFiles.first));

          final success = exitCode == 0;
          return CompilationResult(
            success: success,
            exitCode: exitCode,
            output: cleanOutput.isEmpty ? (success ? '✔ Derleme başarılı! (GNU GCC)' : 'Derleme başarısız.') : cleanOutput,
            outputExe: outputExePath,
            programOutput: progOutput,
          );
        }
      }
    } catch (_) {}

    // Çevrimdışı / Bağlantı hatası durumunda yerel sözdizimi doğrulaması
    return _offlineFallback(code, outputExePath);
  }

  CompilationResult _offlineFallback(String code, String outputExePath) {
    if (!code.contains('main(') && !code.contains('main (')) {
      return CompilationResult(
        success: false,
        exitCode: 1,
        output: 'main.c:1:1: error: undefined reference to \'main\' (Programda main fonksiyonu bulunamadi)',
        outputExe: outputExePath,
      );
    }

    int braces = 0;
    int parens = 0;
    for (int i = 0; i < code.length; i++) {
      if (code[i] == '{') braces++;
      if (code[i] == '}') braces--;
      if (code[i] == '(') parens++;
      if (code[i] == ')') parens--;
    }

    if (braces != 0) {
      return CompilationResult(
        success: false,
        exitCode: 1,
        output: 'main.c:1: error: dengesiz suslu parantez { } hatasi',
        outputExe: outputExePath,
      );
    }

    if (parens != 0) {
      return CompilationResult(
        success: false,
        exitCode: 1,
        output: 'main.c:1: error: dengesiz normal parantez ( ) hatasi',
        outputExe: outputExePath,
      );
    }

    _lastProgramOutput = '[Cevrimdisi Mod: Kod sozdizimi basariyla dogrulandi]';
    return CompilationResult(
      success: true,
      exitCode: 0,
      output: '✔ [Cevrimdisi Sozdizimi Kontrolu] Temel C sozdizimi dogrulandi.\nTam GNU GCC derlemesi ve calistirma icin internet baglantinizi kontrol edin.',
      outputExe: outputExePath,
      programOutput: _lastProgramOutput,
    );
  }

  Future<void> runExternalConsole(String exePath, String workingDirectory) async {
    if (!Platform.isWindows) return;

    final exeFile = File(exePath);
    if (!exeFile.existsSync()) {
      throw Exception('Çalıştırılacak dosya bulunamadı: $exePath');
    }

    final workDir = workingDirectory.isNotEmpty ? workingDirectory : exeFile.parent.path;
    final runnerFile = File(p.join(workDir, '_cstudio_run.bat'));

    final batContent = '''@echo off
chcp 65001 >nul
title C-Studio: ${p.basename(exePath)}
cls
"$exePath"
echo.
echo ==================================================
echo [Program tamamlandi - Kapatmak icin herhangi bir tusa basin]
pause >nul
exit
''';

    try {
      runnerFile.writeAsStringSync(batContent);
    } catch (_) {}

    await Process.start(
      'cmd.exe',
      ['/c', 'start', 'C-Studio Konsolu', 'cmd.exe', '/k', runnerFile.path],
      workingDirectory: workDir,
      runInShell: false,
    );
  }
}
