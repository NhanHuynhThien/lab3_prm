import 'dart:convert';

import 'companion_cloud.dart';
import 'companion_io.dart';
import 'snapshot_collector.dart';

/// Skips token-only writes whose aggregate is unchanged since the last
/// successful publish, uploads only changed auto_usage rows, and retires
/// rows this machine no longer produces. Failed writes never replace the
/// baseline.
class CloudSync {
  CloudSync(this.cloud, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final CompanionCloud cloud;
  final DateTime Function() _clock;
  String? _owner, _digest;
  Json? _snapshot;

  /// Last uploaded content per auto_usage row; only changed rows are sent.
  final _sent = <String, String>{};

  /// Cloud rows of this UID, listed once per run, then kept current here.
  Map<String, AutoDoc>? _known;

  /// Rows inside the read window of a provider whose logs were read fully,
  /// that exist in the cloud but were not produced this time. A partial read
  /// never retires anything: missing there may just mean "not read".
  static List<String> staleRows(
    Json snapshot,
    Map<String, AutoDoc> known,
    DateTime now,
  ) {
    final complete = {
      for (final p in (snapshot['providers'] as List).cast<Json>())
        if (asJson(p['activity'])?['partial'] == false) p['id'] as String,
    };
    final produced = {
      for (final r in CompanionCloud.autoUsageOf(snapshot)) r['id'] as String,
    };
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day - 29,
    ).millisecondsSinceEpoch;
    return [
      for (final d in known.values)
        if (!d.superseded &&
            complete.contains(d.provider) &&
            d.occurredMs >= cutoff &&
            !produced.contains(d.id))
          d.id,
    ];
  }

  Future<({List<String> providers, bool published})> call(
    String uid, {
    bool tokensOnly = false,
  }) async {
    if (uid != _owner) {
      _owner = uid;
      _snapshot = null;
      _digest = null;
      _known = null;
      _sent.clear();
    }
    Json? next;
    String? nextDigest;
    var published = false;
    final previous = _snapshot;
    final providers = await cloud.syncOnce(
      expectedUid: uid,
      collect: () async {
        next = tokensOnly && previous != null
            ? await cloud.collector.collectTokens(previous)
            : await cloud.collector.collect();
        nextDigest = snapshotDigest(next!);
        return next!;
      },
      shouldWrite: (_) {
        published = !tokensOnly || nextDigest != _digest;
        return published;
      },
      pendingRows: (snapshot) => [
        for (final row in CompanionCloud.autoUsageOf(snapshot))
          if (_sent[row['id']] != jsonEncode(row)) row,
      ],
      onRowsWritten: (rows) {
        for (final row in rows) {
          final id = row['id'] as String;
          _sent[id] = jsonEncode(row);
          _known?[id] = (
            id: id,
            provider: row['provider'] as String,
            occurredMs: parseMs(row['occurredAt']) ?? 0,
            superseded: false,
          );
        }
      },
      staleIds: (snapshot, list) async {
        final known = _known ??= {for (final d in await list()) d.id: d};
        return staleRows(snapshot, known, _clock());
      },
      onSuperseded: (ids) {
        for (final id in ids) {
          final d = _known?[id];
          if (d != null) {
            _known![id] = (
              id: d.id,
              provider: d.provider,
              occurredMs: d.occurredMs,
              superseded: true,
            );
          }
          _sent.remove(id);
        }
      },
    );
    _snapshot = next;
    _digest = nextDigest;
    return (providers: providers, published: published);
  }
}
