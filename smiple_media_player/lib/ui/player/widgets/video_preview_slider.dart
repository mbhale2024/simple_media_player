import 'dart:typed_data';
import 'package:flutter/material.dart';

class VideoPreviewSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final Map<int, Uint8List> thumbnails;

  const VideoPreviewSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.thumbnails,
  });

  @override
  State<VideoPreviewSlider> createState() => _VideoPreviewSliderState();
}

class _VideoPreviewSliderState extends State<VideoPreviewSlider> {
  bool _isHovering = false;
  double _hoverPosition = 0.0; // 0.0 to 1.0
  Uint8List? _currentThumbnail;

  double _lastWidth = 0.0;

  @override
  void didUpdateWidget(VideoPreviewSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thumbnails != oldWidget.thumbnails &&
        _isHovering &&
        _lastWidth > 0) {
      // Refresh preview with new thumbnails using last known position
      _updatePreview(_hoverPosition * _lastWidth, _lastWidth);
    }
  }

  void _updatePreview(double localX, double width) {
    if (width <= 0) return;
    final double percent = (localX / width).clamp(0.0, 1.0);
    final double previewTimeMs =
        widget.min + (widget.max - widget.min) * percent;

    // Find closest thumbnail
    int? closestKey;
    int minDiff = 999999999;

    if (widget.thumbnails.isNotEmpty) {
      for (final key in widget.thumbnails.keys) {
        final diff = (key - previewTimeMs).abs().toInt();
        if (diff < minDiff) {
          minDiff = diff;
          closestKey = key;
        }
      }
    }

    setState(() {
      _hoverPosition = percent;
      _currentThumbnail = closestKey != null
          ? widget.thumbnails[closestKey]
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _lastWidth = width;

        return MouseRegion(
          hitTestBehavior: HitTestBehavior.opaque,
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            setState(() => _isHovering = true);
            _updatePreview(event.localPosition.dx, width);
          },
          onExit: (_) => setState(() => _isHovering = false),
          onHover: (event) => _updatePreview(event.localPosition.dx, width),
          child: Container(
            color:
                Colors.transparent, // Ensure hit testing works on empty space
            height: 40, // Enforce a minimum height for easier hovering
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // The actual slider
                Slider(
                  padding: EdgeInsets.zero,
                  value: widget.value,
                  min: widget.min,
                  max: widget.max,
                  onChanged: (val) {
                    widget.onChanged?.call(val);
                    // Also update preview while dragging
                    final percent =
                        (val - widget.min) / (widget.max - widget.min);
                    _updatePreview(percent * width, width);
                  },
                  onChangeStart: (_) => setState(() => _isHovering = true),
                  onChangeEnd: (_) => setState(() => _isHovering = false),
                ),

                // The preview overlay
                if (_isHovering && _currentThumbnail != null)
                  Positioned(
                    left: (_hoverPosition * width) - 80, // Center 160px image
                    bottom:
                        50, // Position above slider (increased to avoid overlap)
                    child: IgnorePointer(
                      child: Container(
                        width: 160,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            _currentThumbnail!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
