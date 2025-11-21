import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smiple_media_player/ui/player/playlist_controller.dart';
import 'package:smiple_media_player/ui/player/repeat_mode.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

import 'player_state.dart';

class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    ref.onDispose(() {
      state.controller?.dispose();
    });
    return const PlayerState();
  }

  bool _isNetwork(String path) {
    return path.startsWith("http://") || path.startsWith("https://");
  }

  Future<void> loadNetwork(String url) async {
    state.controller?.dispose();
    bool isAudio =
        url.toLowerCase().endsWith(".mp3") ||
        url.toLowerCase().endsWith(".wav") ||
        url.toLowerCase().endsWith(".aac") ||
        url.toLowerCase().endsWith(".m4a") ||
        url.toLowerCase().endsWith(".ogg");

    VideoPlayerController? ctrl;
    if (!isAudio) {
      try {
        ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
        await ctrl.initialize();
        ctrl.setLooping(state.isRepeating);
        ctrl.setVolume(state.volume);
      } catch (_) {
        isAudio = true;
        ctrl = null;
      }
    }

    state = state.copyWith(
      controller: ctrl,
      isAudio: isAudio,
      albumArt: null,
      metadata: null,
    );

    if (ctrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctrl?.play());
    }
  }

  Future<void> load(String path) async {
    if (_isNetwork(path)) {
      await loadNetwork(path);
    } else {
      await loadLocal(path);
    }
  }

  Future<void> loadLocal(String path) async {
    Metadata? meta;
    try {
      meta = await MetadataRetriever.fromFile(File(path));
    } catch (_) {}

    bool isAudioOnly = false;

    // Detect based on mime
    final mime = meta?.mimeType?.toLowerCase();
    if (mime != null) {
      if (mime.startsWith("audio/")) isAudioOnly = true;
    } else {
      final ext = p.extension(path).toLowerCase();
      const audioExts = {".mp3", ".wav", ".aac", ".m4a", ".flac", ".ogg"};
      if (audioExts.contains(ext)) isAudioOnly = true;
    }

    final art = meta?.albumArt;

    // Dispose previous controller
    state.controller?.dispose();

    final ctrl = VideoPlayerController.file(File(path));
    await ctrl.initialize();

    // Audio fix: Add continuous listener for duration updates
    ctrl.addListener(() {
      // Auto-next logic
      if (ctrl.value.position >= ctrl.value.duration && !ctrl.value.isPlaying) {
        final playlist = ref.read(playlistControllerProvider);
        // final playlistCtrl = ref.read(playlistControllerProvider.notifier);

        if (playlist.repeatMode == RepeatMode.repeatOne) {
          // replay same track
          seekTo(Duration.zero);
          playPause();
        } else {
          // go to next track
          playNext();
          // final nextFile = playlistCtrl.state.currentFile;
          // if (nextFile != null) {
          //   loadFile(nextFile);
          // }
        }
      }

      state = state.copyWith();
    });

    ctrl.setLooping(state.isRepeating);
    ctrl.setVolume(state.volume);

    state = state.copyWith(
      controller: ctrl,
      isAudio: isAudioOnly,
      metadata: meta,
      albumArt: art,
      isPlaying: true,
    );

    // Play after build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.play();
    });
  }

  void playPause() {
    final c = state.controller;
    if (c == null) return;

    if (c.value.isPlaying) {
      c.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      c.play();
      state = state.copyWith(isPlaying: true);
    }
  }

  void seekTo(Duration d) {
    state.controller?.seekTo(d);
  }

  void forward() {
    final c = state.controller;
    if (c == null) return;
    c.seekTo(c.value.position + const Duration(seconds: 10));
  }

  void backward() {
    final c = state.controller;
    if (c == null) return;
    c.seekTo(c.value.position - const Duration(seconds: 10));
  }

  void toggleRepeat() {
    final val = !state.isRepeating;
    state.controller?.setLooping(val);
    state = state.copyWith(isRepeating: val);
  }

  void setVolume(double v) {
    state.controller?.setVolume(v);
    state = state.copyWith(volume: v);
  }

  void playNext() {
    final playlistCtrl = ref.read(playlistControllerProvider.notifier);
    playlistCtrl.next();

    final file = playlistCtrl.state.currentFile;
    if (file != null) loadLocal(file);
  }

  void playPrevious() {
    final playlistCtrl = ref.read(playlistControllerProvider.notifier);
    playlistCtrl.previous();

    final file = playlistCtrl.state.currentFile;
    if (file != null) loadLocal(file);
  }

  void showVolumeSlider(bool value) {
    state = state.copyWith(showVolumeSlider: value);
  }

  void toggleMute() {
    if (state.volume == 0) {
      // unmute -> restore last volume
      state = state.copyWith(volume: 1);
    } else {
      state = state.copyWith(volume: 0);
    }
  }

  void toggleFullscreen() async {
    bool isFull = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFull);
  }

  Timer? _hideTimer;

  void onHover() {
    if (!state.showControls) {
      state = state.copyWith(showControls: true);
    }

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      state = state.copyWith(showControls: false);
    });
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
