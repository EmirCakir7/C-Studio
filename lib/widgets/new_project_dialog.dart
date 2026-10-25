import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../models/project_model.dart';
import '../services/app_language_service.dart';
import '../services/file_dialog_service.dart';
import '../services/app_path_service.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _pathController;
  ProjectTemplate _selectedTemplate = ProjectModel.templates.first; // 1. Boş C Projesi varsayılan

  @override
  void initState() {
    super.initState();
    final lang = AppLanguageService().uiLanguage;
    final defaultName = lang == 'tr'
        ? 'C_Projem'
        : (lang == 'de' ? 'Mein_C_Projekt' : 'My_C_Project');
    _nameController = TextEditingController(text: defaultName);

    final defaultDir = AppPathService.projectsDirectory;
    _pathController = TextEditingController(text: defaultDir);
    _selectedTemplate = ProjectModel.templates.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _browseFolder() async {
    final lang = AppLanguageService().uiLanguage;
    final title = lang == 'tr'
        ? 'C Projesi Kayıt Klasörünü Seçin'
        : (lang == 'de' ? 'C-Projektordner auswählen' : 'Select C Project Directory');

    final selected = await FileDialogService.pickDirectory(title: title);
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _pathController.text = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langService = AppLanguageService();
    final lang = langService.uiLanguage;

    final dialogTitle = langService.trEnDe('Yeni C Projesi Başlat', 'Start New C Project', 'Neues C-Projekt starten');
    final dialogSubtitle = langService.trEnDe(
        'Projenizin adını ve başlangıç kod şablonunu belirleyin.',
        'Set project name and choose starting template.',
        'Projektname und Startvorlage festlegen.');
    final projectNameLabel = langService.trEnDe('Proje Adı', 'Project Name', 'Projektname');
    final projectDirLabel = langService.trEnDe('Kayıt Dizini', 'Project Directory', 'Projektverzeichnis');
    final browseTooltip = langService.trEnDe('Klasör Seç (Gözat)', 'Browse Folder', 'Ordner durchsuchen');
    final templateHeader = langService.trEnDe('Başlangıç Şablonunu Seçin', 'Select Starting Template', 'Startvorlage auswählen');
    final codePreviewHeader = langService.trEnDe('Kod Önizleme (main.c)', 'Code Preview (main.c)', 'Code-Vorschau (main.c)');
    final cancelLabel = langService.trEnDe('İptal', 'Cancel', 'Abbrechen');
    final createLabel = langService.trEnDe('Projeyi Oluştur', 'Create Project', 'Projekt erstellen');

    return Dialog(
      backgroundColor: const Color(0xFF1A1B26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24283B), width: 1),
      ),
      child: Container(
        width: 720,
        height: 540,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7AA2F7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.create_new_folder_rounded, color: Color(0xFF7AA2F7), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dialogTitle,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      dialogSubtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7982A9)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Proje Adı & Konum Satırı
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectNameLabel,
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFC0CAF5)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF13141C),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF24283B)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF24283B)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF7AA2F7)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectDirLabel,
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFC0CAF5)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pathController,
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF13141C),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF24283B)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF24283B)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Color(0xFF7AA2F7)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: browseTooltip,
                            child: InkWell(
                              onTap: _browseFolder,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2335),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF7AA2F7).withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.folder_open_rounded, color: Color(0xFF7AA2F7), size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Şablon Seçimi & Kod Önizleme
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol: Şablon Listesi
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          templateHeader,
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFC0CAF5)),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF13141C),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF24283B)),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(6),
                              itemCount: ProjectModel.templates.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final t = ProjectModel.templates[index];
                                final isSelected = t.id == _selectedTemplate.id;

                                return InkWell(
                                  onTap: () => setState(() => _selectedTemplate = t),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF1F2335) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF7AA2F7).withValues(alpha: 0.5) : Colors.transparent,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.getDisplayTitle(lang),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF7AA2F7) : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          t.getDisplayDescription(lang),
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            color: const Color(0xFF7982A9),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Sağ: Şablon Kod Önizleme
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          codePreviewHeader,
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFC0CAF5)),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13141C),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF24283B)),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _selectedTemplate.getCode(lang),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  height: 1.45,
                                  color: const Color(0xFF9ECE6A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Alt Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7982A9),
                  ),
                  child: Text(cancelLabel),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(createLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7AA2F7),
                    foregroundColor: const Color(0xFF1A1B26),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final path = _pathController.text.trim();
                    if (name.isEmpty || path.isEmpty) return;

                    final projDir = p.join(path, name);
                    final dir = Directory(projDir);
                    if (!dir.existsSync()) {
                      dir.createSync(recursive: true);
                    }

                    final mainFile = File(p.join(projDir, 'main.c'));
                    mainFile.writeAsStringSync(_selectedTemplate.getCode(lang));

                    final proj = ProjectModel(
                      name: name,
                      rootDirectory: projDir,
                      mainSourceFile: 'main.c',
                      sourceFiles: ['main.c'],
                    );

                    Navigator.pop(context, proj);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
