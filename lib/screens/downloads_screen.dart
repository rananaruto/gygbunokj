import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snaptube/controllers/download_controller.dart';
import 'package:snaptube/core/theme/app_theme.dart';
import 'package:snaptube/models/download_task_model.dart';
import 'package:snaptube/widgets/download_item_widget.dart';

/// Downloads screen — shows the active and completed download queue.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DownloadController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          Obx(() {
            final hasCompleted = ctrl.queue.any((t) => t.status == DownloadStatus.completed);
            if (!hasCompleted) return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: () => ctrl.queue.removeWhere((t) => t.status == DownloadStatus.completed),
              icon: const Icon(Icons.clear_all_rounded, size: 18, color: AppTheme.neonRed),
              label: Text('Clear done', style: GoogleFonts.outfit(color: AppTheme.neonRed, fontSize: 13)),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (ctrl.queue.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.queue.length,
          itemBuilder: (_, i) => DownloadItemWidget(task: ctrl.queue[i]),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(Icons.download_outlined, color: AppTheme.textSecondary, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'No downloads yet',
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Home and paste a YouTube link\nto start downloading.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
