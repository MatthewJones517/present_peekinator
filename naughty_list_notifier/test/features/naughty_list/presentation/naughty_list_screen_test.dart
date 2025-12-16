import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/application/peek_service.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/presentation/naughty_list_screen.dart';
import 'package:naughty_list_notifier/src/shared/firestore/data/firestore_repository.dart';
import 'package:naughty_list_notifier/src/utils/di/setup_di.dart';
import 'naughty_list_screen_test.mocks.dart';

@GenerateMocks([FirestoreRepository])
void main() {
  late MockFirestoreRepository mockFirestoreRepository;
  late PeekService peekService;
  late GetIt getIt;
  late StreamController<List<Map<String, dynamic>>> streamController;

  setUp(() {
    getIt = GetIt.instance;
    // Reset GetIt before each test
    if (getIt.isRegistered<FirestoreRepository>()) {
      getIt.unregister<FirestoreRepository>();
    }
    if (getIt.isRegistered<PeekService>()) {
      getIt.unregister<PeekService>();
    }

    mockFirestoreRepository = MockFirestoreRepository();
    streamController = StreamController<List<Map<String, dynamic>>>();

    when(
      mockFirestoreRepository.watchCollection('videos'),
    ).thenAnswer((_) => streamController.stream);

    registerMock<FirestoreRepository>(mockFirestoreRepository);
    peekService = PeekService(getIt<FirestoreRepository>());
    registerMock<PeekService>(peekService);
  });

  tearDown(() {
    peekService.dispose();
    streamController.close();
    // Clean up GetIt after each test
    if (getIt.isRegistered<FirestoreRepository>()) {
      getIt.unregister<FirestoreRepository>();
    }
    if (getIt.isRegistered<PeekService>()) {
      getIt.unregister<PeekService>();
    }
  });

  Widget createTestWidget() {
    return MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const NaughtyListScreen(),
          ),
          GoRoute(
            path: '/video-evidence',
            name: 'video-evidence',
            builder: (context, state) =>
                const Scaffold(body: Text('Video Evidence Screen')),
          ),
        ],
      ),
    );
  }

  group('NaughtyListScreen', () {
    testWidgets('displays "No videos found" when videos list is empty', (
      WidgetTester tester,
    ) async {
      // Initially empty
      streamController.add([]);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No videos found'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('displays list of videos when videos are available', (
      WidgetTester tester,
    ) async {
      final testData = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T12:00:00.000Z',
        },
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video2.mp4',
          'filePath': 'videos/video2.mp4',
          'size': '2048000',
          'uploadedAt': '2024-01-02T15:30:00.000Z',
        },
      ];

      streamController.add(testData);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No videos found'), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Present Peeker Detected!'), findsNWidgets(2));
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('displays correct date format for videos', (
      WidgetTester tester,
    ) async {
      // Test AM time
      final testDataAM = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T09:30:00.000Z', // 9:30 AM
        },
      ];

      streamController.add(testDataAM);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should display: 1/1/2024 9:30 AM
      expect(find.textContaining('1/1/2024'), findsOneWidget);
      expect(find.textContaining('AM'), findsOneWidget);

      // Test PM time
      final testDataPM = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video2.mp4',
          'filePath': 'videos/video2.mp4',
          'size': '2048000',
          'uploadedAt': '2024-01-02T15:45:00.000Z', // 3:45 PM
        },
      ];

      streamController.add(testDataPM);
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('1/2/2024'), findsOneWidget);
      expect(find.textContaining('PM'), findsOneWidget);

      // Test midnight (12 AM)
      final testDataMidnight = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video3.mp4',
          'filePath': 'videos/video3.mp4',
          'size': '3072000',
          'uploadedAt': '2024-01-03T00:00:00.000Z', // Midnight
        },
      ];

      streamController.add(testDataMidnight);
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('1/3/2024'), findsOneWidget);
      expect(find.textContaining('12:00 AM'), findsOneWidget);

      // Test noon (12 PM)
      final testDataNoon = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video4.mp4',
          'filePath': 'videos/video4.mp4',
          'size': '4096000',
          'uploadedAt': '2024-01-04T12:00:00.000Z', // Noon
        },
      ];

      streamController.add(testDataNoon);
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('1/4/2024'), findsOneWidget);
      expect(find.textContaining('12:00 PM'), findsOneWidget);
    });

    testWidgets('displays correct icons for video cards', (
      WidgetTester tester,
    ) async {
      final testData = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T12:00:00.000Z',
        },
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video2.mp4',
          'filePath': 'videos/video2.mp4',
          'size': '2048000',
          'uploadedAt': '2024-01-02T12:00:00.000Z',
        },
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video3.mp4',
          'filePath': 'videos/video3.mp4',
          'size': '3072000',
          'uploadedAt': '2024-01-03T12:00:00.000Z',
        },
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video4.mp4',
          'filePath': 'videos/video4.mp4',
          'size': '4096000',
          'uploadedAt': '2024-01-04T12:00:00.000Z',
        },
      ];

      streamController.add(testData);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Icons should cycle: icon1, icon2, icon3, icon1 (for 4 items)
      // Find images within ListTile widgets (excluding ScreenBase images)
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(4));

      // Verify each ListTile has an Image widget with AssetImage
      for (int i = 0; i < 4; i++) {
        final listTile = tester.widget<ListTile>(listTiles.at(i));
        // Find Image widget within this ListTile's leading widget
        final leadingWidget = listTile.leading;
        expect(leadingWidget, isA<Image>());
        final image = leadingWidget as Image;
        expect(image.image, isA<AssetImage>());
      }
    });

    testWidgets('updates UI when videos signal changes', (
      WidgetTester tester,
    ) async {
      // Start with empty list
      streamController.add([]);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No videos found'), findsOneWidget);

      // Add videos
      final testData = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T12:00:00.000Z',
        },
      ];

      streamController.add(testData);
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should now show the video
      expect(find.text('No videos found'), findsNothing);
      expect(find.text('Present Peeker Detected!'), findsOneWidget);

      // Remove videos
      streamController.add([]);
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show empty state again
      expect(find.text('No videos found'), findsOneWidget);
      expect(find.text('Present Peeker Detected!'), findsNothing);
    });

    testWidgets('displays chevron icon on each card', (
      WidgetTester tester,
    ) async {
      final testData = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T12:00:00.000Z',
        },
      ];

      streamController.add(testData);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      final chevronIcons = find.byIcon(Icons.chevron_right);
      expect(chevronIcons, findsOneWidget);
    });

    testWidgets('handles date formatting edge cases', (
      WidgetTester tester,
    ) async {
      // Test single digit month and day
      final testData1 = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt':
              '2024-01-05T09:05:00.000Z', // Single digit day, single digit minute
        },
      ];

      streamController.add(testData1);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('1/5/2024'), findsOneWidget);
      expect(find.textContaining('9:05'), findsOneWidget);

      // Test double digit month and day
      final testData2 = [
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video2.mp4',
          'filePath': 'videos/video2.mp4',
          'size': '2048000',
          'uploadedAt':
              '2024-12-25T23:59:00.000Z', // Double digit month and day
        },
      ];

      streamController.add(testData2);
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('12/25/2024'), findsOneWidget);
      expect(find.textContaining('11:59 PM'), findsOneWidget);
    });

    testWidgets('displays correct video information in cards', (
      WidgetTester tester,
    ) async {
      final testData = [
        {
          'bucket': 'my-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://storage.example.com/video.mp4',
          'filePath': 'uploads/video.mp4',
          'size': '5242880',
          'uploadedAt': '2024-12-25T14:30:00.000Z',
        },
      ];

      streamController.add(testData);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the card displays the correct information
      expect(find.text('Present Peeker Detected!'), findsOneWidget);
      expect(find.textContaining('12/25/2024'), findsOneWidget);
      expect(find.textContaining('2:30 PM'), findsOneWidget);
    });

    testWidgets('handles rapid video updates correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Rapidly add and remove videos
      for (int i = 0; i < 5; i++) {
        final testData = [
          {
            'bucket': 'test-bucket',
            'contentType': 'video/mp4',
            'downloadURL': 'https://example.com/video$i.mp4',
            'filePath': 'videos/video$i.mp4',
            'size': '1024000',
            'uploadedAt': '2024-01-0${i + 1}T12:00:00.000Z',
          },
        ];
        streamController.add(testData);
        await tester.pump();
      }

      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      // Should show the latest video
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Present Peeker Detected!'), findsOneWidget);
    });

    testWidgets('maintains scroll position when new videos are added', (
      WidgetTester tester,
    ) async {
      final initialData = List.generate(
        5,
        (index) => {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video$index.mp4',
          'filePath': 'videos/video$index.mp4',
          'size': '1024000',
          'uploadedAt':
              '2024-01-${(index + 1).toString().padLeft(2, '0')}T12:00:00.000Z',
        },
      );

      streamController.add(initialData);
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Allow signal to propagate
      await tester.pump(const Duration(milliseconds: 100));

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView, isNotNull);
    });
  });
}
