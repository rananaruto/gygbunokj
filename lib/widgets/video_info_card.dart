import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snaptube/core/theme/app_theme.dart';
import 'package:snaptube/models/video_info_model.dart';

/// Beautiful video info card showing thumbnail, title, channel & duration.
class VideoInfoCard extends StatelessWidget {
  final VideoInfoModel info;
  final VoidCallback onDownloadTap;

  const VideoInfoCard({
    super.key,
    required this.info,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ──────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: info.thumbnailUrl,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 190,
                    color: AppTheme.surfaceColor,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.neonCyan, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 190,
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary, size: 40),
                  ),
                ),
              ),
              // Duration badge
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.durationString,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Shorts badge
              if (info.isShort)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.neonRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SHORT',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),

          // ── Info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: AppTheme.textSecondary, size: 14),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        info.channelName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Download Button ──────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.neonGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.neonGlow,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onDownloadTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_rounded, color: Colors.black, size: 20),
                      label: Text(
                        'Download',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
    );
  }
}
