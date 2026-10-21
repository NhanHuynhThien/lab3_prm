import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cloud_ledger.dart';
import '../models/ledger.dart';
import 'firestore_ledger_codec.dart';
import 'firestore_ledger_store.dart';

class FirestoreStreamWatcher {
  FirestoreStreamWatcher({
    required this.ownerId,
    required this.store,
    required this.guard,
    required this.failure,
    required this.listeners,
  });

  final String ownerId;
  final LedgerCloudStore store;
  final void Function() guard;
  final CloudLedgerFailure Function(Object) failure;
  final Set<Future<void> Function()> listeners;

  String get root => 'users/$ownerId';

  Stream<CloudSnapshot<T>> watch<T>(
    String collection,
    CloudRecord<T> Function(String, CloudMap, String, {bool pending}) decode, {
    List<StoreFilter> filters = const [],
    required String orderBy,
  }) {
    late StreamController<CloudSnapshot<T>> controller;
    StreamSubscription<StoreSnapshot>? data;
    StreamSubscription<String?>? auth;
    var stopped = false;
    Future<void> stop() async {
      if (stopped) return;
      stopped = true;
      listeners.remove(stop);
      await data?.cancel();
      await auth?.cancel();
      unawaited(controller.close());
    }

    void fail(Object error) {
      if (stopped) return;
      controller.addError(failure(error));
      unawaited(stop());
    }

    controller = StreamController<CloudSnapshot<T>>(
      onListen: () {
        try {
          guard();
          listeners.add(stop);
          auth = store.userIds.listen((uid) {
            if (uid != ownerId) {
              fail(
                const CloudLedgerFailure(
                  CloudLedgerProblem.unauthenticated,
                  'Phiên đăng nhập đã thay đổi.',
                ),
              );
            }
          }, onError: fail);
          data = store
              .watch('$root/$collection', filters: filters, orderBy: orderBy)
              .listen(
                (event) {
                  if (stopped) return;
                  try {
                    guard();
                    controller.add(
                      CloudSnapshot(
                        event.documents.map(
                          (doc) => decode(
                            doc.id,
                            doc.data,
                            ownerId,
                            pending: event.hasPendingWrites,
                          ),
                        ),
                        fromCache: event.fromCache,
                        hasPendingWrites: event.hasPendingWrites,
                      ),
                    );
                  } catch (error) {
                    fail(error);
                  }
                },
                onError: fail,
                onDone: () => unawaited(stop()),
              );
        } catch (error) {
          fail(error);
        }
      },
      onCancel: stop,
      onPause: () => data?.pause(),
      onResume: () => data?.resume(),
    );
    return controller.stream;
  }

  Stream<CloudSnapshot<AIAccount>> watchAccounts({bool? archived}) => watch(
    'accounts',
    FirestoreLedgerCodec.account,
    filters: [if (archived != null) StoreFilter('payload.archived', archived)],
    orderBy: 'updatedAt',
  );

  Stream<CloudSnapshot<UsageSession>> watchAllUsage() => watch(
    'usage_sessions',
    FirestoreLedgerCodec.usage,
    orderBy: 'payload.occurredAt',
  );

  Stream<CloudSnapshot<AccountQuota>> watchAllQuotas() =>
      watch('quota_windows', FirestoreLedgerCodec.quota, orderBy: 'updatedAt');

  Stream<CloudSnapshot<CloudSettings>> watchSettings() =>
      watch('settings', FirestoreLedgerCodec.settings, orderBy: 'updatedAt');

  Stream<CloudSnapshot<UsageSession>> watchUsage(CloudUsageQuery query) {
    if (query.accountId != null) {
      FirestoreLedgerCodec.segment(query.accountId!);
    }
    return watch(
      'usage_sessions',
      FirestoreLedgerCodec.usage,
      filters: [
        StoreFilter(
          'payload.occurredAt',
          Timestamp.fromDate(query.start),
          '>=',
        ),
        StoreFilter('payload.occurredAt', Timestamp.fromDate(query.end), '<'),
        if (query.accountId != null)
          StoreFilter('payload.accountId', query.accountId!),
        if (query.purpose != null)
          StoreFilter('payload.purpose', query.purpose!.name),
      ],
      orderBy: 'payload.occurredAt',
    );
  }

  Stream<CloudSnapshot<AccountQuota>> watchQuotas(String accountId) {
    FirestoreLedgerCodec.segment(accountId);
    return watch(
      'quota_windows',
      FirestoreLedgerCodec.quota,
      filters: [StoreFilter('payload.accountId', accountId)],
      orderBy: 'updatedAt',
    );
  }
}
