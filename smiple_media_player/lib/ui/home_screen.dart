import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("My Playlist", style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.black87,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: "Repeat Mode",
            icon: Icon(
              _repeatIcon(playlist.repeatMode),
              color: Colors.white.withOpacity(0.9),
            ),
            onPressed: controller.toggleRepeatMode,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.greenAccent.shade400,
        icon: const Icon(Icons.add),
        label: const Text("Add Media"),
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
            final path = ref.read(playlistControllerProvider).currentFile!;
            if(context.mounted) context.push('/player?path=${Uri.encodeComponent(path)}');
          }
        },
      ),

      body: SafeArea(
        child: DropTarget(
          onDragDone: (details) {
            bool shouldStartPlayer = false;

            for (final file in details.files) {
              final addedFirst = controller.addItem(file.path);
              if (addedFirst) shouldStartPlayer = true;
            }

            if (shouldStartPlayer) {
              final first = ref.read(playlistControllerProvider).currentFile!;
              context.push('/player?path=${Uri.encodeComponent(first)}');
            }
          },
          child: playlist.items.isEmpty
              ? _emptyDragTarget()
              : _playlistView(context, ref, playlist),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // EMPTY STATE
  // -------------------------------------------------------
  Widget _emptyDragTarget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              "Drag & Drop audio/video files here\nor click + to add to playlist",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // RESPONSIVE PLAYLIST
  // -------------------------------------------------------
  Widget _playlistView(
    BuildContext context,
    WidgetRef ref,
    PlaylistState playlist,
  ) {
    final controller = ref.read(playlistControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.black26,
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: playlist.items.length,
            onReorder: controller.reorder,
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 8,
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final file = playlist.items[index];
              final isCurrent = index == playlist.currentIndex;

              return _playlistTile(
                key: ValueKey(index),
                index: index,
                file: file,
                isActive: isCurrent,
                onTap: () {
                  debugPrint("Tapping on $file");
                  controller.jumpTo(index);
                  context.push('/player?path=${Uri.encodeComponent(file)}');
                },
                onDelete: () => controller.removeItem(index),
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // PLAYLIST TILE
  // -------------------------------------------------------
  Widget _playlistTile({
    required Key key,
    required int index,
    required String file,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.withOpacity(0.15) : Colors.black38,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Colors.greenAccent.shade400, width: 1.4)
              : Border.all(color: Colors.white12),
        ),

        child: Row(
          children: [
            // DRAG HANDLE
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.drag_indicator, color: Colors.white70),
              ),
            ),

            const SizedBox(width: 12),

            // FILENAME
            Expanded(
              child: Text(
                file.split('/').last,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.greenAccent : Colors.white,
                ),
              ),
            ),

            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
