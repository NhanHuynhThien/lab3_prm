import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auto_usage.dart';
import '../models/ledger_enums.dart';

/// User-owned edits to an automatic row. The Companion owns counts and time.
typedef AutoUsageEdit = ({Purpose purpose, String title, String note});

/// `users/{uid}/auto_usage`: per-task rows written by the desktop Companion.
abstract interface class AutoUsageStore {
  Stream<List<AutoUsageEntry>> watch(String uid);
  Future<void> edit(String uid, String id, AutoUsageEdit edit);

  /// Hides a row instead of deleting it, so the next sync cannot recreate it.
  Future<void> hide(String uid, String id);
}

class FirestoreAutoUsageStore implements AutoUsageStore {
  FirestoreAutoUsageStore([FirebaseFirestore? db]) : _db = db;
  final FirebaseFirestore? _db;
  FirebaseFirestore get _store => _db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _store.collection('users/$uid/auto_usage');

  @override
  Stream<List<AutoUsageEntry>> watch(String uid) => _col(uid).snapshots().map(
    (snap) => [
      for (final doc in snap.docs)
        ?AutoUsageEntry.tryParse(doc.id, {
          for (final e in doc.data().entries)
            e.key: e.value is Timestamp
                ? (e.value as Timestamp).toDate()
                : e.value,
        }),
    ],
  );

  @override
  Future<void> edit(String uid, String id, AutoUsageEdit edit) => _col(uid)
      .doc(id)
      .update({
        'purpose': edit.purpose.name,
        'title': edit.title.trim(),
        'note': edit.note,
      });

  @override
  Future<void> hide(String uid, String id) =>
      _col(uid).doc(id).update({'hidden': true});
}
