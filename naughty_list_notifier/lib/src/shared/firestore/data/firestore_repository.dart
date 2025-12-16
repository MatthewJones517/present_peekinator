import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreRepository {
  Future<Map<String, dynamic>?> getDocument(String collection, String docId);
  Future<List<Map<String, dynamic>>> getCollection(String collection);
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  );
  Future<void> deleteDocument(String collection, String docId);
  Stream<Map<String, dynamic>?> watchDocument(String collection, String docId);
  Stream<List<Map<String, dynamic>>> watchCollection(String collection);
}

class FirestoreRepositoryImpl implements FirestoreRepository {
  final FirebaseFirestore _firestore;

  FirestoreRepositoryImpl(this._firestore);

  /// Converts Firestore Timestamp objects to DateTime in the data map
  Map<String, dynamic>? _convertTimestamps(Map<String, dynamic>? data) {
    if (data == null) return null;
    final converted = Map<String, dynamic>.from(data);
    converted.forEach((key, value) {
      if (value is Timestamp) {
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        converted[key] = _convertTimestamps(Map<String, dynamic>.from(value));
      }
    });
    return converted;
  }

  @override
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String docId,
  ) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    return _convertTimestamps(doc.data());
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.map((doc) => _convertTimestamps(doc.data())!).toList();
  }

  @override
  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    return _firestore.collection(collection).doc(docId).set(data);
  }

  @override
  Future<void> deleteDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).delete();
  }

  @override
  Stream<Map<String, dynamic>?> watchDocument(String collection, String docId) {
    return _firestore
        .collection(collection)
        .doc(docId)
        .snapshots()
        .map((doc) => _convertTimestamps(doc.data()));
  }

  @override
  Stream<List<Map<String, dynamic>>> watchCollection(String collection) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _convertTimestamps(doc.data())!)
              .toList(),
        );
  }
}
