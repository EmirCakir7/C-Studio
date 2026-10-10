import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import 'models/compiler_error.dart';
import 'models/project_model.dart';
import 'services/auto_save_service.dart';
import 'services/compiler_service.dart';
import 'services/smart_error_advisor.dart';
import 'services/local_ai_service.dart';
import 'services/ai_assistant_service.dart';
import 'services/app_language_service.dart';
import 'widgets/code_editor.dart';
import 'widgets/error_solution_panel.dart';
import 'widgets/new_project_dialog.dart';
import 'widgets/project_explorer.dart';
import 'widgets/terminal_panel.dart';
import 'widgets/ai_panel.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/special_keys_bar.dart';
import 'services/file_dialog_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CStudioApp());
}

class CStudioApp extends StatelessWidget {
  const CStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C-Studio - Modern C Geliştirme Ortamı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF13141C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7AA2F7),
          secondary: Color(0xFF7DCFFF),
          surface: Color(0xFF1A1B26),
          error: Color(0xFFF7768E),
        ),
      ),
      home: const MainIDEPage(),
    );
  }
}

class MainIDEPage extends StatefulWidget {
  const MainIDEPage({super.key});

  @override
  State<MainIDEPage> createState() => _MainIDEPageState();
}

class _MainIDEPageState extends State<MainIDEPage> with WidgetsBindingObserver {
  final CompilerService _compilerService = CompilerService();
  final AutoSaveService _autoSaveService = AutoSaveService();
  final AppLanguageService _langService = AppLanguageService();

  final List<ProjectModel> _projects = [];
  ProjectModel? _currentProject;
  String _activeFileName = 'main.c';
  final Map<String, CSyntaxTextController> _fileControllers = {};
  final FocusNode _editorFocusNode = FocusNode();

  List<CompilerError> _errors = [];
  CompilerError? _selectedError;
  String _terminalOutput = '';
  String _buildLog = '';

  Process? _runningProcess;
  bool get _isProgramRunning => _runningProcess != null;

  bool _isCompiling = false;
  String _statusMessage = 'Hazır';
  Color _statusColor = const Color(0xFF16161E);
  String _lastSavedTime = '';

  final GlobalKey<AiPanelState> _aiPanelKey = GlobalKey<AiPanelState>();

  // Sağ Panel: 0: Terminal / Program Çıktısı, 1: Hatalar & Çözümler, 2: AI Asistanı
  int _rightTabIndex = 0;
  bool _isRightPanelOpen = true;
  final double _rightPanelWidth = 430.0;
  bool _showProjectExplorer = true;

  // Klavyede zor bulunan tuşlar sekmesi/çubuğu (Açılıp kapatılabilir)
  bool _showSpecialKeysBar = true;

  void _insertSpecialKey(String text, {int cursorOffset = 0}) {
    final controller = _getOrCreateController(_activeFileName);
    final selection = controller.selection;
    final currentText = controller.text;

    int start = selection.baseOffset;
    int end = selection.extentOffset;

    if (start < 0 || end < 0) {
      start = currentText.length;
      end = currentText.length;
    }

    final min = start < end ? start : end;
    final max = start < end ? end : start;

    final newText = currentText.replaceRange(min, max, text);
    final newCursorPos = (min + text.length + cursorOffset).clamp(0, newText.length);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    _editorFocusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _statusMessage = _langService.isUiTurkish ? 'Hazır' : 'Ready';
    WidgetsBinding.instance.addObserver(this);
    _langService.addListener(_onLanguageChanged);
    _initDefaultProject();
    _setupAutoSave();
  }

  @override
  Future<ui.AppExitResponse> didRequestAppExit() async {
    _runningProcess?.kill();
    LocalAiService().stopServer();
    return ui.AppExitResponse.exit;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _runningProcess?.kill();
      LocalAiService().stopServer();
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        if (_statusMessage == 'Hazır' || _statusMessage == 'Ready') {
          _statusMessage = _langService.isUiTurkish ? 'Hazır' : 'Ready';
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _langService.removeListener(_onLanguageChanged);
    _runningProcess?.kill();
    LocalAiService().stopServer();
    _autoSaveService.dispose();
    _editorFocusNode.dispose();
    for (final c in _fileControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setupAutoSave() {
    _autoSaveService.onFileSaved = (path, time) {
      if (mounted) {
        setState(() {
          _lastSavedTime = DateFormat('HH:mm:ss').format(time);
        });
      }
    };
    _autoSaveService.onStatusChanged = (hasChanges) {
      if (mounted) setState(() {});
    };
  }

  void _initDefaultProject() {
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
    final projectsDir = p.join(userProfile, 'Documents', 'CStudio_Projeleri');
    final pDir = Directory(projectsDir);
    if (!pDir.existsSync()) {
      pDir.createSync(recursive: true);
    }

    _projects.clear();

    // Mevcut projeleri tara
    try {
      for (final entity in pDir.listSync()) {
        if (entity is Directory) {
          final proj = ProjectModel.fromDirectory(entity);
          _projects.add(proj);
        }
      }
    } catch (_) {}

    // Eğer hiç proje yoksa veya Ilk_Projem yoksa oluştur
    final defaultDir = p.join(projectsDir, 'Ilk_Projem');
    if (!Directory(defaultDir).existsSync()) {
      Directory(defaultDir).createSync(recursive: true);
      final mainFile = File(p.join(defaultDir, 'main.c'));
      mainFile.writeAsStringSync(ProjectModel.templates.first.initialCode);
    }

    if (!_projects.any((p) => p.name == 'Ilk_Projem')) {
      _projects.insert(
        0,
        ProjectModel(
          name: 'Ilk_Projem',
          rootDirectory: defaultDir,
          mainSourceFile: 'main.c',
          sourceFiles: ['main.c'],
        ),
      );
    }

    _currentProject = _projects.first;
    _currentProject!.refreshFiles();

    _openFile(_currentProject!.mainSourceFile);
  }

  CSyntaxTextController _getOrCreateController(String fileName) {
    if (_fileControllers.containsKey(fileName)) {
      return _fileControllers[fileName]!;
    }

    final fullPath = p.join(_currentProject!.rootDirectory, fileName);
    String content = '';
    final file = File(fullPath);
    if (file.existsSync()) {
      content = file.readAsStringSync();
    }

    final controller = CSyntaxTextController(text: content);
    _fileControllers[fileName] = controller;

    // Auto-save servisine kaydet
    _autoSaveService.registerFileProvider(fullPath, () => controller.text);

    controller.addListener(() {
      _autoSaveService.markDirty(fullPath);
    });

    return controller;
  }

  void _openFile(String fileName) {
    setState(() {
      _activeFileName = fileName;
      _getOrCreateController(fileName);
    });
  }

  // ================= DERLEME & ÇALIŞTIRMA =================

  Future<void> _compileAndRun() async {
    final ok = await _compileOnly();
    if (ok) {
      _executeProgramDirectly();
    }
  }

  bool _fileContainsMain(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      final content = file.readAsStringSync();
      return RegExp(r'\b(int|void)?\s*main\s*\(').hasMatch(content);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _compileOnly() async {
    if (_currentProject == null) return false;

    // Önce çalışan eski işlem varsa sonlandır
    if (_isProgramRunning) {
      _stopProgram();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    final outExe = _currentProject!.fullOutputPath;
    try {
      final exeFile = File(outExe);
      if (exeFile.existsSync()) {
        exeFile.deleteSync();
      }
    } catch (_) {
      try {
        Process.runSync('taskkill', ['/F', '/IM', p.basename(outExe)]);
        await Future.delayed(const Duration(milliseconds: 150));
        final exeFile = File(outExe);
        if (exeFile.existsSync()) {
          exeFile.deleteSync();
        }
      } catch (_) {}
    }

    // Bekleyen tüm değişiklikleri diske kaydet
    _autoSaveService.saveAllDirty();

    final isTr = _langService.isUiTurkish;
    setState(() {
      _isCompiling = true;
      _statusMessage = isTr ? '⏳ Derleniyor...' : '⏳ Compiling...';
      _statusColor = const Color(0xFFD08770);
    });

    _currentProject!.refreshFiles();
    final allC = <String>[];
    for (final s in _currentProject!.sourceFiles) {
      if (s.endsWith('.c')) {
        final full = p.join(_currentProject!.rootDirectory, s);
        if (File(full).existsSync()) {
          allC.add(full);
        }
      }
    }

    final activePath = p.join(_currentProject!.rootDirectory, _activeFileName);
    final sourceFiles = <String>[];

    // Aktif dosya .c ise ve main() içeriyorsa, bu dosyayı ve projede main() İÇERMEYEN yardımcıları derle
    if (_activeFileName.endsWith('.c') && _fileContainsMain(activePath)) {
      sourceFiles.add(activePath);
      for (final src in allC) {
        if (src != activePath && !_fileContainsMain(src)) {
          sourceFiles.add(src);
        }
      }
    } else {
      // Aktif dosya main() içermiyorsa, projede main() içeren ilk dosyayı bul
      final mainFiles = allC.where((f) => _fileContainsMain(f)).toList();
      if (mainFiles.isNotEmpty) {
        final primary = mainFiles.first;
        sourceFiles.add(primary);
        for (final src in allC) {
          if (src != primary && !_fileContainsMain(src)) {
            sourceFiles.add(src);
          }
        }
      } else {
        sourceFiles.addAll(allC);
      }
    }

    if (sourceFiles.isEmpty && File(activePath).existsSync()) {
      sourceFiles.add(activePath);
    }

    final res = await _compilerService.compile(
      sourceFiles: sourceFiles,
      outputExePath: outExe,
      extraFlags: '-Wall',
    );

    final parsed = SmartErrorAdvisor.parseErrors(res.output, activePath);

    setState(() {
      _isCompiling = false;
      _errors = parsed;
      _selectedError = parsed.isNotEmpty ? parsed.first : null;
      _buildLog = '=== ${isTr ? "Derleme Raporu" : "Build Report"} (${DateFormat('HH:mm:ss').format(DateTime.now())}) ===\n'
          '${isTr ? "Derleyici" : "Compiler"}: ${_compilerService.activeCompiler?.name ?? (isTr ? "Bilinmiyor" : "Unknown")}\n'
          '${isTr ? "Derlenen Dosyalar" : "Compiled Files"}: ${sourceFiles.map((s) => p.basename(s)).join(', ')}\n'
          '${isTr ? "Hedef" : "Target"}: $outExe\n'
          '${isTr ? "Çıkış Kodu" : "Exit Code"}: ${res.exitCode}\n'
          '----------------------------------------\n'
          '${res.output}';

      if (res.success) {
        _statusMessage = isTr ? '✔ Derleme Başarılı! (F5 ile Çalıştır)' : '✔ Build Successful! (Press F5 to Run)';
        _statusColor = const Color(0xFF1E3A2F);
        // Başarılıysa Terminal sekmesine geç!
        _rightTabIndex = 0;
        _isRightPanelOpen = true;
      } else {
        _statusMessage = isTr ? '❌ Derleme Hatası (${parsed.length} sorun)' : '❌ Build Error (${parsed.length} issues)';
        _statusColor = const Color(0xFF3E1F24);
        // Hata varsa Hatalar sekmesine odaklan!
        _rightTabIndex = 1;
        _isRightPanelOpen = true;
      }
    });

    if (parsed.isNotEmpty && !res.success) {
      _jumpToError(parsed.first);
    }

    return res.success;
  }

  Future<void> _executeProgramDirectly() async {
    if (_currentProject == null) return;
    final outExe = _currentProject!.fullOutputPath;
    final isTr = _langService.isUiTurkish;

    if (!File(outExe).existsSync()) {
      _showSnackbar(isTr ? 'Çalıştırılabilir dosya bulunamadı: $outExe' : 'Executable file not found: $outExe', isError: true);
      return;
    }

    setState(() {
      _rightTabIndex = 0; // Doğrudan Terminal & Çıktı sekmesine geç
      _isRightPanelOpen = true;
      _terminalOutput = '🚀 ${isTr ? "Program Başlatıldı" : "Program Started"}: ${p.basename(outExe)} [${DateFormat('HH:mm:ss').format(DateTime.now())}]\n'
          '--------------------------------------------------\n';
    });

    try {
      final proc = await Process.start(
        outExe,
        [],
        workingDirectory: _currentProject!.rootDirectory,
        runInShell: false,
      );

      setState(() {
        _runningProcess = proc;
      });

      // Canlı stdout dinle
      proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen(
        (data) {
          if (mounted) {
            setState(() {
              _terminalOutput += data;
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _terminalOutput += '\n[${isTr ? "Çıktı Hatası" : "Output Error"}: $err]\n';
            });
          }
        },
      );

      // Canlı stderr dinle
      proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
        if (mounted) {
          setState(() {
            _terminalOutput += data;
          });
        }
      });

      // Program tamamlandığında
      proc.exitCode.then((code) {
        if (mounted) {
          setState(() {
            _runningProcess = null;
            _terminalOutput += '\n--------------------------------------------------\n'
                '✔ ${isTr ? "Program tamamlandı" : "Program completed"} (${isTr ? "Çıkış Kodu" : "Exit Code"}: $code)\n';
          });
        }
      });
    } catch (e) {
      setState(() {
        _runningProcess = null;
        _terminalOutput += '\n${isTr ? "Program çalıştırılırken hata oluştu" : "Error running program"}: $e\n';
      });
    }
  }

  void _sendInputToProcess(String input) {
    if (_runningProcess != null) {
      _runningProcess!.stdin.writeln(input);
      setState(() {
        _terminalOutput += '$input\n';
      });
    }
  }

  void _stopProgram() {
    if (_runningProcess != null) {
      final isTr = _langService.isUiTurkish;
      _runningProcess!.kill();
      setState(() {
        _runningProcess = null;
        _terminalOutput += '\n[⏹️ ${isTr ? "Program kullanıcı tarafından durduruldu" : "Program stopped by user"}]\n';
      });
    }
  }

  void _jumpToError(CompilerError err) {
    if (err.fileName.isNotEmpty && err.fileName != _activeFileName) {
      _openFile(err.fileName);
    }

    final controller = _getOrCreateController(_activeFileName);
    final text = controller.text;
    final lines = text.split('\n');

    if (err.line <= lines.length && err.line >= 1) {
      int offset = 0;
      for (int i = 0; i < err.line - 1; i++) {
        offset += lines[i].length + 1;
      }
      final colOffset = (err.column - 1).clamp(0, lines[err.line - 1].length);
      offset += colOffset;

      controller.selection = TextSelection.collapsed(offset: offset);
      _editorFocusNode.requestFocus();
    }
  }

  void _applyAutoFix(CompilerError err) {
    final controller = _getOrCreateController(_activeFileName);
    final original = controller.text;
    final fixed = SmartErrorAdvisor.applyAutoFix(original, err);

    if (original != fixed) {
      controller.text = fixed;
      _autoSaveService.saveFile(p.join(_currentProject!.rootDirectory, _activeFileName));
      _showSnackbar(_langService.isUiTurkish ? '✔ Hata otomatik olarak düzeltildi!' : '✔ Error automatically fixed!', isError: false);

      // Otomatik olarak yeniden derle
      _compileOnly();
    } else {
      _showSnackbar(_langService.isUiTurkish ? 'Bu hata için otomatik düzeltme uygulanamadı.' : 'Automatic fix could not be applied for this error.', isError: true);
    }
  }

  void _askAiAboutError(CompilerError err) {
    setState(() {
      _rightTabIndex = 2; // AI Sekmesi
      _isRightPanelOpen = true;
    });

    final isTr = AiAssistantService().isTurkish;
    final prompt = isTr
        ? 'Aşağıdaki derleme hatasını analiz et:\n'
            '• Nerede: Hatanın hangi dosyada ve kaçıncı satırda olduğunu belirt.\n'
            '• Neden: Neden kaynaklandığını ve C kuralını açıkla.\n'
            '• Nasıl Düzeltildiği: Çözümü anlat ve düzeltilmiş tam çalışan C kodunu ```c ve ``` blokları arasında ver.\n\n'
            'Dosya: ${err.fileName}, Satır: ${err.line}\n'
            'Hata Mesajı: ${err.message}\n'
            'Ham Çıktı: ${err.rawLine}'
        : 'Analyze the compiler error:\n'
            '• Where: State file and line.\n'
            '• Why: Explain the root cause and violated C rule.\n'
            '• How It Was Fixed: Explain the fix and provide the complete working C code in ```c and ``` blocks.\n\n'
            'File: ${err.fileName}, Line: ${err.line}\n'
            'Error Message: ${err.message}\n'
            'Raw Output: ${err.rawLine}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aiPanelKey.currentState?.sendUserPrompt(prompt);
    });
  }

  void _applyAiCodeToEditor(String code) {
    final controller = _getOrCreateController(_activeFileName);
    controller.text = code;
    _autoSaveService.saveFile(p.join(_currentProject!.rootDirectory, _activeFileName));
    _editorFocusNode.requestFocus();
    _showSnackbar(_langService.isUiTurkish ? '✔ Editördeki kod yapay zeka önerisiyle güncellendi!' : '✔ Editor code successfully updated!', isError: false);
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? const Color(0xFFF7768E) : const Color(0xFF9ECE6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleNewProject() async {
    final proj = await showDialog<ProjectModel>(
      context: context,
      builder: (context) => const NewProjectDialog(),
    );

    if (proj != null) {
      setState(() {
        if (!_projects.any((p) => p.rootDirectory == proj.rootDirectory)) {
          _projects.add(proj);
        }
      });
      _switchProject(proj);
      _showSnackbar(_langService.isUiTurkish ? 'Yeni proje oluşturuldu: ${proj.name}' : 'New project created: ${proj.name}');
    }
  }

  Future<void> _handleOpenProjectFolder() async {
    final path = await FileDialogService.pickDirectory();
    if (path == null) return;

    final dir = Directory(path);
    if (!dir.existsSync()) return;

    final existing = _projects.where((pr) => p.canonicalize(pr.rootDirectory) == p.canonicalize(path)).firstOrNull;
    if (existing != null) {
      _switchProject(existing);
      return;
    }

    final proj = ProjectModel.fromDirectory(dir);
    setState(() {
      _projects.add(proj);
    });
    _switchProject(proj);
  }

  void _switchProject(ProjectModel proj) {
    if (_currentProject == proj) return;
    _autoSaveService.saveAllDirty();

    setState(() {
      _currentProject = proj;
      _currentProject!.refreshFiles();
      _fileControllers.clear();
      _errors.clear();
      _selectedError = null;
      _terminalOutput = '';
      _openFile(proj.mainSourceFile);
    });

    _showSnackbar(_langService.isUiTurkish ? '✔ Aktif proje değiştirildi: ${proj.name}' : '✔ Active project switched: ${proj.name}');
  }

  Future<void> _renameProject(ProjectModel proj) async {
    final isTr = _langService.isUiTurkish;
    final textController = TextEditingController(text: proj.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF24283B)),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF7AA2F7), size: 20),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Projeyi Yeniden Adlandır' : 'Rename Project',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTr ? 'Yeni proje adını girin:' : 'Enter new project name:',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC0CAF5)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF13141C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Color(0xFF7982A9))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7AA2F7),
                foregroundColor: const Color(0xFF13141C),
              ),
              onPressed: () {
                final name = textController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop(name);
              },
              child: Text(isTr ? 'Yeniden Adlandır' : 'Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != proj.name) {
      setState(() {
        proj.name = newName;
      });
      _showSnackbar(isTr ? '✔ Proje adı değiştirildi: $newName' : '✔ Project renamed: $newName');
    }
  }

  void _closeProject(ProjectModel proj) {
    if (_projects.length <= 1) return;
    setState(() {
      _projects.remove(proj);
      if (_currentProject == proj) {
        _currentProject = _projects.first;
        _currentProject!.refreshFiles();
        _fileControllers.clear();
        _openFile(_currentProject!.mainSourceFile);
      }
    });
    _showSnackbar(_langService.isUiTurkish ? 'Proje kapatıldı: ${proj.name}' : 'Project closed: ${proj.name}');
  }

  void _showProjectSwitcherMenu(Offset position) async {
    final isTr = _langService.isUiTurkish;
    final List<PopupMenuEntry<String>> menuItems = [];

    if (_projects.length > 1) {
      menuItems.add(
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            isTr ? 'AÇIK PROJELER' : 'OPEN PROJECTS',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7AA2F7)),
          ),
        ),
      );

      for (int i = 0; i < _projects.length; i++) {
        final p = _projects[i];
        final isActive = p == _currentProject;
        menuItems.add(
          PopupMenuItem<String>(
            value: 'switch_$i',
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 14,
                  color: isActive ? const Color(0xFF9ECE6A) : const Color(0xFF565F89),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.white : const Color(0xFFC0CAF5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      menuItems.add(const PopupMenuDivider());
    }

    menuItems.addAll([
      PopupMenuItem<String>(
        value: 'rename_project',
        child: Row(
          children: [
            const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF7AA2F7)),
            const SizedBox(width: 8),
            Text(isTr ? 'Projeyi Yeniden Adlandır' : 'Rename Project', style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'new_project',
        child: Row(
          children: [
            const Icon(Icons.create_new_folder_rounded, size: 15, color: Color(0xFF9ECE6A)),
            const SizedBox(width: 8),
            Text(isTr ? 'Yeni Proje Başlat...' : 'New Project...', style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'open_folder',
        child: Row(
          children: [
            const Icon(Icons.folder_open_rounded, size: 15, color: Color(0xFFE0AF68)),
            const SizedBox(width: 8),
            Text(isTr ? 'Mevcut Projeyi Aç (Klasör)...' : 'Open Existing Project...', style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    ]);

    if (_projects.length > 1) {
      menuItems.add(const PopupMenuDivider());
      menuItems.add(
        PopupMenuItem<String>(
          value: 'close_project',
          child: Row(
            children: [
              const Icon(Icons.close_rounded, size: 15, color: Color(0xFFF7768E)),
              const SizedBox(width: 8),
              Text(isTr ? 'Projeyi Kapat' : 'Close Project', style: const TextStyle(fontSize: 12, color: Color(0xFFF7768E))),
            ],
          ),
        ),
      );
    }

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: const Color(0xFF1F2335),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF292E42)),
      ),
      items: menuItems,
    );

    if (selected == null) return;

    if (selected.startsWith('switch_')) {
      final index = int.parse(selected.replaceFirst('switch_', ''));
      _switchProject(_projects[index]);
    } else if (selected == 'rename_project' && _currentProject != null) {
      _renameProject(_currentProject!);
    } else if (selected == 'new_project') {
      _handleNewProject();
    } else if (selected == 'open_folder') {
      _handleOpenProjectFolder();
    } else if (selected == 'close_project' && _currentProject != null) {
      _closeProject(_currentProject!);
    }
  }

  /// C Dosyası İçe Aktar (Bilgisayardan dosya seçip projeye ekler)
  Future<void> _importFile() async {
    final path = await FileDialogService.pickCFile();
    if (path == null) return;

    try {
      final file = File(path);
      final fileName = p.basename(path);
      final content = await file.readAsString();

      if (_currentProject != null) {
        final dest = p.join(_currentProject!.rootDirectory, fileName);
        if (p.canonicalize(path) != p.canonicalize(dest)) {
          await file.copy(dest);
        }
        _currentProject!.refreshFiles();
      }

      final controller = _getOrCreateController(fileName);
      controller.text = content;
      _openFile(fileName);

      _showSnackbar(
        _langService.isUiTurkish
            ? '✔ Dosya başarıyla içe aktarıldı: $fileName'
            : '✔ File successfully imported: $fileName',
      );
    } catch (e) {
      _showSnackbar(_langService.isUiTurkish ? 'Dosya içe aktarılırken hata oluştu: $e' : 'Error importing file: $e', isError: true);
    }
  }

  /// Mevcut C Kodunu Dışa Aktar (Farklı Kaydet)
  Future<void> _exportFile() async {
    final controller = _getOrCreateController(_activeFileName);
    final code = controller.text;

    final dest = await FileDialogService.saveCFile(defaultFileName: _activeFileName);
    if (dest == null) return;

    try {
      final file = File(dest);
      await file.writeAsString(code);
      _showSnackbar(
        _langService.isUiTurkish
            ? '✔ Dosya başarıyla dışa aktarıldı: ${p.basename(dest)}'
            : '✔ File successfully exported: ${p.basename(dest)}',
      );
    } catch (e) {
      _showSnackbar(_langService.isUiTurkish ? 'Dosya dışa aktarılırken hata oluştu: $e' : 'Error exporting file: $e', isError: true);
    }
  }

  /// Dosyayı Yeniden Adlandır (Sağ Tık İle Çağrılır)
  Future<void> _renameFile({String? targetFileName}) async {
    final fileToRename = targetFileName ?? _activeFileName;
    final textController = TextEditingController(text: fileToRename);
    final isTr = _langService.isUiTurkish;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF24283B)),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF7AA2F7), size: 20),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Dosyayı Yeniden Adlandır' : 'Rename File',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTr
                    ? 'Yeni dosya adını girin (.c veya .h uzantılı):'
                    : 'Enter the new file name (with .c or .h extension):',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC0CAF5)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF13141C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Color(0xFF7982A9))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7AA2F7),
                foregroundColor: const Color(0xFF13141C),
              ),
              onPressed: () {
                var name = textController.text.trim();
                if (name.isEmpty) return;
                if (!name.endsWith('.c') && !name.endsWith('.h')) {
                  final ext = p.extension(fileToRename);
                  name = '$name$ext';
                }
                Navigator.of(context).pop(name);
              },
              child: Text(isTr ? 'Yeniden Adlandır' : 'Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != fileToRename && _currentProject != null) {
      try {
        final oldPath = p.join(_currentProject!.rootDirectory, fileToRename);
        final newPath = p.join(_currentProject!.rootDirectory, newName);

        final oldFile = File(oldPath);
        if (oldFile.existsSync()) {
          oldFile.renameSync(newPath);
        }

        final oldController = _fileControllers.remove(fileToRename);
        if (oldController != null) {
          _fileControllers[newName] = oldController;
          _autoSaveService.registerFileProvider(newPath, () => oldController.text);
        }

        if (_currentProject!.mainSourceFile == fileToRename) {
          _currentProject!.mainSourceFile = newName;
        }

        setState(() {
          if (_activeFileName == fileToRename) {
            _activeFileName = newName;
          }
          _currentProject!.refreshFiles();
        });

        _showSnackbar(
          isTr ? '✔ Dosya adı değiştirildi: $newName' : '✔ File renamed: $newName',
        );
      } catch (e) {
        _showSnackbar(_langService.isUiTurkish ? 'Yeniden adlandırılamadı: $e' : 'Could not rename: $e', isError: true);
      }
    }
  }

  /// Dosya Sil (Sağ Tık İle Çağrılır)
  Future<void> _deleteFile(String fileName) async {
    if (_currentProject == null) return;
    final isTr = _langService.isUiTurkish;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF24283B)),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFF7768E), size: 20),
            const SizedBox(width: 8),
            Text(
              isTr ? 'Dosyayı Sil' : 'Delete File',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          isTr
              ? '"$fileName" dosyasını silmek istediğinizden emin misiniz?\nBu işlem geri alınamaz.'
              : 'Are you sure you want to delete "$fileName"?\nThis action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFC0CAF5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Color(0xFF7982A9))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF7768E)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isTr ? 'Sil' : 'Delete', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final filePath = p.join(_currentProject!.rootDirectory, fileName);
        final file = File(filePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
        _fileControllers.remove(fileName);
        _currentProject!.refreshFiles();

        setState(() {
          if (_activeFileName == fileName) {
            _activeFileName = _currentProject!.sourceFiles.isNotEmpty
                ? _currentProject!.sourceFiles.first
                : (_currentProject!.headerFiles.isNotEmpty ? _currentProject!.headerFiles.first : 'main.c');
            _getOrCreateController(_activeFileName);
          }
        });

        _showSnackbar(isTr ? '✔ Dosya silindi: $fileName' : '✔ File deleted: $fileName');
      } catch (e) {
        _showSnackbar(_langService.isUiTurkish ? 'Dosya silinemedi: $e' : 'Could not delete file: $e', isError: true);
      }
    }
  }

  /// Yeni Dosya Ekle (Kullanıcıya İsim Sorar)
  Future<void> _addFileToProject(String ext) async {
    if (_currentProject == null) return;
    final isTr = _langService.isUiTurkish;

    final base = ext == '.h' ? 'baslik' : 'kaynak';
    int counter = 1;
    String defaultName = '$base$ext';
    while (File(p.join(_currentProject!.rootDirectory, defaultName)).existsSync()) {
      counter++;
      defaultName = '$base$counter$ext';
    }

    final textController = TextEditingController(text: defaultName);

    final fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16161E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF24283B)),
          ),
          title: Row(
            children: [
              Icon(
                ext == '.h' ? Icons.data_object_rounded : Icons.code_rounded,
                color: ext == '.h' ? const Color(0xFFE0AF68) : const Color(0xFF7AA2F7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isTr
                    ? (ext == '.h' ? 'Yeni Başlık Dosyası (.h)' : 'Yeni C Dosyası (.c)')
                    : (ext == '.h' ? 'New Header File (.h)' : 'New C Source File (.c)'),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTr ? 'Oluşturulacak dosya adını girin:' : 'Enter the name of the new file:',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC0CAF5)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF13141C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'ornek$ext',
                  hintStyle: const TextStyle(color: Color(0xFF565F89)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Color(0xFF7982A9))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7AA2F7),
                foregroundColor: const Color(0xFF13141C),
              ),
              onPressed: () {
                var name = textController.text.trim();
                if (name.isEmpty) return;
                if (!name.endsWith('.c') && !name.endsWith('.h')) {
                  name = '$name$ext';
                }
                Navigator.of(context).pop(name);
              },
              child: Text(isTr ? 'Oluştur' : 'Create'),
            ),
          ],
        );
      },
    );

    if (fileName == null || fileName.isEmpty) return;

    final fullPath = p.join(_currentProject!.rootDirectory, fileName);
    if (File(fullPath).existsSync()) {
      _showSnackbar(isTr ? 'Bu isimde bir dosya zaten mevcut!' : 'A file with this name already exists!', isError: true);
      return;
    }

    final isH = fileName.endsWith('.h');
    final stem = p.basenameWithoutExtension(fileName).toUpperCase();
    final initText = isH
        ? '#ifndef ${stem}_H\n#define ${stem}_H\n\n// Fonksiyon prototipleri\n\n#endif // ${stem}_H\n'
        : '#include <stdio.h>\n\n// $fileName fonksiyonlari\n';

    File(fullPath).writeAsStringSync(initText);
    _currentProject!.refreshFiles();
    _openFile(fileName);
    _showSnackbar(isTr ? '✔ Dosya oluşturuldu: $fileName' : '✔ File created: $fileName');
  }

  /// Aktif sekme sağ tık menüsü (Yeniden Adlandır, Klasörde Göster, Sil)
  void _showTabContextMenu(Offset position) async {
    final isTr = _langService.isUiTurkish;
    final totalFiles = (_currentProject?.sourceFiles.length ?? 0) + (_currentProject?.headerFiles.length ?? 0);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: const Color(0xFF1F2335),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF292E42)),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF7AA2F7)),
              const SizedBox(width: 8),
              Text(isTr ? 'Yeniden Adlandır' : 'Rename', style: const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'open_in_explorer',
          child: Row(
            children: [
              const Icon(Icons.folder_open_rounded, size: 15, color: Color(0xFFE0AF68)),
              const SizedBox(width: 8),
              Text(isTr ? 'Dosya Konumunu Aç' : 'Reveal in Explorer', style: const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        ),
        if (totalFiles > 1)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFF7768E)),
                const SizedBox(width: 8),
                Text(isTr ? 'Dosyayı Sil' : 'Delete File', style: const TextStyle(fontSize: 12, color: Color(0xFFF7768E))),
              ],
            ),
          ),
      ],
    );

    if (selected == 'rename') {
      _renameFile();
    } else if (selected == 'open_in_explorer' && _currentProject != null) {
      final fullPath = p.join(_currentProject!.rootDirectory, _activeFileName);
      Process.start('explorer.exe', ['/select,', fullPath]);
    } else if (selected == 'delete') {
      _deleteFile(_activeFileName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeController = _getOrCreateController(_activeFileName);
    final errorLines = _errors
        .where((e) => e.fileName == _activeFileName)
        .map((e) => e.line)
        .toSet();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): _compileAndRun,
        const SingleActivator(LogicalKeyboardKey.f6): _compileOnly,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _autoSaveService.saveAllDirty();
          _showSnackbar(_langService.isUiTurkish ? 'Dosya kaydedildi.' : 'File saved.');
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              // 1. Üst Modern Araç Çubuğu (Toolbar)
              _buildTopBar(),

              // 2. Ana Çalışma Alanı (Sol: Gezgin, Orta: Editör, Sağ: Çıktı / Hatalar / AI)
              Expanded(
                child: Row(
                  children: [
                    // Sol: Proje Gezgini
                    if (_showProjectExplorer) ...[
                      SizedBox(
                        width: 220,
                        child: ProjectExplorer(
                          project: _currentProject,
                          projects: _projects,
                          activeFile: _activeFileName,
                          onFileSelected: _openFile,
                          onAddCFile: () => _addFileToProject('.c'),
                          onAddHFile: () => _addFileToProject('.h'),
                          onOpenFolder: () {
                            if (_currentProject != null) {
                              Process.start('explorer.exe', [_currentProject!.rootDirectory]);
                            }
                          },
                          onProjectSelected: _switchProject,
                          onNewProject: _handleNewProject,
                          onOpenExistingProject: _handleOpenProjectFolder,
                          onRenameProject: _renameProject,
                          onCloseProject: _closeProject,
                          onRenameFile: (f) => _renameFile(targetFileName: f),
                          onDeleteFile: _deleteFile,
                        ),
                      ),
                      const VerticalDivider(color: Color(0xFF24283B), width: 1),
                    ],

                    // Orta: Sekmeler ve Tam Boy Kod Editörü
                    Expanded(
                      child: Column(
                        children: [
                          // Dosya Sekmeleri
                          _buildTabBar(),

                          // Klavyede zor bulunan tuşlar sekmesi / çubuğu (Açılıp Kapatılabilir)
                          if (_showSpecialKeysBar)
                            SpecialKeysBar(
                              onInsert: _insertSpecialKey,
                              onClose: () => setState(() => _showSpecialKeysBar = false),
                            ),

                          // Kod Editörü (Tam Boy!)
                          Expanded(
                            child: CodeEditor(
                              controller: activeController,
                              focusNode: _editorFocusNode,
                              errorLines: errorLines,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sağ: Program Çıktısı, Hatalar ve Yapay Zeka
                    if (_isRightPanelOpen) ...[
                      const VerticalDivider(color: Color(0xFF24283B), width: 1),
                      SizedBox(
                        width: _rightPanelWidth,
                        child: _buildRightPanel(),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Durum Çubuğu (Status Bar)
              _buildStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isTr = _langService.isUiTurkish;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16161E),
        border: Border(bottom: BorderSide(color: Color(0xFF24283B))),
      ),
      child: Row(
        children: [
          // Logo & İsim
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/icons/app_logo.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7AA2F7), Color(0xFF7DCFFF)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.code_rounded, color: Color(0xFF13141C), size: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'C-STUDIO',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),

          // Aktif Proje Seçici / Değiştirici Buton
          InkWell(
            onTapDown: (details) => _showProjectSwitcherMenu(details.globalPosition),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2335),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF292E42)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_special_rounded, size: 14, color: Color(0xFF7AA2F7)),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      _currentProject?.name ?? (_langService.isUiTurkish ? 'Proje' : 'Project'),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF7982A9)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Dosya & Proje İşlemleri
          _buildToolButton(
            icon: Icons.create_new_folder_outlined,
            label: isTr ? 'Yeni' : 'New',
            onTap: _handleNewProject,
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: Icons.file_upload_outlined,
            label: isTr ? 'İçe Aktar' : 'Import',
            onTap: _importFile,
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: Icons.file_download_outlined,
            label: isTr ? 'Dışa Aktar' : 'Export',
            onTap: _exportFile,
          ),
          const SizedBox(width: 4),
          _buildToolButton(
            icon: Icons.save_outlined,
            label: isTr ? 'Kaydet' : 'Save',
            onTap: () {
              _autoSaveService.saveAllDirty();
              _showSnackbar(isTr ? 'Tüm dosyalar kaydedildi.' : 'All files saved.');
            },
          ),

          const SizedBox(width: 10),
          Container(width: 1, height: 20, color: const Color(0xFF24283B)),
          const SizedBox(width: 10),

          // ▶️ DERLE VE ÇALIŞTIR (Büyük Canlı Yeşil Buton)
          ElevatedButton.icon(
            icon: _isCompiling
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF13141C)),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Row(
              children: [
                Text(
                  isTr ? 'Derle & Çalıştır' : 'Build & Run',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13141C).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('F5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9ECE6A),
              foregroundColor: const Color(0xFF13141C),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _isCompiling ? null : _compileAndRun,
          ),

          const SizedBox(width: 6),

          // ⚙️ Sadece Derle
          OutlinedButton.icon(
            icon: const Icon(Icons.build_rounded, size: 13),
            label: Text(
              isTr ? 'Derle (F6)' : 'Compile (F6)',
              style: const TextStyle(fontSize: 11.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC0CAF5),
              side: const BorderSide(color: Color(0xFF3B4261)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _isCompiling ? null : _compileOnly,
          ),

          const Spacer(),

          // Aktif Yapay Zeka Modeli Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2335),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E2248)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.smart_toy_rounded, size: 14, color: Color(0xFFBB9AF7)),
                const SizedBox(width: 6),
                Text(
                  'Qwen 2.5 Coder 1.5B',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBB9AF7), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Derleyici Bilgisi Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B26),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF24283B)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.memory_rounded, size: 13, color: Color(0xFF7AA2F7)),
                const SizedBox(width: 5),
                Text(
                  _compilerService.activeCompiler?.name ?? 'TCC 64-bit',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFC0CAF5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Ayarlar
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF7982A9)),
            tooltip: isTr ? 'Ayarlar' : 'Settings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            },
          ),

          // Sağ Paneli Aç/Kapat Butonu
          IconButton(
            icon: Icon(
              _isRightPanelOpen ? Icons.view_sidebar_rounded : Icons.view_sidebar_outlined,
              size: 18,
              color: _isRightPanelOpen ? const Color(0xFF7AA2F7) : const Color(0xFF7982A9),
            ),
            tooltip: isTr ? 'Sağ Paneli Aç/Kapat' : 'Toggle Right Panel',
            onPressed: () {
              setState(() => _isRightPanelOpen = !_isRightPanelOpen);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
    String? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF7AA2F7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF7AA2F7).withValues(alpha: 0.4)),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFF7982A9)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isSelected ? const Color(0xFF7AA2F7) : const Color(0xFFC0CAF5),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFF7768E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final isTr = _langService.isUiTurkish;

    return Container(
      height: 34,
      color: const Color(0xFF13141C),
      child: Row(
        children: [
          // Aktif Dosya Sekmesi (Sağ tık ile yeniden adlandırma, konum açma, silme)
          GestureDetector(
            onSecondaryTapDown: (details) => _showTabContextMenu(details.globalPosition),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF16161E),
                border: Border(
                  top: BorderSide(color: Color(0xFF7AA2F7), width: 2),
                  right: BorderSide(color: Color(0xFF24283B)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _activeFileName.endsWith('.h') ? Icons.data_object_rounded : Icons.code_rounded,
                    size: 14,
                    color: _activeFileName.endsWith('.h') ? const Color(0xFFE0AF68) : const Color(0xFF7AA2F7),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _activeFileName,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Hızlı Tuşlar Sekmesi Aç/Kapat Butonu
          Tooltip(
            message: isTr
                ? 'Klavyede zor bulunan tuşlar paneli ({}, [], \\, |, ~, ->)'
                : 'Special characters panel ({}, [], \\, |, ~, ->)',
            waitDuration: const Duration(milliseconds: 300),
            child: InkWell(
              onTap: () => setState(() => _showSpecialKeysBar = !_showSpecialKeysBar),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _showSpecialKeysBar
                      ? const Color(0xFF7AA2F7).withValues(alpha: 0.15)
                      : const Color(0xFF16161E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _showSpecialKeysBar
                        ? const Color(0xFF7AA2F7).withValues(alpha: 0.5)
                        : const Color(0xFF24283B),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_outlined,
                      size: 13,
                      color: _showSpecialKeysBar ? const Color(0xFF7AA2F7) : const Color(0xFF7982A9),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isTr ? 'Hızlı Tuşlar' : 'Quick Keys',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _showSpecialKeysBar ? const Color(0xFF7AA2F7) : const Color(0xFFC0CAF5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showSpecialKeysBar ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                      size: 14,
                      color: _showSpecialKeysBar ? const Color(0xFF7AA2F7) : const Color(0xFF7982A9),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sol Proje Gezgini Aç/Kapat Butonu
          IconButton(
            icon: Icon(
              _showProjectExplorer ? Icons.folder_open_rounded : Icons.folder_outlined,
              size: 16,
              color: const Color(0xFF7982A9),
            ),
            tooltip: isTr ? 'Proje Gezginini Göster/Gizle' : 'Toggle Project Explorer',
            onPressed: () => setState(() => _showProjectExplorer = !_showProjectExplorer),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: const Color(0xFF16161E),
      child: Column(
        children: [
          _buildRightTabBar(),
          Expanded(child: _buildRightPanelContent()),
        ],
      ),
    );
  }

  Widget _buildRightTabBar() {
    final isTr = _langService.isUiTurkish;

    return Container(
      height: 36,
      color: const Color(0xFF16161E),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF24283B))),
      ),
      child: Row(
        children: [
          _buildRightTabItem(
            index: 0,
            title: isTr ? '💻 Çıktı' : '💻 Output',
            badge: _isProgramRunning ? (isTr ? 'ÇALIŞIYOR' : 'RUNNING') : null,
            badgeColor: const Color(0xFF9ECE6A),
          ),
          const SizedBox(width: 4),
          _buildRightTabItem(
            index: 1,
            title: isTr ? '⚠️ Hatalar' : '⚠️ Errors',
            badge: _errors.isNotEmpty ? '${_errors.length}' : null,
            badgeColor: _errors.any((e) => !e.isWarning) ? const Color(0xFFF7768E) : const Color(0xFFE0AF68),
          ),
          const SizedBox(width: 4),
          _buildRightTabItem(
            index: 2,
            title: isTr ? '🤖 Yapay Zeka' : '🤖 AI',
          ),
          const SizedBox(width: 4),
          _buildRightTabItem(
            index: 3,
            title: isTr ? '📋 Kayıtlar' : '📋 Logs',
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF7982A9)),
            tooltip: isTr ? 'Sağ Paneli Kapat' : 'Close Right Panel',
            onPressed: () {
              setState(() => _isRightPanelOpen = false);
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRightTabItem({
    required int index,
    required String title,
    String? badge,
    Color? badgeColor,
  }) {
    final isSel = _rightTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _rightTabIndex = index),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF7AA2F7).withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSel ? Border.all(color: const Color(0xFF7AA2F7).withValues(alpha: 0.35)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? const Color(0xFF7AA2F7) : const Color(0xFF7982A9),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFFF7768E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanelContent() {
    return IndexedStack(
      index: _rightTabIndex.clamp(0, 3),
      children: [
        TerminalPanel(
          output: _terminalOutput,
          isRunning: _isProgramRunning,
          onSendInput: _sendInputToProcess,
          onStop: _stopProgram,
          onRun: _compileAndRun,
          onClear: () {
            setState(() {
              _terminalOutput = '';
            });
          },
        ),
        ErrorSolutionPanel(
          errors: _errors,
          selectedError: _selectedError,
          onErrorSelected: (err) {
            setState(() => _selectedError = err);
            _jumpToError(err);
          },
          onApplyAutoFix: _applyAutoFix,
          onAskAi: _askAiAboutError,
        ),
        AiPanel(
          key: _aiPanelKey,
          activeCode: _getOrCreateController(_activeFileName).text,
          getActiveCode: () => _getOrCreateController(_activeFileName).text,
          onApplyCodeToEditor: _applyAiCodeToEditor,
          onInsertCodeToCursor: (code) => _insertSpecialKey(code),
        ),
        Container(
          color: const Color(0xFF10111A),
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: SelectableText(
              _buildLog.isEmpty ? (_langService.isUiTurkish ? 'Derleme raporu henüz oluşturulmadı.' : 'No build report generated yet.') : _buildLog,
              style: GoogleFonts.jetBrainsMono(fontSize: 11.5, color: const Color(0xFF7982A9), height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 24,
      color: const Color(0xFF0F1017),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Durum Mesajı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _statusMessage,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),

          // Otomatik Kayıt Durumu
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 12,
                color: _autoSaveService.hasPendingChanges ? const Color(0xFFE0AF68) : const Color(0xFF9ECE6A),
              ),
              const SizedBox(width: 4),
              Text(
                _autoSaveService.hasPendingChanges
                    ? (_langService.isUiTurkish ? 'Kaydediliyor...' : 'Saving...')
                    : '${_langService.isUiTurkish ? "Otomatik Kayıt: " : "Auto-Save: "}${_lastSavedTime.isNotEmpty ? _lastSavedTime : (_langService.isUiTurkish ? "Aktif" : "Active")}',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7982A9)),
              ),
            ],
          ),

          const Spacer(),

          // UTF-8
          Text('UTF-8', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF565F89))),
          const SizedBox(width: 12),

          // Derleyici
          Text(
            _compilerService.activeCompiler?.name ?? 'TCC 64-bit',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7AA2F7)),
          ),
        ],
      ),
    );
  }
}
