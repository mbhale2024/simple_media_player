import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smiple_media_player/constants/app_textstyles.dart';
import 'package:smiple_media_player/ui/player/player_controller.dart';
import 'package:smiple_media_player/ui/player/player_state.dart';
import 'package:path/path.dart';

class BottomControlPanel extends StatelessWidget {
  final PlayerState state;
  final PlayerController notifier;
  final String filePath;

  const BottomControlPanel({
    super.key,
    required this.notifier,
    required this.state,
    required this.filePath,
  });

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = state.controller!;
    final duration = ctrl.value.duration;
    final position = ctrl.value.position;
    final countdown =
        "${formatDuration(position)} / ${formatDuration(duration)}";
    final title = state.metadata?.trackName ?? basename(filePath);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextstyles.title),
                Text(countdown, style: AppTextstyles.subtitle),
              ],
            ),
            Slider(
              padding: EdgeInsets.zero,
              min: 0,
              max: duration.inMilliseconds.toDouble(),
              value: position.inMilliseconds
                  .clamp(0, duration.inMilliseconds)
                  .toDouble(),
              onChanged: (v) =>
                  notifier.seekTo(Duration(milliseconds: v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildPlayControls(), _buildSideControls(context)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayControls() {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(
            state.isPlaying ? LucideIcons.pause : LucideIcons.circlePlay,
          ),
          onPressed: notifier.playPause,
          color: Colors.white,
          iconSize: 34,
        ),

        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(LucideIcons.rotateCcw),
          onPressed: notifier.backward,
          color: Colors.white,
          iconSize: 34,
        ),

        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(LucideIcons.rotateCw),
          onPressed: notifier.forward,
          color: Colors.white,
          iconSize: 34,
        ),
      ],
    );
  }

  Widget _buildSideControls(BuildContext context) {
    return Row(
      children: [
        _buildVolumeButton(context),
        IconButton(
          icon: const Icon(LucideIcons.captions),
          onPressed: () {},
          color: Colors.white,
        ),
        IconButton(
          icon: const Icon(LucideIcons.fullscreen),
          onPressed: notifier.toggleFullscreen,
          color: Colors.white,
        ),
        IconButton(
          icon: const Icon(LucideIcons.ellipsisVertical),
          onPressed: () {},
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildVolumeButton(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => notifier.showVolumeSlider(true),
      onExit: (_) => notifier.showVolumeSlider(false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                state.volume == 0 ? LucideIcons.volumeX : LucideIcons.volume2,
              ),
              onPressed: notifier.toggleMute,
              color: Colors.white,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: state.showVolumeSlider ? 1 : 0,
                child: state.showVolumeSlider
                    ? SizedBox(
                        width: 100,
                        height: 40,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ), // default is 10–12
                            overlayShape: SliderComponentShape
                                .noOverlay, // removes big glow
                            trackHeight: 2, // thinner track
                          ),
                          child: Slider(
                            padding: EdgeInsets.only(right: 16.0),
                            value: state.volume,
                            min: 0,
                            max: 1,
                            onChanged: notifier.setVolume,
                          ),
                        ),
                      )
                    : const SizedBox(width: 0), // hidden
              ),
            ),
          ],
        ),
      ),
    );
  }
}
