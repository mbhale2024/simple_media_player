import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smiple_media_player/ui/player/playlist_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistControllerProvider);
    final controller = ref.read(playlistControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Playlist")),

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

          for (var f in result.files) {
            if (f.path != null) controller.addItem(f.path!);
          }
        },
      ),

      body: playlist.items.isEmpty
          ? const Center(child: Text("No media added"))
          : ReorderableListView.builder(
              itemCount: playlist.items.length,
              onReorder: (oldIndex, newIndex) {
                controller.reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final file = playlist.items[index];
                final isCurrent = index == playlist.currentIndex;

                return ListTile(
                  key: ValueKey(file),
                  title: Text(
                    file.split("/").last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? Colors.greenAccent : Colors.white,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  leading: Icon(Icons.drag_handle, color: Colors.grey.shade300),
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
            ),
    );
  }
}
