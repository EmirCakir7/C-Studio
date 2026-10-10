import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import '../models/project_model.dart';
import '../services/app_language_service.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final TextEditingController _nameController = TextEditingController(text: 'C_Projem');
  late final TextEditingController _pathController;
  ProjectTemplate _selectedTemplate = ProjectModel.templates.first;

  @override
  void initState() {
    super.initState();
    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\';
    final defaultDir = p.join(userProfile, 'Documents', 'CStudio_Projeleri');
    _pathController = TextEditingController(text: defaultDir);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppLanguageService().isUiTurkish;

    return Dialog(
      backgroundColor: const Color(0xFF1A1B26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF24283B), width: 1),
      ),
      child: Container(
        width: 700,
        height: 520,
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
                      isTr ? 'Yeni C Projesi Başlat' : 'Start New C Project',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isTr
                          ? 'Projenizin adını ve başlangıç kod şablonunu belirleyin.'
                          : 'Set project name and choose starting template.',
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
                        isTr ? 'Proje Adı' : 'Project Name',
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
                        isTr ? 'Kayıt Dizini' : 'Project Directory',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFC0CAF5)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
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
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Şablon Seçimi
            Text(
              isTr ? 'Başlangıç Şablonu Seçin' : 'Select Starting Template',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFC0CAF5)),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Row(
                children: [
                  // Şablon Listesi
                  SizedBox(
                    width: 310,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF13141C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF24283B)),
                      ),
                      child: ListView.builder(
                        itemCount: ProjectModel.templates.length,
                        itemBuilder: (context, index) {
                          final t = ProjectModel.templates[index];
                          final isSel = _selectedTemplate == t;

                          return InkWell(
                            onTap: () => setState(() => _selectedTemplate = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF1F2335) : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSel ? const Color(0xFF7AA2F7) : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.getDisplayTitle(isTr),
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      color: isSel ? Colors.white : const Color(0xFFA9B1D6),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.getDisplayDescription(isTr),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: const Color(0xFF565F89),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Şablon Kod Önizleme
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13141C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF24283B)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _selectedTemplate.initialCode,
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
                  child: Text(isTr ? 'İptal' : 'Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(isTr ? 'Projeyi Oluştur' : 'Create Project'),
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
                    mainFile.writeAsStringSync(_selectedTemplate.initialCode);

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
