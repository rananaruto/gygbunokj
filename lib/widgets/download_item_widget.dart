import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:snaptube/controllers/download_controller.dart';
import 'package:snaptube/core/theme/app_theme.dart';
import 'package:snaptube/models/download_task_model.dart';

/// A single card in the Downloads list showing progress, speed, ETA,
/// status badge, and a cancel button for active downloads.
class DownloadItemWidget extends StatelessWidget {
  final DownloadTaskModel task;

  const DownloadItemWidget({super.key, required this.task});

  Color get _statusColor {
    switch (task.status) {
      case DownloadStatus.completed:
        return AppTheme.neonGreen;
      case DownloadStatus.failed:
        return AppTheme.neonRed;
      case DownloadStatus.cancelled:
        return AppTheme.textSecondary;
      case DownloadStatus.downloading:
        return AppTheme.neonCyan;
      case DownloadStatus.queued:
        return AppTheme.neonOrange;
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.queued:
        return 'Queued';
    }
  }

  String _formatEta(int secs) {
    if (secs <= 0) return '';
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DownloadController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: task.thumbnailUrl,
                    width: 68,
                    height: 46,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surfaceColor,
                      child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + quality badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _badge(
                            task.quality,
                            task.isAudio ? AppTheme.neonPurple : AppTheme.neonCyan,
                          ),
                          const SizedBox(width: 6),
                          _badge(
                            _statusLabel,
                            _statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cancel button for active downloads
                if (task.status == DownloadStatus.downloading ||
                    task.status == DownloadStatus.queued)
                  GestureDetector(
                    onTap: () => ctrl.cancelDownload(task),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.neonRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.neonRed.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.close_rounded, color: AppTheme.neonRed, size: 16),
                    ),
                  ),
              ],
            ),

            // ── Progress bar (only while downloading) ───
            if (task.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 12),
              LinearPercentIndicator(
                lineHeight: 6,
                percent: task.progress.clamp(0.0, 1.0),
                barRadius: const Radius.circular(10),
                backgroundColor: AppTheme.progressBg,
                linearGradient: AppTheme.neonGradient,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(task.progress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  if (task.speedMbps > 0)
                    Text(
                      '${task.speedMbps.toStringAsFixed(1)} MB/s',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  if (task.etaSeconds > 0)
                    Text(
                      'ETA ${_formatEta(task.etaSeconds)}',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                ],
              ),
            ],

            // ── Completed path hint ──────────────────────
            if (task.status == DownloadStatus.completed &&
                task.savedFilePath != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.folder_open_rounded, color: AppTheme.neonGreen, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.savedFilePath!.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: AppTheme.neonGreen, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
