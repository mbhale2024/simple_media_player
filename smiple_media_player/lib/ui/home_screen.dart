import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smiple_media_player/ui/player/playlist_controller.dart';
import 'package:smiple_media_player/ui/player/playlist_state.dart';
import 'package:smiple_media_player/ui/player/repeat_mode.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.repeatAll:
        return Icons.repeat;
      case RepeatMode.repeatOne:
        return Icons.repeat_one;
      default:
        return Icons.repeat_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistControllerProvider);
    final controller = ref.read(playlistControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Playlist"),
        actions: [
          IconButton(
            icon: Icon(
              _repeatIcon(ref.watch(playlistControllerProvider).repeatMode),
            ),
            onPressed: () {
              ref.read(playlistControllerProvider.notifier).toggleRepeatMode();
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.custom,
            allowedExtensions: [
              'mp3',
              'wav',
              'm4a',
              'aac',
              'flac',
              'ogg',
              'mp4',
              'mkv',
              'mov',
              'avi',
              'webm',
            ],
          );

          if (result == null) return;

          bool shouldStartPlayer = false;
          for (var f in result.files) {
            if (f.path != null) {
              final first = controller.addItem(f.path!);
              if (first) shouldStartPlayer = true;
            }
          }
          if (shouldStartPlayer) {
            final firstPath = ref.read(playlistControllerProvider).currentFile!;
            context.push('/player?path=${Uri.encodeComponent(firstPath)}');
          }
        },
      ),

      body: DropTarget(
        onDragDone: (details) {
          final controller = ref.read(playlistControllerProvider.notifier);

          bool shouldStartPlayer = false;

          for (final file in details.files) {
            final path = file.path;
            final firstAdded = controller.addItem(path);
            if (firstAdded) shouldStartPlayer = true;
          }

          // Auto-play if playlist was empty
          if (shouldStartPlayer) {
            final firstTrack = ref
                .read(playlistControllerProvider)
                .currentFile!;
            context.push('/player?path=${Uri.encodeComponent(firstTrack)}');
          }
        },

        child: playlist.items.isEmpty
            ? const Center(child: Text("Drag files here to add to playlist"))
            : _playlistListView(ref, playlist),
      ),
    );
  }

  Widget _playlistListView(WidgetRef ref, PlaylistState playlist) {
    final controller = ref.read(playlistControllerProvider.notifier);

    return ReorderableListView.builder(
      itemCount: playlist.items.length,
      onReorder: controller.reorder,
      itemBuilder: (context, index) {
        final file = playlist.items[index];
        final isCurrent = index == playlist.currentIndex;

        return ListTile(
          key: ValueKey(file),
          leading: const Icon(Icons.drag_handle),
          title: Text(
            file.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent ? Colors.greenAccent : Colors.white,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => controller.removeItem(index),
          ),
          onTap: () {
            controller.jumpTo(index);
            context.push("/player?path=${Uri.encodeComponent(file)}");
          },
        );
      },
    );
  }
}
