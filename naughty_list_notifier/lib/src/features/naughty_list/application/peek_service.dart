import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:naughty_list_notifier/src/features/naughty_list/domain/peek_vm.dart';
import 'package:naughty_list_notifier/src/shared/firestore/data/firestore_repository.dart';

class PeekService {
  final FirestoreRepository _firestoreRepository;
  final String _collectionName;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  final Signal<List<PeekVM>> videos = signal(<PeekVM>[]);

  PeekService(this._firestoreRepository, {String collectionName = 'videos'})
    : _collectionName = collectionName {
    _watchCollection();
  }

  void _watchCollection() {
    _subscription?.cancel();
    _subscription = _firestoreRepository
        .watchCollection(_collectionName)
        .listen(
          (data) {
            final peekVideos = data
                .map((json) => PeekVM.fromJson(json))
                .toList();
            videos.value = peekVideos;
          },
          onError: (error) {
            debugPrint('Error watching video collection: $error');
          },
        );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
