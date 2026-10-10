import 'dart:io';
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
  String toString() => '$name ${isPortable ? "(Dahili Portatif)" : "(Sistem)"}';
}

class CompilationResult {
  final bool success;
  final int exitCode;
  final String output;
  final String outputExe;

  CompilationResult({
    required this.success,
    required this.exitCode,
    required this.output,
    required this.outputExe,
  });
}

class CompilerService {
  final List<CompilerInfo> availableCompilers = [];
  CompilerInfo? activeCompiler;

  CompilerService() {
    detectCompilers();
  }

  void detectCompilers() {
    availableCompilers.clear();

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

    if (activeCompiler == null && availableCompilers.isNotEmpty) {
      activeCompiler = availableCompilers.first;
    }
  }

  /// Verilen C kodunu hızlıca derleyerek sözdizimi hatalarını döner
  Future<String?> checkSyntax(String cCode) async {
    if (activeCompiler == null || !File(activeCompiler!.exePath).existsSync()) {
      return null;
    }
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
  }) async {
    if (activeCompiler == null || !File(activeCompiler!.exePath).existsSync()) {
      return CompilationResult(
        success: false,
        exitCode: -1,
        output: 'HATA: C derleyicisi bulunamadı!\nLütfen compiler/tcc.exe dosyasının mevcut olduğunu kontrol edin.',
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

    final args = <String>[];
    for (final src in sourceFiles) {
      args.add(src);
    }

    // C-Studio Runtime: printf çıktı tamponunu (buffering) anında boşaltmak için ekle
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

  Future<void> runExternalConsole(String exePath, String workingDirectory) async {
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
