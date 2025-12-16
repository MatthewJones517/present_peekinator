import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:signals_flutter/signals_flutter.dart';

class VideoEvidenceController {
  final String? downloadURL;

  final Signal<bool> isLoading = signal(true);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<Player?> player = signal<Player?>(null);
  final Signal<VideoController?> videoController = signal<VideoController?>(
    null,
  );
  final Signal<bool> isBuffering = signal(false);

  VideoEvidenceController(this.downloadURL) {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (downloadURL == null || downloadURL!.isEmpty) {
      isLoading.value = false;
      errorMessage.value = 'No video URL provided';
      return;
    }

    try {
      debugPrint('Opening video URL: $downloadURL');

      // Initialize media_kit player with increased buffer for seamless looping
      final newPlayer = Player(
        configuration: PlayerConfiguration(
          bufferSize: 64 * 1024 * 1024, // 64 MB buffer for better pre-loading
        ),
      );
      final newVideoController = VideoController(newPlayer);

      // Set looping
      newPlayer.setPlaylistMode(PlaylistMode.loop);

      // Listen to player state changes for debugging
      newPlayer.stream.playing.listen((playing) {
        debugPrint('Player playing state: $playing');
      });
      newPlayer.stream.completed.listen((completed) {
        debugPrint('Player completed: $completed');
      });
      newPlayer.stream.error.listen((error) {
        debugPrint('Player error: $error');
        errorMessage.value = 'Player error: $error';
      });
      // Track buffering state
      newPlayer.stream.buffering.listen((buffering) {
        isBuffering.value = buffering;
      });

      // Set player first so Video widget can attach
      player.value = newPlayer;
      videoController.value = newVideoController;

      // Open the video directly from URL (media_kit will handle downloading/streaming)
      await newPlayer.open(Media(downloadURL!));

      // Start playing
      await newPlayer.play();

      // Wait for the player to start playing and finish initial buffering
      try {
        await newPlayer.stream.playing
            .firstWhere((playing) => playing == true)
            .timeout(const Duration(seconds: 10));
        debugPrint('Video started playing successfully');

        // Wait for initial buffering to complete for smoother looping
        await newPlayer.stream.buffering
            .firstWhere((buffering) => buffering == false)
            .timeout(const Duration(seconds: 15));
        debugPrint('Initial buffering complete');
      } catch (e) {
        debugPrint('Timeout waiting for video to play: $e');
        // Continue anyway - video might still work
      }

      isLoading.value = false;
      debugPrint('Video player initialized');
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error loading video: $e';
      debugPrint('Error initializing video player: $e');
    }
  }

  void dispose() {
    player.value?.dispose();
  }
}
