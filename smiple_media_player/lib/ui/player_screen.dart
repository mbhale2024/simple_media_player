import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ----------------------
/// STATE
/// ----------------------
class PlayerState {
  final VideoPlayerController? controller;
  final bool isRepeating;
  final double volume;

  const PlayerState({
    this.controller,
    this.isRepeating = false,
    this.volume = 1.0,
  });

  PlayerState copyWith({
    VideoPlayerController? controller,
    bool? isRepeating,
    double? volume,
  }) {
    return PlayerState(
      controller: controller ?? this.controller,
      isRepeating: isRepeating ?? this.isRepeating,
      volume: volume ?? this.volume,
    );
  }
}

/// ----------------------
/// CONTROLLER (Riverpod 3)
/// ----------------------
class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() {
    // Register a cleanup callback that runs when this provider is disposed.
    // It reads the current state.controller at the time of disposal.
    ref.onDispose(() {
      state.controller?.dispose();
    });

    return const PlayerState();
  }

  Future<void> loadFile(String path) async {
    // Dispose previous controller if exists
    state.controller?.dispose();

    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();

    controller.setLooping(state.isRepeating);
    controller.setVolume(state.volume);

    state = state.copyWith(controller: controller);
    controller.play();
  }

  void playPause() {
    final c = state.controller;
    if (c == null) return;

    c.value.isPlaying ? c.pause() : c.play();
    state = state.copyWith();
  }

  void forward() {
    final c = state.controller;
    if (c == null) return;
    c.seekTo(c.value.position + const Duration(seconds: 10));
  }

  void backward() {
    final c = state.controller;
    if (c == null) return;

    final newPos = c.value.position - const Duration(seconds: 10);
    c.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
  }

  void toggleRepeat() {
    final repeat = !state.isRepeating;
    state.controller?.setLooping(repeat);
    state = state.copyWith(isRepeating: repeat);
  }

  void setVolume(double volume) {
    state.controller?.setVolume(volume);
    state = state.copyWith(volume: volume);
  }
}

/// Provider — Riverpod 3 syntax
final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

/// ----------------------
/// UI SCREEN
/// ----------------------
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

    if (widget.filePath.isNotEmpty) {
      ref.read(playerControllerProvider.notifier).loadFile(widget.filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    final controller = state.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Player"),
        actions: [
          IconButton(onPressed: (){
            controller!.dispose();
            context.pop();
          } , icon: Icon(Icons.close)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: controller == null
                  ? const Text("Loading...")
                  : AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
            ),
          ),

          if (controller != null) _buildControls(state),
        ],
      ),
    );
  }

  Widget _buildControls(PlayerState state) {
    final controller = state.controller!;
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
        VideoProgressIndicator(controller, allowScrubbing: true),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, child) {
                  return Text(formatDuration(controller.value.position));
                },
              ),
              Spacer(),
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
              IconButton(
                icon: Icon(state.isRepeating ? Icons.repeat_on : Icons.repeat),
                onPressed: player.toggleRepeat,
              ),
              Spacer(),
              Text(formatDuration(controller.value.duration)),
            ],
          ),
        ),

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
}
