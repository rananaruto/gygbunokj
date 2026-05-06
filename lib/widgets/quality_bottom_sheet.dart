import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snaptube/controllers/download_controller.dart';
import 'package:snaptube/controllers/home_controller.dart';
import 'package:snaptube/core/theme/app_theme.dart';
import 'package:snaptube/models/video_info_model.dart';

/// Quality picker bottom sheet.
/// Shows: Video (muxed) qualities + Audio-only MP3 options.
void showQualityBottomSheet(BuildContext context, VideoInfoModel info) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QualityBottomSheet(info: info),
  );
}

class _QualityBottomSheet extends StatefulWidget {
  final VideoInfoModel info;

  const _QualityBottomSheet({required this.info});

  @override
  State<_QualityBottomSheet> createState() => _QualityBottomSheetState();
}

class _QualityBottomSheetState extends State<_QualityBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingQualities = true;
  List<MuxedStreamInfo> _muxedStreams = [];
  List<VideoOnlyStreamInfo> _highResStreams = [];
  AudioOnlyStreamInfo? _audioStream;

  final _homeCtrl = Get.find<HomeController>();
  final _downloadCtrl = Get.find<DownloadController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStreams();
  }

  Future<void> _fetchStreams() async {
    try {
      final muxed = await _homeCtrl.getVideoQualities(widget.info.videoUrl);
      final highRes = await _homeCtrl.getHighResStreams(widget.info.videoUrl);
      final audio = await _homeCtrl.getBestAudioStream(widget.info.videoUrl);
      
      if (mounted) {
        setState(() {
          _muxedStreams = muxed;
          _highResStreams = highRes;
          _audioStream = audio;
          _isLoadingQualities = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingQualities = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.borderColor),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Quality',
              style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppTheme.neonGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(text: '🎬 Video'),
                    Tab(text: '🎵 Audio'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoadingQualities
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan, strokeWidth: 2))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVideoTab(scrollCtrl),
                        _buildAudioTab(scrollCtrl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTab(ScrollController ctrl) {
    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // ── High Resolution (HQ) Section ───────────────
        if (_highResStreams.isNotEmpty) ...[
          _sectionHeader('High Resolution (Merging required)'),
          ..._highResStreams.map((s) => _QualityTile(
                icon: Icons.high_quality_rounded,
                iconColor: AppTheme.neonPurple,
                title: '${s.videoQuality.label} (HQ)',
                subtitle: '${(s.size.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                onTap: () {
                  Get.back();
                  if (_audioStream != null) {
                    _downloadCtrl.startHighResDownload(widget.info, s, _audioStream!);
                  }
                },
              )),
          const SizedBox(height: 16),
        ],

        // ── Standard Section ──────────────────────────
        _sectionHeader('Standard Quality'),
        ..._muxedStreams.map((s) => _QualityTile(
              icon: Icons.videocam_rounded,
              iconColor: AppTheme.neonCyan,
              title: s.videoQuality.label,
              subtitle: '${(s.size.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
              onTap: () {
                Get.back();
                _downloadCtrl.startVideoDownload(widget.info, s);
              },
            )),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }

  Widget _buildAudioTab(ScrollController ctrl) {
    if (_audioStream == null) {
      return _buildUnavailable('No audio streams found.');
    }
    final sizeMb = (_audioStream.size.totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final bitrate = _audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0);

    return ListView(
      controller: ctrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _QualityTile(
          icon: Icons.music_note_rounded,
          iconColor: AppTheme.neonPurple,
          title: 'MP3 • $bitrate kbps',
          subtitle: '$sizeMb MB · Best quality',
          onTap: () {
            Get.back();
            _downloadCtrl.startAudioDownload(
              widget.info,
              _audioStream,
              'MP3 ${bitrate}kbps',
            );
            Get.snackbar(
              '🎵 Audio Download Started',
              widget.info.title,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUnavailable(String msg) {
    return Center(
      child: Text(msg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
    );
  }
}

/// Single quality option tile inside the bottom sheet
class _QualityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QualityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download_rounded, color: AppTheme.neonCyan, size: 22),
          ],
        ),
      ),
    );
  }
}
