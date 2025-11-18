// // lib/ui/player_screen.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:video_player/video_player.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';

// import 'dart:typed_data';

// import 'package:flutter_media_metadata/flutter_media_metadata.dart';
// import 'package:path/path.dart' as p;

// /// ------------------------------------------------------
// /// PLAYER STATE
// /// ------------------------------------------------------
// class PlayerState {
//   final VideoPlayerController? controller;
//   final bool isRepeating;
//   final double volume;

//   final bool isAudio;
//   final Metadata? metadata;
//   final Uint8List? albumArt;

//   const PlayerState({
//     this.controller,
//     this.isRepeating = false,
//     this.volume = 1.0,
//     this.isAudio = false,
//     this.metadata,
//     this.albumArt,
//   });

//   PlayerState copyWith({
//     VideoPlayerController? controller,
//     bool? isRepeating,
//     double? volume,
//     bool? isAudio,
//     Metadata? metadata,
//     Uint8List? albumArt,
//   }) {
//     return PlayerState(
//       controller: controller ?? this.controller,
//       isRepeating: isRepeating ?? this.isRepeating,
//       volume: volume ?? this.volume,
//       isAudio: isAudio ?? this.isAudio,
//       metadata: metadata ?? this.metadata,
//       albumArt: albumArt ?? this.albumArt,
//     );
//   }
// }

// /// ------------------------------------------------------
// /// PLAYER CONTROLLER  (Riverpod 3 Notifier)
// /// ------------------------------------------------------
// class PlayerController extends Notifier<PlayerState> {
//   @override
//   PlayerState build() {
//     ref.onDispose(() {
//       state.controller?.dispose();
//     });
//     return const PlayerState();
//   }

//   /// Load media file, detect audio/video, extract metadata, load video if needed
//   Future<void> loadFile(String path) async {
//     Metadata? meta;
//     try {
//       meta = await MetadataRetriever.fromFile(File(path));
//     } catch (_) {
//       meta = null;
//     }

//     bool isAudioOnly = false;
//     final mime = meta?.mimeType?.toLowerCase();

//     if (mime != null) {
//       isAudioOnly = mime.startsWith("audio/");
//     } else {
//       final ext = p.extension(path).toLowerCase();
//       const audioExts = {
//         ".mp3",
//         ".wav",
//         ".m4a",
//         ".aac",
//         ".flac",
//         ".ogg",
//         ".opus",
//         ".wma",
//       };
//       if (audioExts.contains(ext)) isAudioOnly = true;
//     }

//     final art = meta?.albumArt;

//     state.controller?.dispose();

//     // ALWAYS CREATE a VideoPlayerController (audio OR video)
//     VideoPlayerController? videoCtrl;

//     try {
//       final ctrl = VideoPlayerController.file(File(path));
//       await ctrl.initialize();

//       // ADD THIS LISTENER (IMPORTANT FOR AUDIO)
//       ctrl.addListener(() {
//         // duration & position updates come through this
//         state = state.copyWith();
//       });

//       ctrl.setLooping(state.isRepeating);
//       ctrl.setVolume(state.volume);

//       videoCtrl = ctrl;
//     } catch (_) {
//       videoCtrl = null;
//     }

//     state = state.copyWith(
//       controller: videoCtrl,
//       isAudio: isAudioOnly,
//       metadata: meta,
//       albumArt: art,
//     );

//     if (videoCtrl != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         videoCtrl!.play();
//       });
//     }
//   }

//   void playPause() {
//     final c = state.controller;
//     if (c == null) return;
//     c.value.isPlaying ? c.pause() : c.play();
//     state = state.copyWith();
//   }

//   void forward() {
//     final c = state.controller;
//     if (c == null) return;
//     c.seekTo(c.value.position + const Duration(seconds: 10));
//   }

//   void backward() {
//     final c = state.controller;
//     if (c == null) return;
//     final pos = c.value.position - const Duration(seconds: 10);
//     c.seekTo(pos < Duration.zero ? Duration.zero : pos);
//   }

//   void toggleRepeat() {
//     final r = !state.isRepeating;
//     state.controller?.setLooping(r);
//     state = state.copyWith(isRepeating: r);
//   }

//   void setVolume(double v) {
//     state.controller?.setVolume(v);
//     state = state.copyWith(volume: v);
//   }
// }

// /// Riverpod provider
// final playerControllerProvider =
//     NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

// /// ------------------------------------------------------
// /// PLAYER SCREEN UI
// /// ------------------------------------------------------
// class PlayerScreen extends ConsumerStatefulWidget {
//   final String filePath;
//   const PlayerScreen({super.key, required this.filePath});

//   @override
//   ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
// }

// class _PlayerScreenState extends ConsumerState<PlayerScreen> {
//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(playerControllerProvider.notifier).loadFile(widget.filePath);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(playerControllerProvider);
//     final meta = state.metadata;

//     final title = meta?.trackName ?? p.basename(widget.filePath);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         actions: [
//           IconButton(onPressed: () => context.pop(), icon: Icon(Icons.close)),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Center(
//               child: state.isAudio
//                   ? _buildAudioArtwork(state)
//                   : (state.controller == null
//                         ? const CircularProgressIndicator()
//                         : AspectRatio(
//                             aspectRatio: state.controller!.value.aspectRatio,
//                             child: VideoPlayer(state.controller!),
//                           )),
//             ),
//           ),
//           if (state.controller != null || state.isAudio) _buildControls(state),
//         ],
//       ),
//     );
//   }

//   Widget _buildAudioArtwork(PlayerState state) {
//     final meta = state.metadata;

//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           width: 220,
//           height: 220,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             color: Colors.grey.shade900,
//             image: state.albumArt != null
//                 ? DecorationImage(
//                     image: MemoryImage(state.albumArt!),
//                     fit: BoxFit.cover,
//                   )
//                 : null,
//           ),
//           child: state.albumArt == null
//               ? const Icon(Icons.music_note, size: 80)
//               : null,
//         ),
//         const SizedBox(height: 20),
//         Text(
//           meta?.trackName ?? "Unknown title",
//           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           meta?.trackArtistNames?.join(", ") ?? "Unknown artist",
//           style: const TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       ],
//     );
//   }

// Widget _buildControls(PlayerState state) {
//   final controller = state.controller;
//   final player = ref.read(playerControllerProvider.notifier);

//   // Format duration to MM:SS
//   String formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$minutes:$seconds';
//   }

//   return Column(
//     children: [
//       // Only show scrubber for video
//       if (!state.isAudio && controller != null)
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: VideoProgressIndicator(controller, allowScrubbing: true),
//         ),
//       const SizedBox(height: 10),

//       Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ValueListenableBuilder(
//               valueListenable: controller!,
//               builder: (context, value, child) {
//                 return Text(formatDuration(controller.value.position));
//               },
//             ),
//             Spacer(),
//             IconButton(
//               icon: const Icon(Icons.replay_10),
//               onPressed: player.backward,
//             ),
//             IconButton(
//               icon: Icon(
//                 controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//               ),
//               onPressed: player.playPause,
//               iconSize: 40,
//             ),
//             IconButton(
//               icon: const Icon(Icons.forward_10),
//               onPressed: player.forward,
//             ),
//             IconButton(
//               icon: Icon(state.isRepeating ? Icons.repeat_on : Icons.repeat),
//               onPressed: player.toggleRepeat,
//             ),
//             Spacer(),
//             Text(formatDuration(controller.value.duration)),
//           ],
//         ),
//       ),

//       // Volume
//       Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.volume_down),
//           SizedBox(
//             width: 200,
//             child: Slider(
//               value: state.volume,
//               min: 0,
//               max: 1,
//               onChanged: player.setVolume,
//             ),
//           ),
//           const Icon(Icons.volume_up),
//         ],
//       ),

//       const SizedBox(height: 10),
//     ],
//   );
// }
// }

// lib/ui/player/player_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import 'player_controller.dart';
import 'player_state.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const PlayerScreen({super.key, required this.filePath});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerControllerProvider.notifier).loadFile(widget.filePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);

    final controller = state.controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = state.metadata?.trackName ?? p.basename(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: () => context.pop(), icon: Icon(Icons.close)),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: state.isAudio ? _audioUI(state) : _videoUI(state)),
          _controls(state),
        ],
      ),
    );
  }

  Widget _videoUI(PlayerState state) {
    final ctrl = state.controller!;
    return Center(
      child: AspectRatio(
        aspectRatio: ctrl.value.aspectRatio,
        child: VideoPlayer(ctrl),
      ),
    );
  }

  Widget _audioUI(PlayerState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.albumArt != null)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: MemoryImage(state.albumArt!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          const Icon(Icons.audiotrack, size: 120),

        const SizedBox(height: 20),
        Text(
          state.metadata?.trackName ?? "Unknown",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(state.metadata?.trackArtistNames?.join(", ") ?? ""),
      ],
    );
  }

  Widget _buildControls(PlayerState state) {
    final controller = state.controller;
    final player = ref.read(playerControllerProvider.notifier);

    // Format duration to MM:SS
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: controller!,
                builder: (context, value, child) {
                  return Text(formatDuration(controller.value.position));
                },
              ),
              Spacer(),
              // Previous track
              IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 40,
                onPressed: () {
                  ref.read(playerControllerProvider.notifier).playPrevious();
                },
              ),
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: player.backward,
              ),
              IconButton(
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: player.playPause,
                iconSize: 40,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: player.forward,
              ),
              // Next track
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 40,
                onPressed: () {
                  ref.read(playerControllerProvider.notifier).playNext();
                },
              ),
              // IconButton(
              //   icon: Icon(state.isRepeating ? Icons.repeat_on : Icons.repeat),
              //   onPressed: player.toggleRepeat,
              // ),
              Spacer(),
              Text(formatDuration(controller.value.duration)),
            ],
          ),
        ),

        // Volume
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volume_down),
            SizedBox(
              width: 200,
              child: Slider(
                value: state.volume,
                min: 0,
                max: 1,
                onChanged: player.setVolume,
              ),
            ),
            const Icon(Icons.volume_up),
          ],
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _controls(PlayerState state) {
    final ctrl = state.controller!;
    final notifier = ref.read(playerControllerProvider.notifier);

    final duration = ctrl.value.duration;
    final position = ctrl.value.position;

    return Column(
      children: [
        // seek for audio & video
        Slider(
          min: 0,
          max: duration.inMilliseconds.toDouble(),
          value: position.inMilliseconds
              .clamp(0, duration.inMilliseconds)
              .toDouble(),
          onChanged: (v) => notifier.seekTo(Duration(milliseconds: v.toInt())),
        ),

        _buildControls(state),
      ],
    );
  }
}
