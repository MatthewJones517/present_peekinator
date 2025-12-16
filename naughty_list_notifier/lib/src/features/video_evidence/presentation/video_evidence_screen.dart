import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:naughty_list_notifier/src/features/video_evidence/presentation/video_evidence_controller.dart';
import 'package:naughty_list_notifier/src/shared/screen_base/presentation/screen_base.dart';

class VideoEvidenceScreen extends StatefulWidget {
  final String? downloadURL;

  const VideoEvidenceScreen({super.key, this.downloadURL});

  @override
  State<VideoEvidenceScreen> createState() => _VideoEvidenceScreenState();
}

class _VideoEvidenceScreenState extends State<VideoEvidenceScreen> {
  late final VideoEvidenceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<VideoEvidenceController>(
      param1: widget.downloadURL,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBase(
      child: Watch((context) {
        final isLoading = _controller.isLoading.value;
        final errorMessage = _controller.errorMessage.value;
        final videoController = _controller.videoController.value;

        // Once video controller is initialized, always show it (even during loops)
        if (videoController != null) {
          return Center(
            child: Transform.rotate(
              angle: pi, // 180 degrees in radians
              child: Video(
                controller: videoController,
                controls: NoVideoControls,
                fill: Colors.black,
              ),
            ),
          );
        }

        if (errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading video...'),
              ],
            ),
          );
        }

        return const Center(child: Text('Video player not initialized'));
      }),
    );
  }
}
