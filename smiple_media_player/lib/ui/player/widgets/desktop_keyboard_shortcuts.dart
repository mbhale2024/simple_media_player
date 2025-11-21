import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../player/player_controller.dart';

/// ------------------------------------------------------------
/// INTENTS
/// ------------------------------------------------------------
class PlayPauseIntent extends Intent {}

class ForwardIntent extends Intent {}

class BackwardIntent extends Intent {}

class BigForwardIntent extends Intent {}

class BigBackwardIntent extends Intent {}

class NextTrackIntent extends Intent {}

class PreviousTrackIntent extends Intent {}

class MuteIntent extends Intent {}

class VolumeUpIntent extends Intent {}

class VolumeDownIntent extends Intent {}

class FullScreenIntent extends Intent {}

class ExitFullScreenIntent extends Intent {}

/// ------------------------------------------------------------
/// WIDGET: DesktopKeyboardShortcuts
/// ------------------------------------------------------------
class DesktopKeyboardShortcuts extends ConsumerStatefulWidget {
  final Widget child;

  const DesktopKeyboardShortcuts({super.key, required this.child});

  @override
  ConsumerState<DesktopKeyboardShortcuts> createState() =>
      _DesktopKeyboardShortcutsState();
}

class _DesktopKeyboardShortcutsState
    extends ConsumerState<DesktopKeyboardShortcuts> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// ------------------------------------------------------------
  /// FULLSCREEN HELPERS (with delayed focus restore)
  /// ------------------------------------------------------------
  Future<void> _enterFullScreen() async {
    await windowManager.setFullScreen(true);

    Future.microtask(() {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _exitFullScreen() async {
    await windowManager.setFullScreen(false);

    Future.microtask(() {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(playerControllerProvider.notifier);

    return Shortcuts(
      shortcuts: {
        // Playback
        LogicalKeySet(LogicalKeyboardKey.space): PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): BackwardIntent(),

        // Big seek (Shift + arrow)
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight):
            BigForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft):
            BigBackwardIntent(),

        // Playlist navigation
        LogicalKeySet(LogicalKeyboardKey.arrowUp): NextTrackIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): PreviousTrackIntent(),

        // Volume & mute
        LogicalKeySet(LogicalKeyboardKey.keyM): MuteIntent(),
        LogicalKeySet(LogicalKeyboardKey.add): VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.minus): VolumeDownIntent(),

        // Fullscreen
        LogicalKeySet(LogicalKeyboardKey.keyF): FullScreenIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): ExitFullScreenIntent(),
      },
      child: Actions(
        actions: {
          PlayPauseIntent: CallbackAction(
            onInvoke: (_) {
              controller.playPause();
              return null;
            },
          ),
          ForwardIntent: CallbackAction(
            onInvoke: (_) {
              controller.forward();
              return null;
            },
          ),
          BackwardIntent: CallbackAction(
            onInvoke: (_) {
              controller.backward();
              return null;
            },
          ),
          // BigForwardIntent: CallbackAction(onInvoke: (_) {
          //   controller.seekRelative(const Duration(seconds: 60));
          //   return null;
          // }),
          // BigBackwardIntent: CallbackAction(onInvoke: (_) {
          //   controller.seekRelative(const Duration(seconds: -60));
          //   return null;
          // }),
          NextTrackIntent: CallbackAction(
            onInvoke: (_) {
              controller.playNext();
              return null;
            },
          ),
          PreviousTrackIntent: CallbackAction(
            onInvoke: (_) {
              controller.playPrevious();
              return null;
            },
          ),
          MuteIntent: CallbackAction(
            onInvoke: (_) {
              final current = ref.read(playerControllerProvider).volume;
              controller.setVolume(current > 0 ? 0 : 1.0);
              return null;
            },
          ),
          VolumeUpIntent: CallbackAction(
            onInvoke: (_) {
              final v = ref.read(playerControllerProvider).volume;
              controller.setVolume((v + 0.1).clamp(0, 1.0));
              return null;
            },
          ),
          VolumeDownIntent: CallbackAction(
            onInvoke: (_) {
              final v = ref.read(playerControllerProvider).volume;
              controller.setVolume((v - 0.1).clamp(0, 1.0));
              return null;
            },
          ),
          FullScreenIntent: CallbackAction(
            onInvoke: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                _enterFullScreen();
              });
              return null;
            },
          ),

          ExitFullScreenIntent: CallbackAction(
            onInvoke: (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                _exitFullScreen();
              });
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          canRequestFocus: true, // 👈 be explicit
          focusNode: _focusNode,
          child: widget.child,
        ),
      ),
    );
  }
}
