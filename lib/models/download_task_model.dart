/// A single download task (active, queued, or completed)
class DownloadTaskModel {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String quality;   // e.g. "720p", "MP3 128kbps"
  final bool isAudio;

  double progress;        // 0.0 → 1.0
  double speedMbps;       // current MB/s
  int etaSeconds;         // seconds remaining
  DownloadStatus status;
  String? savedFilePath;

  DownloadTaskModel({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.quality,
    required this.isAudio,
    this.progress = 0.0,
    this.speedMbps = 0.0,
    this.etaSeconds = 0,
    this.status = DownloadStatus.queued,
    this.savedFilePath,
  });
}

enum DownloadStatus { queued, downloading, completed, failed, cancelled }
