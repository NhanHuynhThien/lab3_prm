import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../firebase_options.dart';
import '../models/companion_state.dart';
import 'auto_usage_rows.dart';
import 'companion_io.dart';
import 'keychain_store.dart';
import 'snapshot_collector.dart';

/// Public Firebase web client config; not an admin credential.
class CompanionFirebaseConfig {
  const CompanionFirebaseConfig({
    required this.apiKey,
    required this.authDomain,
    required this.projectId,
    required this.appId,
  });
  factory CompanionFirebaseConfig.fromOptions() {
    final web = DefaultFirebaseOptions.web;
    return CompanionFirebaseConfig(
      apiKey: web.apiKey,
      authDomain: web.authDomain ?? '${web.projectId}.firebaseapp.com',
      projectId: web.projectId,
      appId: web.appId,
    );
  }
  final String apiKey, authDomain, projectId, appId;
  Json toJson() => {
    'apiKey': apiKey,
    'authDomain': authDomain,
    'projectId': projectId,
    'appId': appId,
  };
}

typedef AutoDoc = ({
  String id,
  String provider,
  int occurredMs,
  bool superseded,
});

typedef FirebaseSession = ({String idToken, String uid, String? refreshToken});

/// Account identity file shared with the CLI bridge (uid + email, not secret).
class AccountFile {
  const AccountFile();
  File get _file => File('$companionStateDir/cloud-account.json');

  Future<CompanionAccount?> read() async {
    try {
      return CompanionAccount.fromJson(jsonDecode(await _file.readAsString()));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(CompanionAccount account) =>
      writeAtomic(_file.path, jsonEncode(account.toJson()));

  Future<void> delete() async {
    if (await _file.exists()) await _file.delete();
  }
}

class CompanionCloud {
  CompanionCloud({
    required this.config,
    http.Client? client,
    this.secrets = const KeychainStore(),
    this.collector = const SnapshotCollector(),
  }) : client = client ?? http.Client();

  final CompanionFirebaseConfig config;
  final http.Client client;
  final KeychainStore secrets;
  final SnapshotCollector collector;
  static const _timeout = Duration(seconds: 30);

  Future<FirebaseSession> exchange(String refreshToken) async {
    final res = await client
        .post(
          Uri.parse(
            'https://securetoken.googleapis.com/v1/token?key=${config.apiKey}',
          ),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw CompanionException(
        'Phiên đăng nhập hết hạn (${res.statusCode}). Hãy đăng nhập lại.',
      );
    }
    final body = asJson(jsonDecode(res.body))!;
    return (
      idToken: body['id_token'] as String,
      uid: body['user_id'] as String,
      refreshToken: body['refresh_token'] as String?,
    );
  }

  String _doc(String uid, String path) =>
      'projects/${config.projectId}/databases/(default)/documents/users/$uid/$path';

  /// Per-task rows go to `auto_usage`; the snapshot keeps only aggregates.
  static Json withoutAutoUsage(Json snapshot) => stripAutoUsage(snapshot);
  static List<Json> autoUsageOf(Json snapshot) => autoUsageRowsOf(snapshot);

  /// Upserts only the Companion's fields, so the user's purpose/title/note
  /// edits and hidden flag on the phone survive every later sync.
  Json autoUsageWrite(String uid, Json row) {
    Json time(Object? iso) =>
        iso == null ? {'nullValue': null} : {'timestampValue': iso};
    final model = row['model'];
    final fields = <String, Json>{
      'ownerId': {'stringValue': uid},
      'provider': {'stringValue': row['provider']},
      'detectedPurpose': {'stringValue': row['detectedPurpose']},
      'model': model == null ? {'nullValue': null} : {'stringValue': model},
      'inputTokens': {'integerValue': '${row['inputTokens']}'},
      'outputTokens': {'integerValue': '${row['outputTokens']}'},
      'occurredAt': time(row['occurredAt']),
      'startedAt': time(row['startedAt']),
      // Produced again by this sync, so it counts again.
      'superseded': {'booleanValue': false},
    };
    return {
      'update': {
        'name': _doc(uid, 'auto_usage/${row['id']}'),
        'fields': fields,
      },
      'updateMask': {'fieldPaths': fields.keys.toList()},
      'updateTransforms': [
        {'fieldPath': 'syncedAt', 'setToServerValue': 'REQUEST_TIME'},
      ],
    };
  }

  /// Marks a row this machine no longer produces (its session was re-read
  /// under another task numbering), so the phone stops counting it twice.
  /// Only an existing row is touched; user edits stay.
  Json supersedeWrite(String uid, String id) => {
    'update': {
      'name': _doc(uid, 'auto_usage/$id'),
      'fields': {
        'superseded': {'booleanValue': true},
      },
    },
    'updateMask': {
      'fieldPaths': ['superseded'],
    },
    'currentDocument': {'exists': true},
  };

  /// Companion rows already in the cloud: id, provider, time, superseded.
  Future<List<AutoDoc>> listAutoUsage(String idToken, String uid) async {
    final out = <AutoDoc>[];
    String? page;
    do {
      final uri =
          Uri.parse(
            'https://firestore.googleapis.com/v1/${_doc(uid, 'auto_usage')}',
          ).replace(
            queryParameters: {
              'pageSize': '300',
              'mask.fieldPaths': ['provider', 'occurredAt', 'superseded'],
              'pageToken': ?page,
            },
          );
      final res = await client
          .get(uri, headers: {'Authorization': 'Bearer $idToken'})
          .timeout(_timeout);
      if (res.statusCode != 200) {
        throw CompanionException('Firestore từ chối đọc (${res.statusCode}).');
      }
      final body = asJson(jsonDecode(res.body)) ?? const {};
      for (final d in (body['documents'] as List? ?? const []).map(asJson)) {
        final f = asJson(d?['fields']);
        final at = parseMs(asJson(f?['occurredAt'])?['timestampValue']);
        final provider = asJson(f?['provider'])?['stringValue'];
        final name = d?['name'];
        if (name is! String || provider is! String || at == null) continue;
        out.add((
          id: name.split('/').last,
          provider: provider,
          occurredMs: at,
          superseded: asJson(f?['superseded'])?['booleanValue'] == true,
        ));
      }
      page = body['nextPageToken'] as String?;
    } while (page != null && page.isNotEmpty);
    return out;
  }

  Json snapshotWrite(String uid, Json snapshot) => {
    'writes': [
      {
        'update': {
          'name': _doc(uid, 'provider_snapshots/latest'),
          'fields': {
            'ownerId': {'stringValue': uid},
            'json': {'stringValue': jsonEncode(withoutAutoUsage(snapshot))},
          },
        },
        // Firestore rules require savedAt == request.time.
        'updateTransforms': [
          {'fieldPath': 'savedAt', 'setToServerValue': 'REQUEST_TIME'},
        ],
      },
    ],
  };

  /// Refreshes the session, collects, and writes when [shouldWrite] allows.
  /// Returns the provider IDs that reported ready.
  Future<List<String>> syncOnce({
    required String expectedUid,
    required Future<Json> Function() collect,
    bool Function(Json snapshot)? shouldWrite,
    List<Json> Function(Json snapshot)? pendingRows,
    void Function(List<Json> rows)? onRowsWritten,
    Future<List<String>> Function(
      Json snapshot,
      Future<List<AutoDoc>> Function() list,
    )?
    staleIds,
    void Function(List<String> ids)? onSuperseded,
  }) async {
    final stored = await secrets.load();
    if (stored == null) {
      throw const CompanionException('Chưa đăng nhập. Hãy kết nối lại.');
    }
    final session = await exchange(stored);
    if (session.uid != expectedUid) {
      throw const CompanionException(
        'Tài khoản đồng bộ đã thay đổi. Hãy đăng nhập lại.',
      );
    }
    final refreshed = session.refreshToken;
    if (refreshed != null && refreshed != stored) await secrets.save(refreshed);
    final snapshot = await collect();
    final ready = [
      for (final p in (snapshot['providers'] as List).cast<Json>())
        if (p['status'] == 'ready') p['id'] as String,
    ];
    if (shouldWrite != null && !shouldWrite(snapshot)) return ready;
    final rows = pendingRows?.call(snapshot) ?? autoUsageOf(snapshot);
    await _commit(session.idToken, snapshotWrite(session.uid, snapshot));
    // Firestore allows 500 writes per commit; stay well below it.
    for (var i = 0; i < rows.length; i += 200) {
      final chunk = rows.sublist(
        i,
        i + 200 > rows.length ? rows.length : i + 200,
      );
      await _commit(session.idToken, {
        'writes': [for (final r in chunk) autoUsageWrite(session.uid, r)],
      });
      onRowsWritten?.call(chunk);
    }
    final stale =
        await staleIds?.call(
          snapshot,
          () => listAutoUsage(session.idToken, session.uid),
        ) ??
        const <String>[];
    for (var i = 0; i < stale.length; i += 200) {
      final chunk = stale.sublist(
        i,
        i + 200 > stale.length ? stale.length : i + 200,
      );
      await _commit(session.idToken, {
        'writes': [for (final id in chunk) supersedeWrite(session.uid, id)],
      });
      onSuperseded?.call(chunk);
    }
    return ready;
  }

  Future<void> _commit(String idToken, Json body) async {
    final res = await client
        .post(
          Uri.parse(
            'https://firestore.googleapis.com/v1/projects/${config.projectId}/databases/(default)/documents:commit',
          ),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw CompanionException('Firestore từ chối ghi (${res.statusCode}).');
    }
  }
}
