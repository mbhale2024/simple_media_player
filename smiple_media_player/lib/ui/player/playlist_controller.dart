// lib/ui/player/playlist_controller.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'playlist_state.dart';

final playlistControllerProvider =
    NotifierProvider<PlaylistController, PlaylistState>(PlaylistController.new);

class PlaylistController extends Notifier<PlaylistState> {
  @override
  PlaylistState build() => const PlaylistState();

  void addItem(String path) {
    final updated = [...state.items, path];
    state = state.copyWith(items: updated);

    // if first item added → start from index 0
    if (updated.length == 1) {
      state = state.copyWith(currentIndex: 0);
    }
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updated = [...state.items]..removeAt(index);

    int newIndex = state.currentIndex;
    if (newIndex >= updated.length) {
      newIndex = updated.isEmpty ? 0 : updated.length - 1;
    }

    state = state.copyWith(items: updated, currentIndex: newIndex);
  }

  void next() {
    if (state.items.isEmpty) return;

    int newIndex = state.currentIndex + 1;
    if (newIndex >= state.items.length) newIndex = 0;

    state = state.copyWith(currentIndex: newIndex);
  }

  void previous() {
    if (state.items.isEmpty) return;

    int newIndex = state.currentIndex - 1;
    if (newIndex < 0) newIndex = state.items.length - 1;

    state = state.copyWith(currentIndex: newIndex);
  }

  void jumpTo(int index) {
    if (index < 0 || index >= state.items.length) return;

    state = state.copyWith(currentIndex: index);
  }

  void reorder(int oldIndex, int newIndex) {
    final items = [...state.items];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    int current = state.currentIndex;

    // Update currentIndex if needed
    if (oldIndex == current)
      current = newIndex;
    else if (oldIndex < current && newIndex >= current)
      current -= 1;
    else if (oldIndex > current && newIndex <= current)
      current += 1;

    state = state.copyWith(items: items, currentIndex: current);
  }
}
