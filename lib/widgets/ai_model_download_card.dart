import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_model_downloader_service.dart';
import '../services/app_language_service.dart';

class AiModelDownloadCard extends StatefulWidget {
  final VoidCallback? onDownloadCompleted;
  final bool compact;

  const AiModelDownloadCard({
    super.key,
    this.onDownloadCompleted,
    this.compact = false,
  });

  @override
  State<AiModelDownloadCard> createState() => _AiModelDownloadCardState();
}

class _AiModelDownloadCardState extends State<AiModelDownloadCard> {
  final _downloader = AiModelDownloaderService();
  final _langService = AppLanguageService();

  @override
  void initState() {
    super.initState();
    _downloader.addListener(_onDownloaderChanged);
    _langService.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _downloader.removeListener(_onDownloaderChanged);
    _langService.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onDownloaderChanged() {
    if (mounted) {
      if (_downloader.isCompleted) {
        widget.onDownloadCompleted?.call();
      }
      setState(() {});
    }
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_downloader.isModelAlreadyDownloaded() && !_downloader.isDownloading && !_downloader.isCompleted) {
      return const SizedBox.shrink();
    }

    final isDownloading = _downloader.isDownloading;
    final isCompleted = _downloader.isCompleted;
    final hasError = _downloader.errorMessage != null;

    final title = _langService.t('model_not_installed');
    final desc = _langService.t('model_not_installed_desc');
    final downloadBtnLabel = _langService.t('download_ai_model');
    final cancelLabel = _langService.t('cancel');
    final successLabel = _langService.t('model_download_success');
    final retryLabel = _langService.t('retry_download');

    final downloadedMb = (_downloader.downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (_downloader.totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final percent = (_downloader.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF9ECE6A).withValues(alpha: 0.6)
              : (isDownloading ? const Color(0xFF7AA2F7).withValues(alpha: 0.6) : const Color(0xFF24283B)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık Satırı
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF9ECE6A).withValues(alpha: 0.15)
                      : const Color(0xFF7AA2F7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.psychology_rounded,
                  color: isCompleted ? const Color(0xFF9ECE6A) : const Color(0xFF7AA2F7),
                  size: widget.compact ? 18 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? successLabel : title,
                      style: GoogleFonts.inter(
                        fontSize: widget.compact ? 12.5 : 13.5,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? const Color(0xFF9ECE6A) : Colors.white,
                      ),
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7982A9)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // İndirme Durumu & İlerleme Çubuğu
          if (isDownloading) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percent% ($downloadedMb MB / $totalMb MB)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7AA2F7),
                  ),
                ),
                if (_downloader.speedText.isNotEmpty)
                  Text(
                    _downloader.speedText,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: const Color(0xFF9ECE6A),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _downloader.progress > 0 ? _downloader.progress : null,
                minHeight: 6,
                backgroundColor: const Color(0xFF1F2335),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7AA2F7)),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _downloader.cancelDownload(),
                icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFF7768E)),
                label: Text(
                  cancelLabel,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFF7768E)),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ] else if (hasError) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7768E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF7768E).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFF7768E), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_langService.t("download_failed")}: ${_downloader.errorMessage}',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFF7768E)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _downloader.startDownload(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7768E),
                      foregroundColor: const Color(0xFF13141C),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: Text(retryLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else if (!isCompleted) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _downloader.startDownload(),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(downloadBtnLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7AA2F7),
                foregroundColor: const Color(0xFF13141C),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
