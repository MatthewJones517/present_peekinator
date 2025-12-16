import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/application/peek_service.dart';
import 'package:naughty_list_notifier/src/shared/firestore/data/firestore_repository.dart';
import 'package:naughty_list_notifier/src/utils/di/setup_di.dart';
import 'peek_service_test.mocks.dart';

@GenerateMocks([FirestoreRepository])
void main() {
  late MockFirestoreRepository mockFirestoreRepository;
  late PeekService peekService;
  late GetIt getIt;

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
    registerMock<FirestoreRepository>(mockFirestoreRepository);
  });

  tearDown(() {
    peekService.dispose();
    // Clean up GetIt after each test
    if (getIt.isRegistered<FirestoreRepository>()) {
      getIt.unregister<FirestoreRepository>();
    }
    if (getIt.isRegistered<PeekService>()) {
      getIt.unregister<PeekService>();
    }
  });

  group('PeekService', () {
    test('initializes with default collection name', () {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      verify(mockFirestoreRepository.watchCollection('videos')).called(1);
      expect(peekService.videos.value, isEmpty);
    });

    test('initializes with custom collection name', () {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('custom_collection'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(
        getIt<FirestoreRepository>(),
        collectionName: 'custom_collection',
      );

      verify(
        mockFirestoreRepository.watchCollection('custom_collection'),
      ).called(1);
      expect(peekService.videos.value, isEmpty);
    });

    test(
      'watches collection and updates videos signal when data arrives',
      () async {
        final streamController = StreamController<List<Map<String, dynamic>>>();

        when(
          mockFirestoreRepository.watchCollection('videos'),
        ).thenAnswer((_) => streamController.stream);

        peekService = PeekService(getIt<FirestoreRepository>());

        final testData = [
          {
            'bucket': 'test-bucket',
            'contentType': 'video/mp4',
            'downloadURL': 'https://example.com/video1.mp4',
            'filePath': 'videos/video1.mp4',
            'size': '1024000',
            'uploadedAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'bucket': 'test-bucket',
            'contentType': 'video/mp4',
            'downloadURL': 'https://example.com/video2.mp4',
            'filePath': 'videos/video2.mp4',
            'size': '2048000',
            'uploadedAt': '2024-01-02T00:00:00.000Z',
          },
        ];

        streamController.add(testData);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(peekService.videos.value.length, 2);
        expect(
          peekService.videos.value[0].downloadURL,
          'https://example.com/video1.mp4',
        );
        expect(
          peekService.videos.value[1].downloadURL,
          'https://example.com/video2.mp4',
        );

        streamController.close();
      },
    );

    test('handles empty collection data', () async {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      streamController.add([]);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(peekService.videos.value, isEmpty);

      streamController.close();
    });

    test('handles stream errors gracefully', () async {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      // Add initial data
      streamController.add([
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T00:00:00.000Z',
        },
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(peekService.videos.value.length, 1);

      // Emit error - should not crash, just print debug message
      streamController.addError(Exception('Stream error'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Videos should still contain the previous data
      expect(peekService.videos.value.length, 1);

      streamController.close();
    });

    test('updates videos signal when new data arrives', () async {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      // First data
      streamController.add([
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T00:00:00.000Z',
        },
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(peekService.videos.value.length, 1);

      // Updated data
      streamController.add([
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T00:00:00.000Z',
        },
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video2.mp4',
          'filePath': 'videos/video2.mp4',
          'size': '2048000',
          'uploadedAt': '2024-01-02T00:00:00.000Z',
        },
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video3.mp4',
          'filePath': 'videos/video3.mp4',
          'size': '3072000',
          'uploadedAt': '2024-01-03T00:00:00.000Z',
        },
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(peekService.videos.value.length, 3);
      expect(
        peekService.videos.value[2].downloadURL,
        'https://example.com/video3.mp4',
      );

      streamController.close();
    });

    test('converts JSON data to PeekVM objects correctly', () async {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      final testData = [
        {
          'bucket': 'my-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://storage.example.com/video.mp4',
          'filePath': 'uploads/video.mp4',
          'size': '5242880',
          'uploadedAt': '2024-12-25T12:00:00.000Z',
        },
      ];

      streamController.add(testData);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(peekService.videos.value.length, 1);
      final peekVM = peekService.videos.value[0];
      expect(peekVM.bucket, 'my-bucket');
      expect(peekVM.contentType, 'video/mp4');
      expect(peekVM.downloadURL, 'https://storage.example.com/video.mp4');
      expect(peekVM.filePath, 'uploads/video.mp4');
      expect(peekVM.size, '5242880');
      expect(peekVM.uploadedAt, DateTime.parse('2024-12-25T12:00:00.000Z'));

      streamController.close();
    });

    test('dispose cancels subscription and clears it', () {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      expect(peekService.videos.value, isEmpty);

      peekService.dispose();

      // After dispose, subscription should be cancelled
      // We can verify this by checking that adding to stream doesn't update videos
      streamController.add([
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T00:00:00.000Z',
        },
      ]);

      // Videos should remain empty since subscription is cancelled
      expect(peekService.videos.value, isEmpty);

      streamController.close();
    });

    test('can be disposed multiple times safely', () {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      peekService.dispose();
      peekService.dispose();
      peekService.dispose();

      // Should not throw an error
      expect(peekService.videos.value, isEmpty);

      streamController.close();
    });

    test('re-watches collection when service is recreated', () {
      final streamController1 = StreamController<List<Map<String, dynamic>>>();
      final streamController2 = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController1.stream);

      peekService = PeekService(getIt<FirestoreRepository>());
      verify(mockFirestoreRepository.watchCollection('videos')).called(1);

      peekService.dispose();
      streamController1.close();

      // Reset mock to clear call count
      reset(mockFirestoreRepository);

      // Create new service instance
      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController2.stream);

      peekService = PeekService(getIt<FirestoreRepository>());
      verify(mockFirestoreRepository.watchCollection('videos')).called(1);

      streamController2.close();
    });

    test('videos signal is reactive and updates listeners', () async {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      int updateCount = 0;
      // Use effect to track signal changes
      final dispose = effect(() {
        peekService.videos.value; // Access value to create dependency
        updateCount++;
      });

      streamController.add([
        {
          'bucket': 'test-bucket',
          'contentType': 'video/mp4',
          'downloadURL': 'https://example.com/video1.mp4',
          'filePath': 'videos/video1.mp4',
          'size': '1024000',
          'uploadedAt': '2024-01-01T00:00:00.000Z',
        },
      ]);
      await Future.delayed(const Duration(milliseconds: 100));

      // Effect should have been triggered
      expect(updateCount, greaterThanOrEqualTo(1));

      dispose();
      streamController.close();
    });

    test('handles multiple rapid updates correctly', () async {
      final streamController = StreamController<List<Map<String, dynamic>>>();

      when(
        mockFirestoreRepository.watchCollection('videos'),
      ).thenAnswer((_) => streamController.stream);

      peekService = PeekService(getIt<FirestoreRepository>());

      // Send multiple rapid updates
      for (int i = 0; i < 5; i++) {
        streamController.add([
          {
            'bucket': 'test-bucket',
            'contentType': 'video/mp4',
            'downloadURL': 'https://example.com/video$i.mp4',
            'filePath': 'videos/video$i.mp4',
            'size': '1024000',
            'uploadedAt': '2024-01-0${i + 1}T00:00:00.000Z',
          },
        ]);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Should have the latest data
      expect(peekService.videos.value.length, 1);
      expect(
        peekService.videos.value[0].downloadURL,
        'https://example.com/video4.mp4',
      );

      streamController.close();
    });
  });
}
