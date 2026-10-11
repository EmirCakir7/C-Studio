import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  print('=== Packaging C-Studio Release Packages ===');

  final distDir = Directory('dist');
  if (distDir.existsSync()) {
    distDir.deleteSync(recursive: true);
  }
  distDir.createSync(recursive: true);

  final runnerReleaseDir = Directory(p.join('build', 'windows', 'x64', 'runner', 'Release'));
  if (!runnerReleaseDir.existsSync()) {
    print('Error: runner Release directory not found!');
    exit(1);
  }

  // 1. Prepare Base Files for Staging
  final stagingBase = Directory(p.join('dist', 'staging_base', 'C-Studio'));
  stagingBase.createSync(recursive: true);

  // Copy CStudio.exe and flutter_windows.dll
  File(p.join(runnerReleaseDir.path, 'CStudio.exe')).copySync(p.join(stagingBase.path, 'CStudio.exe'));
  File(p.join(runnerReleaseDir.path, 'flutter_windows.dll')).copySync(p.join(stagingBase.path, 'flutter_windows.dll'));

  // Copy data directory
  await copyDirectory(Directory(p.join(runnerReleaseDir.path, 'data')), Directory(p.join(stagingBase.path, 'data')));

  // Copy compiler directory
  await copyDirectory(Directory('compiler'), Directory(p.join(stagingBase.path, 'compiler')));

  // Copy ai/runtime directory
  final aiRuntimeStaging = Directory(p.join(stagingBase.path, 'ai', 'runtime'));
  aiRuntimeStaging.createSync(recursive: true);
  await copyDirectory(Directory(p.join('ai', 'runtime')), aiRuntimeStaging);

  // Copy standalone tools and helpers
  final rootExe = File('c-studio_language_creator.exe');
  if (rootExe.existsSync()) {
    rootExe.copySync(p.join(stagingBase.path, 'C-Studio_Language_Creator.exe'));
  }
  final rootHtml = File('C-Studio_Language_Pack_Creator.html');
  if (rootHtml.existsSync()) {
    rootHtml.copySync(p.join(stagingBase.path, 'C-Studio_Language_Pack_Creator.html'));
  }
  final rootBat = File('Launch_Language_Creator.bat');
  if (rootBat.existsSync()) {
    rootBat.copySync(p.join(stagingBase.path, 'Launch_Language_Creator.bat'));
  }

  // Copy examples
  if (Directory('examples').existsSync()) {
    await copyDirectory(Directory('examples'), Directory(p.join(stagingBase.path, 'examples')));
  }

  // Copy README.md and LICENSE
  if (File('README.md').existsSync()) {
    File('README.md').copySync(p.join(stagingBase.path, 'README.md'));
  }
  if (File('LICENSE').existsSync()) {
    File('LICENSE').copySync(p.join(stagingBase.path, 'LICENSE'));
  }

  // 2. Build Slim Edition
  print('Creating Slim Edition staging...');
  final stagingSlim = Directory(p.join('dist', 'staging_slim', 'C-Studio'));
  stagingSlim.createSync(recursive: true);
  await copyDirectory(stagingBase, stagingSlim);

  // Create empty models dir with README.txt in Slim
  final slimModelsDir = Directory(p.join(stagingSlim.path, 'ai', 'models'));
  slimModelsDir.createSync(recursive: true);
  File(p.join(slimModelsDir.path, 'README.txt')).writeAsStringSync('''C-Studio AI Models Directory
====================================
The offline AI assistant model is not pre-packaged in this Slim edition.

How to enable AI in C-Studio:
1. Open CStudio.exe
2. In the AI Assistant panel or Settings -> AI, click:
   "⬇️ Download AI Model (~881 MB)"
   C-Studio will automatically download and activate Qwen 2.5 Coder 1.5B with 1-click!

Alternatively, you can manually download:
https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q3_k_m.gguf
and place it in this folder.
''');

  final slimZipPath = p.join('dist', 'C-Studio-v1.2.0-Windows-x64-Slim.zip');
  print('Zipping Slim Edition: $slimZipPath...');
  final slimTarResult = await Process.run('tar.exe', [
    '-a',
    '-c',
    '-f',
    p.absolute(slimZipPath),
    'C-Studio',
  ], workingDirectory: p.join('dist', 'staging_slim'));

  if (slimTarResult.exitCode != 0) {
    print('Error creating slim zip: ${slimTarResult.stderr}');
    exit(1);
  }
  print('Slim Edition created: ${(File(slimZipPath).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');

  // 3. Build Full Edition (With AI)
  print('Creating Full Edition staging (With AI)...');
  final stagingFull = Directory(p.join('dist', 'staging_full', 'C-Studio'));
  stagingFull.createSync(recursive: true);
  await copyDirectory(stagingBase, stagingFull);

  // Copy AI model into stagingFull
  final fullModelsDir = Directory(p.join(stagingFull.path, 'ai', 'models'));
  fullModelsDir.createSync(recursive: true);
  final localModel = File(p.join('ai', 'models', 'qwen2.5-coder-1.5b-instruct-q3_k_m.gguf'));
  if (localModel.existsSync()) {
    print('Copying AI model to full package (~881 MB)...');
    localModel.copySync(p.join(fullModelsDir.path, 'qwen2.5-coder-1.5b-instruct-q3_k_m.gguf'));
  } else {
    print('Warning: local model file not found in ai/models/');
  }

  final fullZipPath = p.join('dist', 'C-Studio-v1.2.0-Windows-x64-With-AI.zip');
  print('Zipping Full Edition: $fullZipPath...');
  final fullTarResult = await Process.run('tar.exe', [
    '-a',
    '-c',
    '-f',
    p.absolute(fullZipPath),
    'C-Studio',
  ], workingDirectory: p.join('dist', 'staging_full'));

  if (fullTarResult.exitCode != 0) {
    print('Error creating full zip: ${fullTarResult.stderr}');
    exit(1);
  }
  print('Full Edition created: ${(File(fullZipPath).lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');

  // Copy standalone exe for release asset
  if (rootExe.existsSync()) {
    rootExe.copySync(p.join('dist', 'C-Studio_Language_Creator.exe'));
    print('Copied C-Studio_Language_Creator.exe to dist/');
  }

  print('=== Packaging complete! ===');
}

Future<void> copyDirectory(Directory source, Directory destination) async {
  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }

  for (final entity in source.listSync(recursive: false)) {
    final newPath = p.join(destination.path, p.basename(entity.path));
    if (entity is File) {
      entity.copySync(newPath);
    } else if (entity is Directory) {
      await copyDirectory(entity, Directory(newPath));
    }
  }
}
