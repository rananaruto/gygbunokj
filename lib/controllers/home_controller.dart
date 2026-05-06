import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:snaptube/models/video_info_model.dart';

/// Handles fetching video/playlist info from YouTube.
/// Also manages the URL input and search state on the Home screen.
class HomeController extends GetxController {
  final _yt = YoutubeExplode();
  final _dio = Dio();

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

  /// Bulk fetch multiple videos from a list of URLs
  Future<void> fetchBulkVideos(List<String> urls) async {
    isLoading.value = true;
    int count = 0;
    for (var url in urls) {
      if (url.trim().isEmpty) continue;
      await fetchVideoInfo(url);
      if (videoInfo.value != null) {
        // Auto-queue best quality for bulk
        final qualities = await getVideoQualities(url);
        if (qualities.isNotEmpty) {
          Get.find<DownloadController>().startVideoDownload(videoInfo.value!, qualities.first);
          count++;
        }
      }
    }
    Get.snackbar('Bulk Download', 'Queued $count videos from list.', snackPosition: SnackPosition.BOTTOM);
    isLoading.value = false;
  }

  /// Get available muxed video streams (720p and below).
  Future<List<MuxedStreamInfo>> getVideoQualities(String videoUrl) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoUrl);
    final sorted = manifest.muxed.toList()
      ..sort((a, b) => b.videoQuality.index.compareTo(a.videoQuality.index));
    return sorted;
  }

  /// Get high-resolution video-only DASH streams (1080p, 4K, 8K).
  Future<List<VideoOnlyStreamInfo>> getHighResStreams(String videoUrl) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoUrl);
    final sorted = manifest.videoOnly.toList()
      ..sort((a, b) => b.videoQuality.index.compareTo(a.videoQuality.index));
    return sorted;
  }

  /// Get the best audio-only stream for merging or MP3.
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

  /// Fetch skippable segments (SponsorBlock API)
  Future<List<Map<String, dynamic>>> fetchSponsorSegments(String videoId) async {
    try {
      final response = await _dio.get(
        'https://sponsor.ajay.app/api/skipSegments',
        queryParameters: {
          'videoID': videoId,
          'categories': '["sponsor", "intro", "outro", "interaction", "selfpromo"]'
        },
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      debugPrint('SponsorBlock error: $e');
    }
    return [];
  }

  @override
  void onClose() {
    _yt.close();
    super.onClose();
  }
}
