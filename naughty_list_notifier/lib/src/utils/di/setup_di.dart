import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/application/peek_service.dart';
import 'package:naughty_list_notifier/src/features/video_evidence/presentation/video_evidence_controller.dart';
import 'package:naughty_list_notifier/src/shared/firebase_cloud_messaging/application/firebase_cloud_messaging_service.dart';
import 'package:naughty_list_notifier/src/shared/firebase_cloud_messaging/data/firebase_cloud_messaging_repository.dart';
import 'package:naughty_list_notifier/src/shared/firestore/data/firestore_repository.dart';

final _getIt = GetIt.instance;

void setupDi() {
  _registerRepositories();
  _registerServices();
  _registerControllers();
}

void _registerRepositories() {
  _getIt.registerLazySingleton<FirestoreRepository>(
    () => FirestoreRepositoryImpl(FirebaseFirestore.instance),
  );
  _getIt.registerLazySingleton<FirebaseCloudMessagingRepository>(
    () => FirebaseCloudMessagingRepositoryImpl(),
  );
}

void _registerServices() {
  _getIt.registerLazySingleton<PeekService>(
    () => PeekService(_getIt<FirestoreRepository>()),
  );
  _getIt.registerLazySingleton<FirebaseCloudMessagingService>(
    () => FirebaseCloudMessagingService(
      fcmRepository: _getIt<FirebaseCloudMessagingRepository>(),
    ),
  );
}

void _registerControllers() {
  _getIt.registerFactoryParam<VideoEvidenceController, String?, void>(
    (downloadURL, _) => VideoEvidenceController(downloadURL),
  );
}

void registerMock<T extends Object>(T mockInstance) {
  if (_getIt.isRegistered<T>()) {
    _getIt.unregister<T>();
  }
  _getIt.registerLazySingleton<T>(() => mockInstance);
}
