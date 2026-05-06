/// Metadata for a YouTube video fetched via youtube_explode_dart
class VideoInfoModel {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final Duration duration;
  final String videoUrl;
  final bool isShort;

  const VideoInfoModel({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.duration,
    required this.videoUrl,
    required this.isShort,
  });

  /// e.g. "3:45" or "1:02:33"
  String get durationString {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
