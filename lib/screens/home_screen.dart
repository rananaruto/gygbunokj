import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snaptube/controllers/home_controller.dart';
import 'package:snaptube/core/theme/app_theme.dart';
import 'package:snaptube/widgets/quality_bottom_sheet.dart';
import 'package:snaptube/widgets/video_info_card.dart';

/// Home screen — paste a YouTube link, see video info, pick quality & download.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  final HomeController _controller = Get.find<HomeController>();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    _controller.fetchVideoInfo(_urlController.text);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────
            SliverAppBar(
              expandedHeight: 110,
              pinned: true,
              backgroundColor: AppTheme.bgColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppTheme.neonGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppTheme.neonGlow,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SnapTube',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                          ).createShader(const Rect.fromLTWH(0, 0, 150, 30)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tagline ─────────────────────────
                    Text(
                      'Download any YouTube video,\nShorts or Playlist.',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                    const SizedBox(height: 24),

                    // ── URL Input ───────────────────────
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Paste YouTube link here...',
                          prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.neonCyan, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste_rounded, color: AppTheme.textSecondary, size: 20),
                            tooltip: 'Paste from clipboard',
                            onPressed: _pasteFromClipboard,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2),

                    const SizedBox(height: 16),

                    // ── Search Button ───────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.neonGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.neonGlow,
                        ),
                        child: ElevatedButton(
                          onPressed: _search,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Obx(() => _controller.isLoading.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'FETCH VIDEO',
                                  style: GoogleFonts.outfit(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 1.2,
                                  ),
                                )),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.2),

                    const SizedBox(height: 28),

                    // ── Error Message ───────────────────
                    Obx(() {
                      if (_controller.errorMessage.value.isEmpty) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.neonRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.neonRed.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.neonRed, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _controller.errorMessage.value,
                                style: const TextStyle(color: AppTheme.neonRed, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake();
                    }),

                    // ── Video Info Card ─────────────────
                    Obx(() {
                      final info = _controller.videoInfo.value;
                      if (info == null) return const SizedBox.shrink();
                      return VideoInfoCard(
                        info: info,
                        onDownloadTap: () {
                          showQualityBottomSheet(context, info);
                        },
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3);
                    }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
