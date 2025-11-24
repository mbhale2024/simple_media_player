// lib/ui/player/player_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smiple_media_player/ui/player/widgets/bottom_control_panel.dart';
import 'package:smiple_media_player/ui/player/widgets/desktop_keyboard_shortcuts.dart';
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
    final notifier = ref.read(playerControllerProvider.notifier);

    final controller = state.controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DesktopKeyboardShortcuts(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: MouseRegion(
                onHover: (_) => notifier.onUserActive(),
                child: Stack(
                  children: [
                    state.isAudio ? _audioUI(state) : _videoUI(state),
                    MouseRegion(
                      onEnter: (_) => notifier.onControlsEnter(),
                      onExit: (_) => notifier.onControlsExit(),
                      child: AnimatedOpacity(
                        opacity: state.showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildTopBar(controller, context),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: MouseRegion(
                        onEnter: (_) => notifier.onControlsEnter(),
                        onExit: (_) => notifier.onControlsExit(),
                        child: AnimatedOpacity(
                          opacity: state.showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: BottomControlPanel(
                            notifier: notifier,
                            state: state,
                            filePath: widget.filePath,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(VideoPlayerController controller, BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.transparent, Colors.black],
        ),
      ),
      child: Row(
        children: [
          Spacer(),
          IconButton(
            onPressed: () async {
              await controller.pause();
              if (context.mounted) {
                context.pop();
              }
            },
            icon: Icon(LucideIcons.x, color: Colors.white),
          ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (state.albumArt != null)
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: MemoryImage(state.albumArt!),
                  fit: BoxFit.cover,
                ),
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
}
