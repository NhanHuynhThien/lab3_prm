import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_usage.dart';

/// Last companion snapshot kept per Google account, so logging in shows the
/// token figures without the companion running. Holds only the aggregates the
/// companion already sanitises (tokens, models, purposes); no prompts.
abstract interface class ProviderSnapshotStore {
  /// Emits the saved snapshot now and whenever the background companion
  /// writes a newer one.
  Stream<ProviderSnapshot?> watch(String uid);
  Future<void> save(String uid, ProviderSnapshot snapshot);
}

class FirestoreProviderSnapshotStore implements ProviderSnapshotStore {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.doc('users/$uid/provider_snapshots/latest');

  @override
  Stream<ProviderSnapshot?> watch(String uid) =>
      _doc(uid).snapshots().map((doc) {
        final raw = doc.data()?['json'];
        if (raw is! String) return null;
        return ProviderSnapshot.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      });

  @override
  Future<void> save(String uid, ProviderSnapshot snapshot) async {
    final raw = snapshot.raw;
    if (raw == null) return;
    await _doc(uid).set({
      'ownerId': uid,
      'savedAt': FieldValue.serverTimestamp(),
      'json': raw,
    });
  }
}
