/// A completed download entry stored in history (persisted via SharedPreferences)
class HistoryItemModel {
  final String videoId;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String quality;
  final bool isAudio;
  final String filePath;
  final DateTime downloadedAt;

  const HistoryItemModel({
    required this.videoId,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.quality,
    required this.isAudio,
    required this.filePath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'channelName': channelName,
        'thumbnailUrl': thumbnailUrl,
        'quality': quality,
        'isAudio': isAudio,
        'filePath': filePath,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory HistoryItemModel.fromJson(Map<String, dynamic> json) =>
      HistoryItemModel(
        videoId: json['videoId'] as String,
        title: json['title'] as String,
        channelName: json['channelName'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
        quality: json['quality'] as String,
        isAudio: json['isAudio'] as bool,
        filePath: json['filePath'] as String,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      );
}
