import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:snaptube/controllers/history_controller.dart';
import 'package:snaptube/models/download_task_model.dart';
import 'package:snaptube/models/history_item_model.dart';
import 'package:snaptube/models/video_info_model.dart';

/// Manages the download queue.
/// Handles video + audio downloads with real-time progress, speed, and ETA.
class DownloadController extends GetxController {
  final _yt = YoutubeExplode();

  final RxList<DownloadTaskModel> queue = <DownloadTaskModel>[].obs;

  /// Cancel an active download
  void cancelDownload(DownloadTaskModel task) {
    task.status = DownloadStatus.cancelled;
    queue.refresh();
  }

  /// Start a standard muxed video download (720p and below).
  Future<void> startVideoDownload(
    VideoInfoModel info,
    MuxedStreamInfo streamInfo,
  ) async {
    final task = DownloadTaskModel(
      videoId: info.id,
      title: info.title,
      thumbnailUrl: info.thumbnailUrl,
      quality: streamInfo.qualityLabel,
      isAudio: false,
      status: DownloadStatus.queued,
    );
    queue.add(task);
    await _runStandardDownload(task, info, streamInfo: streamInfo);
  }

  /// Start a high-resolution video download (1080p, 4K, 8K).
  /// Merges Video-only and Audio-only streams.
  Future<void> startHighResDownload(
    VideoInfoModel info,
    VideoOnlyStreamInfo videoStream,
    AudioOnlyStreamInfo audioStream,
  ) async {
    final task = DownloadTaskModel(
      videoId: info.id,
      title: info.title,
      thumbnailUrl: info.thumbnailUrl,
      quality: '${videoStream.qualityLabel} (HQ)',
      isAudio: false,
      status: DownloadStatus.queued,
    );
    queue.add(task);
    await _runHighResDownload(task, info, videoStream, audioStream);
  }

  /// Start an audio-only (MP3) download.
  Future<void> startAudioDownload(
    VideoInfoModel info,
    AudioOnlyStreamInfo audioStream,
    String qualityLabel,
  ) async {
    final task = DownloadTaskModel(
      videoId: info.id,
      title: info.title,
      thumbnailUrl: info.thumbnailUrl,
      quality: qualityLabel,
      isAudio: true,
      status: DownloadStatus.queued,
    );
    queue.add(task);
    await _runStandardDownload(task, info, audioStream: audioStream);
  }

  // ── Internal ──────────────────────────────────────────

  Future<void> _runStandardDownload(
    DownloadTaskModel task,
    VideoInfoModel info, {
    MuxedStreamInfo? streamInfo,
    AudioOnlyStreamInfo? audioStream,
  }) async {
    if (!await _requestStoragePermission()) {
      task.status = DownloadStatus.failed;
      queue.refresh();
      return;
    }

    task.status = DownloadStatus.downloading;
    queue.refresh();

    try {
      final dir = await _getDownloadDir();
      final safeTitle = _sanitizeFileName(info.title);
      final ext = task.isAudio ? 'mp3' : streamInfo!.container.name;
      final fileName = '${safeTitle}_${task.quality}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${dir.path}/$fileName');

      final streamInfoToUse = (task.isAudio ? audioStream : streamInfo)!;
      await _downloadStream(streamInfoToUse, file, task);

      if (task.status != DownloadStatus.cancelled) {
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        task.savedFilePath = file.path;
        
        Get.find<HistoryController>().addToHistory(HistoryItemModel(
          videoId: info.id,
          title: info.title,
          channelName: info.channelName,
          thumbnailUrl: info.thumbnailUrl,
          quality: task.quality,
          isAudio: task.isAudio,
          filePath: file.path,
          downloadedAt: DateTime.now(),
        ));
      }
      queue.refresh();
    } catch (e) {
      task.status = DownloadStatus.failed;
      queue.refresh();
    }
  }

  // ── Internal ──────────────────────────────────────────

  Future<void> _runHighResDownload(
    DownloadTaskModel task,
    VideoInfoModel info,
    VideoOnlyStreamInfo videoStream,
    AudioOnlyStreamInfo audioStream,
  ) async {
    if (!await _requestStoragePermission()) {
      task.status = DownloadStatus.failed;
      queue.refresh();
      return;
    }

    task.status = DownloadStatus.downloading;
    queue.refresh();

    try {
      final dir = await _getDownloadDir();
      final tempDir = await getTemporaryDirectory();
      final safeTitle = _sanitizeFileName(info.title);
      
      final videoFile = File('${tempDir.path}/${info.id}_video.tmp');
      final audioFile = File('${tempDir.path}/${info.id}_audio.tmp');
      final outputFile = File('${dir.path}/${safeTitle}_${videoStream.qualityLabel}.mp4');

      // 1. Download Video
      await _downloadStream(videoStream, videoFile, task, part: 0.7); // 70% progress for video
      
      // 2. Download Audio
      await _downloadStream(audioStream, audioFile, task, part: 0.2, offset: 0.7); // 20% for audio

      // 3. Merge using FFmpeg (Final 10%)
      task.quality = "Merging...";
      queue.refresh();

      final command = '-i "${videoFile.path}" -i "${audioFile.path}" -c copy "${outputFile.path}" -y';
      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          task.status = DownloadStatus.completed;
          task.progress = 1.0;
          task.savedFilePath = outputFile.path;
          
          // Add to history
          Get.find<HistoryController>().addToHistory(HistoryItemModel(
            videoId: info.id,
            title: info.title,
            channelName: info.channelName,
            thumbnailUrl: info.thumbnailUrl,
            quality: videoStream.qualityLabel,
            isAudio: false,
            filePath: outputFile.path,
            downloadedAt: DateTime.now(),
          ));
        } else {
          task.status = DownloadStatus.failed;
        }
      });

      // Cleanup temp files
      if (videoFile.existsSync()) videoFile.deleteSync();
      if (audioFile.existsSync()) audioFile.deleteSync();
      
      queue.refresh();
    } catch (e) {
      task.status = DownloadStatus.failed;
      queue.refresh();
    }
  }

  Future<void> _downloadStream(
    StreamInfo streamInfo,
    File file,
    DownloadTaskModel task, {
    double part = 1.0,
    double offset = 0.0,
  }) async {
    final stream = _yt.videos.streamsClient.get(streamInfo);
    final sink = file.openWrite();
    final totalBytes = streamInfo.size.totalBytes;
    var downloaded = 0;

    await for (final chunk in stream) {
      if (task.status == DownloadStatus.cancelled) {
        await sink.close();
        return;
      }
      sink.add(chunk);
      downloaded += chunk.length;
      task.progress = offset + ((downloaded / totalBytes) * part);
      queue.refresh();
    }
    await sink.flush();
    await sink.close();
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted) return true;
      // Android 13+
      final videos = await Permission.videos.request();
      final audio = await Permission.audio.request();
      if (videos.isGranted || audio.isGranted) return true;
      // Fallback for < Android 13
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }

  Future<Directory> _getDownloadDir() async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/SnapTube');
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory('${docs.path}/SnapTube');
    }
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, name.length > 60 ? 60 : name.length);
  }

  @override
  void onClose() {
    _yt.close();
    super.onClose();
  }
}
