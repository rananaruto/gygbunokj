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

  // ── Public API ────────────────────────────────────────

  /// Start a video download at a given muxed stream quality.
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
    await _runDownload(task, info, streamInfo: streamInfo);
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
    await _runDownload(task, info, audioStream: audioStream);
  }

  /// Cancel an active download
  void cancelDownload(DownloadTaskModel task) {
    task.status = DownloadStatus.cancelled;
    queue.refresh();
  }

  // ── Internal ──────────────────────────────────────────

  Future<void> _runDownload(
    DownloadTaskModel task,
    VideoInfoModel info, {
    MuxedStreamInfo? streamInfo,
    AudioOnlyStreamInfo? audioStream,
  }) async {
    // Check / request storage permission
    if (!await _requestStoragePermission()) {
      task.status = DownloadStatus.failed;
      queue.refresh();
      Get.snackbar('Permission Denied', 'Storage permission is required to download files.',
          snackPosition: SnackPosition.BOTTOM);
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

      // Get the stream
      final videoStream = task.isAudio
          ? _yt.videos.streamsClient.get(audioStream!)
          : _yt.videos.streamsClient.get(streamInfo!);

      final totalBytes = task.isAudio ? audioStream!.size.totalBytes : streamInfo!.size.totalBytes;

      final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
      var downloaded = 0;
      var lastTime = DateTime.now();
      var lastBytes = 0;

      await for (final chunk in videoStream) {
        // Respect cancellation
        if (task.status == DownloadStatus.cancelled) {
          await sink.close();
          if (file.existsSync()) file.deleteSync();
          return;
        }

        sink.add(chunk);
        downloaded += chunk.length;

        // Update progress
        task.progress = downloaded / totalBytes;

        // Calculate speed & ETA every 500ms
        final now = DateTime.now();
        final elapsed = now.difference(lastTime).inMilliseconds;
        if (elapsed >= 500) {
          final bytesDelta = downloaded - lastBytes;
          task.speedMbps = (bytesDelta / elapsed * 1000) / (1024 * 1024);
          final remaining = totalBytes - downloaded;
          task.etaSeconds = task.speedMbps > 0
              ? (remaining / (task.speedMbps * 1024 * 1024)).round()
              : 0;
          lastTime = now;
          lastBytes = downloaded;
        }
        queue.refresh();
      }

      await sink.flush();
      await sink.close();

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task.savedFilePath = file.path;
      queue.refresh();

      // Persist to history
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

      Get.snackbar(
        '✅ Download Complete',
        '${info.title} saved to Downloads/SnapTube',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Download error: $e');
      task.status = DownloadStatus.failed;
      queue.refresh();
      Get.snackbar('Download Failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
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
