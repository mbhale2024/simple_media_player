import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path/path.dart' as p;

import 'player_state.dart';

class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    ref.onDispose(() {
      state.controller?.dispose();
    });
    return const PlayerState();
  }

  Future<void> loadFile(String path) async {
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
      const audioExts = {
        ".mp3", ".wav", ".aac", ".m4a", ".flac", ".ogg"
      };
      if (audioExts.contains(ext)) isAudioOnly = true;
    }

    final art = meta?.albumArt;

    // Dispose previous controller
    state.controller?.dispose();

    final ctrl = VideoPlayerController.file(File(path));
    await ctrl.initialize();

    // Audio fix: Add continuous listener for duration updates
    ctrl.addListener(() {
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
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
