import 'dart:typed_data';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:video_player/video_player.dart';

class PlayerState {
  final VideoPlayerController? controller;
  final bool isPlaying;
  final bool isAudio;
  final bool isRepeating;
  final double volume;
  final bool showControls;
  final bool showVolumeSlider;
  final bool isPointerInsideControls;
  final Metadata? metadata;
  final Uint8List? albumArt;
  final Map<int, Uint8List> thumbnails;

  const PlayerState({
    this.controller,
    this.isPlaying = false,
    this.isPointerInsideControls = false,
    this.showControls = false,
    this.showVolumeSlider = false,
    this.isAudio = false,
    this.isRepeating = false,
    this.volume = 1.0,
    this.metadata,
    this.albumArt,
    this.thumbnails = const {},
  });

  PlayerState copyWith({
    VideoPlayerController? controller,
    bool? isPointerInsideControls,
    bool? showControls,
    bool? isPlaying,
    bool? isAudio,
    bool? isRepeating,
    bool? showVolumeSlider,
    double? volume,
    Metadata? metadata,
    Uint8List? albumArt,
    Map<int, Uint8List>? thumbnails,
  }) {
    return PlayerState(
      controller: controller ?? this.controller,
      isPointerInsideControls:
          isPointerInsideControls ?? this.isPointerInsideControls,
      showControls: showControls ?? this.showControls,
      showVolumeSlider: showVolumeSlider ?? this.showVolumeSlider,
      isPlaying: isPlaying ?? this.isPlaying,
      isAudio: isAudio ?? this.isAudio,
      isRepeating: isRepeating ?? this.isRepeating,
      volume: volume ?? this.volume,
      metadata: metadata ?? this.metadata,
      albumArt: albumArt ?? this.albumArt,
      thumbnails: thumbnails ?? this.thumbnails,
    );
  }

  /// Helper to check if controller is non-null & initialized
  bool get hasActiveController {
    final c = controller;
    if (c == null) return false;
    return c.value.isInitialized;
  }
}
