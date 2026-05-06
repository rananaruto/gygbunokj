import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:snaptube/models/video_info_model.dart';

/// Handles fetching video/playlist info from YouTube.
/// Also manages the URL input and search state on the Home screen.
class HomeController extends GetxController {
  final _yt = YoutubeExplode();

  // ── Observables ───────────────────────────────────────
  final isLoading = false.obs;
  final videoInfo = Rxn<VideoInfoModel>();
  final errorMessage = ''.obs;
  final urlController = ''.obs; // tracks text field value

  // ── Public API ────────────────────────────────────────

  /// Fetch video metadata from a YouTube URL (video, shorts, or playlist item).
  Future<void> fetchVideoInfo(String url) async {
    if (url.trim().isEmpty) return;
    isLoading.value = true;
    errorMessage.value = '';
    videoInfo.value = null;

    try {
      final video = await _yt.videos.get(url.trim());
      videoInfo.value = VideoInfoModel(
        id: video.id.value,
        title: video.title,
        channelName: video.author,
        thumbnailUrl: 'https://img.youtube.com/vi/${video.id.value}/hqdefault.jpg',
        duration: video.duration ?? Duration.zero,
        videoUrl: video.url,
        isShort: _detectShort(video.url),
      );
    } on VideoUnplayableException catch (_) {
      errorMessage.value = 'Video unplayable. It might be private or age-restricted.';
    } on Exception catch (e) {
      debugPrint('fetchVideoInfo error: $e');
      errorMessage.value = 'Could not fetch video. Check the URL and try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Get available video stream qualities for quality picker bottom sheet.
  Future<List<MuxedStreamInfo>> getVideoQualities(String videoUrl) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoUrl);
    // Sort descending by quality
    final sorted = manifest.muxed.toList()
      ..sort((a, b) {
        final aq = int.tryParse(a.qualityLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bq = int.tryParse(b.qualityLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return bq.compareTo(aq);
      });
    return sorted;
  }

  /// Get the audio-only stream for MP3 download.
  Future<AudioOnlyStreamInfo?> getBestAudioStream(String videoUrl) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoUrl);
    if (manifest.audioOnly.isEmpty) return null;
    final sorted = manifest.audioOnly.toList()
      ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
    return sorted.first;
  }

  /// Clear current result
  void clearVideo() {
    videoInfo.value = null;
    errorMessage.value = '';
  }

  /// Detect if URL is a YouTube Shorts link
  bool _detectShort(String url) => url.contains('/shorts/');

  @override
  void onClose() {
    _yt.close();
    super.onClose();
  }
}
