import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Media Player Home")),
//       body: Center(
//         child: ElevatedButton.icon(
//           icon: const Icon(Icons.folder_open),
//           label: const Text("Pick Media File"),
//           onPressed: () async {
//             final result = await FilePicker.platform.pickFiles(
//               type: FileType.custom,
//               allowedExtensions: [
//                 // Audio
//                 'mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg',
//                 // Video
//                 'mp4', 'mkv', 'mov', 'avi', 'webm',
//               ],
//             );

//             if (result != null && result.files.single.path != null) {
//               final path = result.files.single.path!;
//               context.push("/player?path=$path");
//             }
//           },
//         ),
//       ),
//     );
//   }
// }


// lib/ui/home/home_screen.dart

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smiple_media_player/ui/player/playlist_controller.dart';

// import '../player/player_screen.dart';
// import '../player/playlist_controller.dart';
// import '../player/playlist_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistControllerProvider);
    final controller = ref.read(playlistControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Media Player"),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.custom,
            allowedExtensions: [
              'mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg',
              'mp4', 'mkv', 'mov', 'avi', 'webm',
            ],
          );

          if (result == null) return;

          for (final file in result.files) {
            controller.addItem(file.path!);
          }
        },
      ),

      body: playlist.items.isEmpty
          ? const Center(child: Text("No media added"))
          : ListView.builder(
              itemCount: playlist.items.length,
              itemBuilder: (context, index) {
                final file = playlist.items[index];
                final isCurrent = index == playlist.currentIndex;

                return ListTile(
                  leading: Icon(
                    Icons.play_arrow,
                    color: isCurrent ? Colors.greenAccent : Colors.white,
                  ),
                  title: Text(
                    file.split("/").last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      controller.removeItem(index);
                    },
                  ),
                  onTap: () {
                    controller.jumpTo(index);
                    context.push('/player?path=${Uri.encodeComponent(file)}');
                  },
                );
              },
            ),
    );
  }
}
