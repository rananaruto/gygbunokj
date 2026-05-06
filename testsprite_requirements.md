# SnapTube Testing Requirements

## Project Overview
SnapTube is a Flutter-based YouTube video and audio downloader. It uses `youtube_explode_dart` for fetching streams and `ffmpeg_kit_flutter` for merging high-resolution DASH streams.

## Core Functionalities to Test

### 1. URL Analysis
- **Input**: Paste a valid YouTube URL (Video, Shorts, or Playlist).
- **Expectation**: App should show video thumbnail, title, channel name, and duration.
- **Error Handling**: Test with invalid URLs or restricted videos (Age-restricted/Private).

### 2. Quality Selection
- **Muxed Streams**: Test downloading 360p or 720p (standard).
- **HQ Merging (PRO)**: Test downloading 1080p, 4K, or 8K. 
    - *Note*: This triggers FFmpeg merging of separate video and audio tracks.
- **Audio Only**: Test downloading MP3 320kbps.

### 3. Download Process
- **Queue Management**: Verify that multiple downloads can be queued.
- **Progress Tracking**: Real-time progress bar, speed (MB/s), and ETA should update.
- **Cancellation**: Verify that canceling a download stops the stream and deletes the partial file.

### 4. Storage & History
- **File Saving**: Verify files are saved to `Downloads/SnapTube`.
- **History Persistence**: Ensure downloaded items appear in the "History" tab with the correct metadata.

### 5. UI/UX (Dark Neon Theme)
- **Navigation**: Verify switching between Home, Downloads, and History tabs.
- **Responsiveness**: Ensure the app handles long titles and various screen sizes.

## Technical Details for TestSprite
- **Framework**: Flutter (Dart)
- **Storage**: Requires `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` (or Scoped Storage on Android 13+).
- **Backgrounding**: Uses Foreground Service for downloads.
