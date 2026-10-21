import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef CloudMap = Map<String, dynamic>;

class StoreDocument {
  const StoreDocument(this.id, this.data);
  final String id;
  final CloudMap data;
}

class StoreSnapshot {
  const StoreSnapshot(
    this.documents, {
    required this.fromCache,
    required this.hasPendingWrites,
  });
  final List<StoreDocument> documents;
  final bool fromCache, hasPendingWrites;
}

class StoreFilter {
  const StoreFilter(this.field, this.value, [this.operator = '==']);
  final String field, operator;
  final Object value;
}

abstract interface class LedgerTransaction {
  Future<CloudMap?> get(String path);
  void set(String path, CloudMap data);
  void delete(String path);
}

/// Injectable SDK boundary. Only the production implementation calls Firebase.
abstract interface class LedgerCloudStore {
  String? get currentUid;
  Stream<String?> get userIds;
  Object get serverTimestamp;
  Stream<StoreSnapshot> watch(
    String collection, {
    List<StoreFilter> filters = const [],
    required String orderBy,
  });
  Future<T> transaction<T>(Future<T> Function(LedgerTransaction) action);
}

class FirestoreLedgerStore implements LedgerCloudStore {
  FirestoreLedgerStore({required this._firestore, required this._auth});
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  @override
  String? get currentUid => _auth.currentUser?.uid;
  @override
  Stream<String?> get userIds => _auth.userChanges().map((user) => user?.uid);
  @override
  Object get serverTimestamp => FieldValue.serverTimestamp();
  @override
  Stream<StoreSnapshot> watch(
    String collection, {
    List<StoreFilter> filters = const [],
    required String orderBy,
  }) {
    Query<CloudMap> query = _firestore.collection(collection);
    for (final filter in filters) {
      query = switch (filter.operator) {
        '==' => query.where(filter.field, isEqualTo: filter.value),
        '>=' => query.where(filter.field, isGreaterThanOrEqualTo: filter.value),
        '<' => query.where(filter.field, isLessThan: filter.value),
        _ => throw ArgumentError('Unsupported query operator'),
      };
    }
    return query
        .orderBy(orderBy, descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => StoreSnapshot(
            snapshot.docs
                .map((doc) => StoreDocument(doc.id, doc.data()))
                .toList(),
            fromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          ),
        );
  }

  @override
  Future<T> transaction<T>(Future<T> Function(LedgerTransaction) action) =>
      _firestore.runTransaction(
        (transaction) => action(_FirestoreTransaction(_firestore, transaction)),
      );
}

class _FirestoreTransaction implements LedgerTransaction {
  _FirestoreTransaction(this.firestore, this.transaction);
  final FirebaseFirestore firestore;
  final Transaction transaction;
  @override
  Future<CloudMap?> get(String path) async =>
      (await transaction.get(firestore.doc(path))).data();
  @override
  void set(String path, CloudMap data) =>
      transaction.set(firestore.doc(path), data);
  @override
  void delete(String path) => transaction.delete(firestore.doc(path));
}
