// lib/ui/player/playlist_controller.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smiple_media_player/ui/player/playlist_state.dart';
import 'package:smiple_media_player/ui/player/repeat_mode.dart';

/// ------------------------------------------------------------
/// PROVIDER
/// ------------------------------------------------------------
final playlistControllerProvider =
    NotifierProvider<PlaylistController, PlaylistState>(PlaylistController.new);

/// ------------------------------------------------------------
/// CONTROLLER
/// ------------------------------------------------------------
class PlaylistController extends Notifier<PlaylistState> {
  @override
  PlaylistState build() => const PlaylistState();

  /// Add a media file to playlist
  /// Returns TRUE if this was the **first media** (→ auto play)
  bool addItem(String path) {
    final updated = [...state.items, path];
    final wasEmpty = state.items.isEmpty;

    state = state.copyWith(
      items: updated,
      currentIndex: wasEmpty ? 0 : state.currentIndex,
    );

    return wasEmpty;
  }

  /// Remove a track and fix indices
  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;

    final updated = [...state.items]..removeAt(index);

    int newIndex = state.currentIndex;

    if (updated.isEmpty) {
      newIndex = 0;
    } else if (index < newIndex) {
      newIndex -= 1;
    } else if (index == newIndex) {
      if (newIndex >= updated.length) {
        newIndex = updated.length - 1;
      }
    }

    state = state.copyWith(items: updated, currentIndex: newIndex);
  }

  /// Jump to specific track
  void jumpTo(int index) {
    if (index < 0 || index >= state.items.length) return;
    state = state.copyWith(currentIndex: index);
  }

  /// Next track (with repeat rules)
  void next() {
    if (state.items.isEmpty) return;

    int newIndex = state.currentIndex + 1;

    switch (state.repeatMode) {
      case RepeatMode.repeatOne:
        newIndex = state.currentIndex;
        break;

      case RepeatMode.repeatAll:
        if (newIndex >= state.items.length) newIndex = 0;
        break;

      case RepeatMode.none:
        if (newIndex >= state.items.length) {
          newIndex = state.items.length - 1;
        }
        break;
    }

    state = state.copyWith(currentIndex: newIndex);
  }

  /// Previous track
  void previous() {
    if (state.items.isEmpty) return;

    int newIndex = state.currentIndex - 1;
    if (newIndex < 0) newIndex = state.items.length - 1;

    state = state.copyWith(currentIndex: newIndex);
  }

  /// Reorder the playlist with full index integrity
  void reorder(int oldIndex, int newIndex) {
    final items = [...state.items];

    if (newIndex > oldIndex) newIndex--;

    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    int cur = state.currentIndex;

    if (cur == oldIndex) {
      cur = newIndex;
    } else if (cur > oldIndex && cur <= newIndex) {
      cur -= 1;
    } else if (cur < oldIndex && cur >= newIndex) {
      cur += 1;
    }

    state = state.copyWith(items: items, currentIndex: cur);
  }

  /// Toggle repeat mode between none → all → one
  void toggleRepeatMode() {
    final next = {
      RepeatMode.none: RepeatMode.repeatAll,
      RepeatMode.repeatAll: RepeatMode.repeatOne,
      RepeatMode.repeatOne: RepeatMode.none,
    }[state.repeatMode]!;

    state = state.copyWith(repeatMode: next);
  }
}
