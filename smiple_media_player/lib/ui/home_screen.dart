import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Media Player Home")),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text("Pick Media File"),
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: [
                // Audio
                'mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg',
                // Video
                'mp4', 'mkv', 'mov', 'avi', 'webm',
              ],
            );

            if (result != null && result.files.single.path != null) {
              final path = result.files.single.path!;
              context.go("/player?path=$path");
            }
          },
        ),
      ),
    );
  }
}
