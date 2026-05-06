import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snaptube/controllers/history_controller.dart';
import 'package:snaptube/core/theme/app_theme.dart';
import 'package:snaptube/models/history_item_model.dart';

/// History screen — all past completed downloads with timestamps.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HistoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          Obx(() {
            if (ctrl.history.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.neonRed),
              tooltip: 'Clear all history',
              onPressed: () => _confirmClear(context, ctrl),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (ctrl.history.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.history.length,
          itemBuilder: (_, i) => _HistoryCard(
            item: ctrl.history[i],
            onRemove: () => ctrl.removeFromHistory(ctrl.history[i]),
          ),
        );
      }),
    );
  }

  void _confirmClear(BuildContext context, HistoryController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear History?', style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'All history entries will be removed. Downloaded files are not deleted.',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ctrl.clearHistory();
              Get.back();
            },
            child: Text('Clear', style: GoogleFonts.outfit(color: AppTheme.neonRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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
            child: const Icon(Icons.history_rounded, color: AppTheme.textSecondary, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'No history yet',
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed downloads will appear here.',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryItemModel item;
  final VoidCallback onRemove;

  const _HistoryCard({required this.item, required this.onRemove});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: item.thumbnailUrl,
            width: 72,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
            errorWidget: (_, __, ___) => Container(
              color: AppTheme.surfaceColor,
              child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary, size: 20),
            ),
          ),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (item.isAudio ? AppTheme.neonPurple : AppTheme.neonCyan).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (item.isAudio ? AppTheme.neonPurple : AppTheme.neonCyan).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  item.quality,
                  style: TextStyle(
                    color: item.isAudio ? AppTheme.neonPurple : AppTheme.neonCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeAgo(item.downloadedAt),
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.neonRed, size: 20),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
