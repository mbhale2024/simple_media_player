// lib/ui/player/playlist_state.dart
import 'repeat_mode.dart';

class PlaylistState {
  final List<String> items;
  final int currentIndex;
  final RepeatMode repeatMode;

  const PlaylistState({
    this.items = const [],
    this.currentIndex = 0,
    this.repeatMode = RepeatMode.none,
  });

  String? get currentFile =>
      items.isEmpty ? null : items[currentIndex];

  PlaylistState copyWith({
    List<String>? items,
    int? currentIndex,
    RepeatMode? repeatMode,
  }) {
    return PlaylistState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}
