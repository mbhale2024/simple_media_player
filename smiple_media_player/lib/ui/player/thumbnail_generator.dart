import 'dart:typed_data';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class ThumbnailGenerator {
  /// Generates thumbnails for a video at fixed intervals.
  ///
  /// [path] is the local file path of the video.
  /// [duration] is the total duration of the video.
  /// [maxThumbnails] is the maximum number of thumbnails to generate (default: 100).
  ///
  /// Returns a map where the key is the timestamp in milliseconds and the value is the thumbnail data.
  static Future<Map<int, Uint8List>> generate(
    String path,
    Duration duration, {
    int maxThumbnails = 100,
  }) async {
    final Map<int, Uint8List> thumbnails = {};
    final int totalMs = duration.inMilliseconds;

    // Calculate interval to target ~100 thumbnails, but at least 2 seconds apart
    int intervalMs = (totalMs / maxThumbnails).ceil();
    if (intervalMs < 2000) intervalMs = 2000;

    final int stepMs = intervalMs;

    // Create a dedicated player for thumbnail generation
    final player = Player(
      configuration: const PlayerConfiguration(vo: 'libmpv'),
    );
    // Attach a VideoController to ensure texture creation
    VideoController(player);

    try {
      await player.open(Media(path), play: false);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 500));

      for (int ms = 0; ms < totalMs; ms += stepMs) {
        try {
          // print("Generating thumbnail for $ms ms");
          await player.seek(Duration(milliseconds: ms));
          // Small delay to ensure frame is rendered
          await Future.delayed(const Duration(milliseconds: 200));

          final Uint8List? data = await player.screenshot();
          if (data != null) {
            // print("Thumbnail generated for $ms ms: ${data.length} bytes");
            thumbnails[ms] = data;
          } else {
            print("Thumbnail data is null for $ms ms");
          }
        } catch (e) {
          print("Error generating thumbnail at $ms: $e");
        }
      }
    } catch (e) {
      print("Error initializing thumbnail generation: $e");
    } finally {
      await player.dispose();
    }

    return thumbnails;
  }
}
