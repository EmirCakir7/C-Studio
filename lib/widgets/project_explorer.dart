import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_model.dart';
import '../services/app_language_service.dart';

class ProjectExplorer extends StatelessWidget {
  final ProjectModel? project;
  final List<ProjectModel> projects;
  final String activeFile;
  final ValueChanged<String> onFileSelected;
  final VoidCallback onAddCFile;
  final VoidCallback onAddHFile;
  final VoidCallback onOpenFolder;
  final ValueChanged<ProjectModel>? onProjectSelected;
  final VoidCallback? onNewProject;
  final VoidCallback? onOpenExistingProject;
  final ValueChanged<ProjectModel>? onRenameProject;
  final ValueChanged<ProjectModel>? onCloseProject;
  final ValueChanged<String>? onRenameFile;
  final ValueChanged<String>? onDeleteFile;

  const ProjectExplorer({
    super.key,
    required this.project,
    this.projects = const [],
    required this.activeFile,
    required this.onFileSelected,
    required this.onAddCFile,
    required this.onAddHFile,
    required this.onOpenFolder,
    this.onProjectSelected,
    this.onNewProject,
    this.onOpenExistingProject,
    this.onRenameProject,
    this.onCloseProject,
    this.onRenameFile,
    this.onDeleteFile,
  });

  void _showProjectMenu(BuildContext context, Offset position) async {
    final isTr = AppLanguageService().isUiTurkish;
    final allProjects = projects.isNotEmpty ? projects : (project != null ? [project!] : <ProjectModel>[]);

    final List<PopupMenuEntry<String>> menuItems = [];

    if (allProjects.length > 1) {
      menuItems.add(
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            isTr ? 'AÇIK PROJELER' : 'OPEN PROJECTS',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7AA2F7)),
          ),
        ),
      );

      for (int i = 0; i < allProjects.length; i++) {
        final p = allProjects[i];
        final isActive = p == project;
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

    if (allProjects.length > 1) {
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
      onProjectSelected?.call(allProjects[index]);
    } else if (selected == 'rename_project' && project != null) {
      onRenameProject?.call(project!);
    } else if (selected == 'new_project') {
      onNewProject?.call();
    } else if (selected == 'open_folder') {
      onOpenExistingProject?.call();
    } else if (selected == 'close_project' && project != null) {
      onCloseProject?.call(project!);
    }
  }

  void _showFileContextMenu(BuildContext context, Offset position, String fileName) async {
    final isTr = AppLanguageService().isUiTurkish;
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
      onRenameFile?.call(fileName);
    } else if (selected == 'delete') {
      onDeleteFile?.call(fileName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppLanguageService().isUiTurkish;

    if (project == null) {
      return Container(
        color: const Color(0xFF13141C),
        alignment: Alignment.center,
        child: Text(
          isTr ? 'Proje Açılmadı' : 'No Project Opened',
          style: GoogleFonts.inter(color: const Color(0xFF565F89), fontSize: 13),
        ),
      );
    }

    return Container(
      color: const Color(0xFF13141C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proje Başlığı (Tıklayınca ve Sağ Tıklayınca Proje Menüsü Açılır)
          GestureDetector(
            onSecondaryTapDown: (details) => _showProjectMenu(context, details.globalPosition),
            child: InkWell(
              onTapDown: (details) => _showProjectMenu(context, details.globalPosition),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF16161E),
                  border: Border(bottom: BorderSide(color: Color(0xFF24283B))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_special_rounded, color: Color(0xFF7AA2F7), size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project!.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: const Color(0xFFC0CAF5),
                            ),
                          ),
                          if (projects.length > 1)
                            Text(
                              '${projects.length} ${isTr ? "proje açık" : "projects open"}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF7982A9)),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF7982A9)),
                  ],
                ),
              ),
            ),
          ),

          // Dosya listesi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                // Kaynak Dosyalar (.c)
                _buildSectionHeader(
                  isTr ? 'KAYNAK DOSYALAR (.c)' : 'SOURCE FILES (.c)',
                  onAddCFile,
                ),
                ...project!.sourceFiles.map((f) => _buildFileItem(context, f, isHeader: false)),

                const SizedBox(height: 10),

                // Başlık Dosyaları (.h)
                _buildSectionHeader(
                  isTr ? 'BAŞLIK DOSYALARI (.h)' : 'HEADER FILES (.h)',
                  onAddHFile,
                ),
                if (project!.headerFiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      isTr ? 'Henüz .h dosyası yok' : 'No .h files yet',
                      style: GoogleFonts.inter(color: const Color(0xFF414868), fontSize: 11),
                    ),
                  )
                else
                  ...project!.headerFiles.map((f) => _buildFileItem(context, f, isHeader: true)),
              ],
            ),
          ),

          // Alt Ekleme Butonları
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF24283B))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 13),
                    label: Text(isTr ? '.c Ekle' : 'Add .c', style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7AA2F7),
                      side: const BorderSide(color: Color(0xFF3B4261)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: onAddCFile,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 13),
                    label: Text(isTr ? '.h Ekle' : 'Add .h', style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7DCFFF),
                      side: const BorderSide(color: Color(0xFF3B4261)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: onAddHFile,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    final isTr = AppLanguageService().isUiTurkish;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: const Color(0xFF565F89),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 14, color: Color(0xFF7AA2F7)),
            tooltip: isTr ? 'Yeni Dosya Ekle' : 'Add New File',
            onPressed: onAdd,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, String fileName, {required bool isHeader}) {
    final isSelected = activeFile == fileName;

    return GestureDetector(
      onSecondaryTapDown: (details) => _showFileContextMenu(context, details.globalPosition, fileName),
      child: InkWell(
        onTap: () => onFileSelected(fileName),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1F2335) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isSelected ? const Color(0xFF7AA2F7) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHeader
                      ? const Color(0xFFE0AF68).withValues(alpha: 0.15)
                      : const Color(0xFF7AA2F7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isHeader ? 'H' : 'C',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isHeader ? const Color(0xFFE0AF68) : const Color(0xFF7AA2F7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : const Color(0xFFA9B1D6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
