// lib/ui/player/playlist_state.dart

class PlaylistState {
  final List<String> items; // file paths
  final int currentIndex;

  const PlaylistState({
    this.items = const [],
    this.currentIndex = 0,
  });

  String? get currentFile =>
      (items.isEmpty || currentIndex >= items.length)
          ? null
          : items[currentIndex];

  PlaylistState copyWith({
    List<String>? items,
    int? currentIndex,
  }) {
    return PlaylistState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
