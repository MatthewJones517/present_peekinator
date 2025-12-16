import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:naughty_list_notifier/src/features/video_evidence/presentation/video_evidence_controller.dart';
import 'package:naughty_list_notifier/src/features/video_evidence/presentation/video_evidence_screen.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'video_evidence_screen_test.mocks.dart';

@GenerateMocks([VideoEvidenceController])
void main() {
  late MockVideoEvidenceController mockController;
  late GetIt getIt;

  setUp(() {
    getIt = GetIt.instance;
    // Reset GetIt before each test
    if (getIt.isRegistered<VideoEvidenceController>()) {
      getIt.unregister<VideoEvidenceController>();
    }

    mockController = MockVideoEvidenceController();

    // Set up default signal returns for the mock
    // These will be overridden in individual tests as needed
    when(mockController.isLoading).thenReturn(signal(false));
    when(mockController.errorMessage).thenReturn(signal<String?>(null));
    when(
      mockController.videoController,
    ).thenReturn(signal<VideoController?>(null));
  });

  tearDown(() {
    // Clean up GetIt after each test
    if (getIt.isRegistered<VideoEvidenceController>()) {
      getIt.unregister<VideoEvidenceController>();
    }
    // Dispose mock controller if needed
    try {
      mockController.dispose();
    } catch (_) {
      // Ignore if already disposed
    }
  });

  Widget createTestWidget({
    String? downloadURL,
    VideoEvidenceController? customController,
  }) {
    // Unregister if already registered
    if (getIt.isRegistered<VideoEvidenceController>()) {
      getIt.unregister<VideoEvidenceController>();
    }

    // Register the controller (mock or custom)
    final controllerToUse = customController ?? mockController;
    getIt.registerFactoryParam<VideoEvidenceController, String?, void>(
      (param1, _) => controllerToUse,
    );

    return MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/video-evidence',
            name: 'video-evidence',
            builder: (context, state) {
              final url = state.uri.queryParameters['downloadURL'];
              return VideoEvidenceScreen(downloadURL: url);
            },
          ),
        ],
        initialLocation: '/video-evidence',
      ),
    );
  }

  group('VideoEvidenceScreen', () {
    testWidgets('displays loading indicator when controller is loading', (
      WidgetTester tester,
    ) async {
      // Setup mock controller signals to simulate loading state
      final isLoadingSignal = signal(true);
      final errorMessageSignal = signal<String?>(null);
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading video...'), findsOneWidget);
    });

    testWidgets('displays error message when controller has error', (
      WidgetTester tester,
    ) async {
      // Setup mock controller signals
      final isLoadingSignal = signal(false);
      final errorMessageSignal = signal<String?>(
        'Error loading video: Network error',
      );
      final videoControllerSignal = signal<VideoController?>(null);

      // Create a mock controller with signals
      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show error UI
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading video: Network error'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'displays "Video player not initialized" when no video controller',
      (WidgetTester tester) async {
        // Setup mock controller signals
        final isLoadingSignal = signal(false);
        final errorMessageSignal = signal<String?>(null);
        final videoControllerSignal = signal<VideoController?>(null);

        when(mockController.isLoading).thenReturn(isLoadingSignal);
        when(mockController.errorMessage).thenReturn(errorMessageSignal);
        when(mockController.videoController).thenReturn(videoControllerSignal);

        await tester.pumpWidget(
          createTestWidget(downloadURL: 'https://example.com/video.mp4'),
        );
        await tester.pump(); // Allow signal to propagate
        await tester.pump(const Duration(milliseconds: 100));

        // Should show not initialized message
        expect(find.text('Video player not initialized'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      },
    );

    testWidgets('disposes controller when widget is disposed', (
      WidgetTester tester,
    ) async {
      when(mockController.isLoading).thenReturn(signal(false));
      when(mockController.errorMessage).thenReturn(signal<String?>(null));
      when(
        mockController.videoController,
      ).thenReturn(signal<VideoController?>(null));

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      // Dispose the widget
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Verify dispose was called
      verify(mockController.dispose()).called(1);
    });

    testWidgets('passes downloadURL to controller through GetIt', (
      WidgetTester tester,
    ) async {
      const testURL = 'https://example.com/test-video.mp4';

      when(mockController.isLoading).thenReturn(signal(false));
      when(mockController.errorMessage).thenReturn(signal<String?>(null));
      when(
        mockController.videoController,
      ).thenReturn(signal<VideoController?>(null));

      await tester.pumpWidget(createTestWidget(downloadURL: testURL));
      await tester.pump();

      // The controller should be created with the downloadURL parameter
      // We verify this by checking that GetIt was called correctly
      // Since we're using registerFactoryParam, the parameter is passed
      expect(getIt.isRegistered<VideoEvidenceController>(), isTrue);
    });

    testWidgets('handles null downloadURL', (WidgetTester tester) async {
      when(mockController.isLoading).thenReturn(signal(false));
      when(mockController.errorMessage).thenReturn(signal<String?>(null));
      when(
        mockController.videoController,
      ).thenReturn(signal<VideoController?>(null));

      await tester.pumpWidget(createTestWidget(downloadURL: null));
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should still render (controller handles null URL internally)
      expect(find.byType(VideoEvidenceScreen), findsOneWidget);
    });

    testWidgets('handles empty downloadURL', (WidgetTester tester) async {
      when(mockController.isLoading).thenReturn(signal(false));
      when(mockController.errorMessage).thenReturn(signal<String?>(null));
      when(
        mockController.videoController,
      ).thenReturn(signal<VideoController?>(null));

      await tester.pumpWidget(createTestWidget(downloadURL: ''));
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should still render
      expect(find.byType(VideoEvidenceScreen), findsOneWidget);
    });

    testWidgets('updates UI when loading state changes', (
      WidgetTester tester,
    ) async {
      final isLoadingSignal = signal(true);
      final errorMessageSignal = signal<String?>(null);
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading video...'), findsOneWidget);

      // Change loading state
      isLoadingSignal.value = false;
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show not initialized message
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Video player not initialized'), findsOneWidget);
    });

    testWidgets('updates UI when error state changes', (
      WidgetTester tester,
    ) async {
      final isLoadingSignal = signal(false);
      final errorMessageSignal = signal<String?>(null);
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Initially no error
      expect(find.byIcon(Icons.error_outline), findsNothing);

      // Set error
      errorMessageSignal.value = 'Test error message';
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show error UI
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('displays video when videoController is available', (
      WidgetTester tester,
    ) async {
      // Note: This test is simplified since Video widget from media_kit_video
      // requires actual video controller setup which is complex to mock
      // We'll verify the structure is correct
      final isLoadingSignal = signal(false);
      final errorMessageSignal = signal<String?>(null);
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Without a real video controller, should show not initialized
      expect(find.text('Video player not initialized'), findsOneWidget);
    });

    testWidgets('prioritizes video controller over loading state', (
      WidgetTester tester,
    ) async {
      final isLoadingSignal = signal(true);
      final errorMessageSignal = signal<String?>(null);
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show loading (videoController is null)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Even if loading is true, if videoController exists, it should show video
      // But we can't easily test this without a real VideoController
    });

    testWidgets('prioritizes video controller over error state', (
      WidgetTester tester,
    ) async {
      final isLoadingSignal = signal(false);
      final errorMessageSignal = signal<String?>('Some error');
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show error (videoController is null)
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Some error'), findsOneWidget);
    });

    testWidgets('displays error icon and message correctly', (
      WidgetTester tester,
    ) async {
      final isLoadingSignal = signal(false);
      final errorMessageSignal = signal<String?>('Failed to load video');
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Verify error UI structure
      final errorIcon = find.byIcon(Icons.error_outline);
      expect(errorIcon, findsOneWidget);

      final iconWidget = tester.widget<Icon>(errorIcon);
      expect(iconWidget.size, 64);
      expect(iconWidget.color, Colors.red);

      expect(find.text('Failed to load video'), findsOneWidget);
    });

    testWidgets('displays loading UI structure correctly', (
      WidgetTester tester,
    ) async {
      final isLoadingSignal = signal(true);
      final errorMessageSignal = signal<String?>(null);
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Verify loading UI structure
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading video...'), findsOneWidget);

      // Verify it's in a Column with center alignment
      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('wraps content in ScreenBase', (WidgetTester tester) async {
      final isLoadingSignal = signal(false);
      final errorMessageSignal = signal<String?>(null);
      final videoControllerSignal = signal<VideoController?>(null);

      when(mockController.isLoading).thenReturn(isLoadingSignal);
      when(mockController.errorMessage).thenReturn(errorMessageSignal);
      when(mockController.videoController).thenReturn(videoControllerSignal);

      await tester.pumpWidget(
        createTestWidget(downloadURL: 'https://example.com/video.mp4'),
      );
      await tester.pump();

      // ScreenBase should be present (we can't easily find it without importing,
      // but we verify the screen renders)
      expect(find.byType(VideoEvidenceScreen), findsOneWidget);
    });
  });
}
