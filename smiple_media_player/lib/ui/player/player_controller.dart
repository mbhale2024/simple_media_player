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

  int _loadRequestId = 0;

  bool _detectIsAudio(String path, Metadata? meta) {
    final mime = meta?.mimeType?.toLowerCase();
    if (mime != null && mime.startsWith("audio/")) return true;

    final ext = p.extension(path).toLowerCase();
    const audioExts = {".mp3", ".wav", ".aac", ".m4a", ".flac", ".ogg"};
    return audioExts.contains(ext);
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
    final int requestId = ++_loadRequestId;
    // --- 1. Read metadata (safe) ---
    Metadata? meta;
    try {
      meta = await MetadataRetriever.fromFile(File(path));
    } catch (_) {}

    final isAudioOnly = _detectIsAudio(path, meta);
    final art = meta?.albumArt;

    // --- 2. Create a new controller (DO NOT dispose old one yet) ---
    final oldCtrl = state.controller;
    final newCtrl = VideoPlayerController.file(File(path));

    try {
      await newCtrl.initialize();
    } catch (e) {
      // safe failure: controller init failed
      if (requestId != _loadRequestId) {
        newCtrl.dispose();
        return;
      }
      rethrow;
    }

    // --- 3. CANCEL if another loadFile has been called ---
    if (requestId != _loadRequestId) {
      newCtrl.dispose();
      return;
    }

    // --- 4. Now safe to dispose old controller ---
    oldCtrl?.dispose();

    // --- 5. Set listeners AFTER controller is validated ---
    newCtrl.addListener(() {
      if (requestId != _loadRequestId) return; // Listener from old load calls

      final v = newCtrl.value;

      // Auto-next logic
      if (!v.isPlaying && v.position >= v.duration) {
        final playlist = ref.read(playlistControllerProvider);
        if (playlist.repeatMode == RepeatMode.repeatOne) {
          seekTo(Duration.zero);
          playPause();
        } else {
          playNext();
        }
      }

      // Trigger UI rebuild
      state = state.copyWith();
    });

    newCtrl.setLooping(state.isRepeating);
    newCtrl.setVolume(state.volume);

    // --- 6. Update state with the new controller ---
    state = state.copyWith(
      controller: newCtrl,
      isAudio: isAudioOnly,
      metadata: meta,
      albumArt: art,
      isPlaying: true,
    );

    // --- 7. Start playback after the build ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (requestId == _loadRequestId) {
        newCtrl.play();
      }
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
    setVolume(state.volume);
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
