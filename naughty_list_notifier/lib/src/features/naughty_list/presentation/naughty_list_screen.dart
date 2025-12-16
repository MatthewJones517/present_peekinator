import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/application/peek_service.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/domain/peek_vm.dart';
import 'package:naughty_list_notifier/src/shared/screen_base/presentation/screen_base.dart';

class NaughtyListScreen extends StatelessWidget {
  const NaughtyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final peekService = GetIt.instance<PeekService>();

    return ScreenBase(
      child: Watch((context) {
        final videos = peekService.videos.value;

        if (videos.isEmpty) {
          return const Center(child: Text('No videos found'));
        }

        // Sort videos by date from most recent to oldest
        final sortedVideos = List<PeekVM>.from(videos)
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

        return ListView.builder(
          padding: const EdgeInsets.only(top: 50),
          itemCount: sortedVideos.length,
          itemBuilder: (context, index) {
            final video = sortedVideos[index];
            final iconPath = _getCardIcon(index);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Image.asset(
                  iconPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                title: const Text(
                  'Present Peeker Detected!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _formatDate(video.uploadedAt),
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.pushNamed(
                    'video-evidence',
                    queryParameters: {'downloadURL': video.downloadURL},
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final hour12 = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final period = date.hour < 12 ? 'AM' : 'PM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month}/${date.day}/${date.year} $hour12:$minute $period';
  }

  String _getCardIcon(int index) {
    final iconNumber = (index % 3) + 1;
    return 'assets/icon$iconNumber.png';
  }
}
