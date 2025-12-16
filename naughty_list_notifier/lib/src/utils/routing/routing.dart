import 'package:go_router/go_router.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/presentation/naughty_list_screen.dart';
import 'package:naughty_list_notifier/src/features/video_evidence/presentation/video_evidence_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'naughty-list',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const NaughtyListScreen(),
      ),
    ),
    GoRoute(
      path: '/video-evidence',
      name: 'video-evidence',
      pageBuilder: (context, state) {
        final downloadURL = state.uri.queryParameters['downloadURL'];
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: VideoEvidenceScreen(downloadURL: downloadURL),
        );
      },
    ),
  ],
);
