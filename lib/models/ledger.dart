import 'ai_account.dart';
import 'usage_session.dart';

export 'ai_account.dart';
export 'data_scope.dart';
export 'ledger_enums.dart';
export 'quota_snapshot.dart';
export 'usage_session.dart';

class LedgerData {
  LedgerData({
    required List<AIAccount> accounts,
    required List<UsageSession> sessions,
    this.reportingTimezone = 'Asia/Ho_Chi_Minh',
  }) : accounts = List.unmodifiable(accounts),
       sessions = List.unmodifiable(sessions);

  final List<AIAccount> accounts;
  final List<UsageSession> sessions;
  final String reportingTimezone;

  AIAccount? account(String id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  LedgerData copyWith({
    List<AIAccount>? accounts,
    List<UsageSession>? sessions,
    String? reportingTimezone,
  }) => LedgerData(
    accounts: accounts ?? this.accounts,
    sessions: sessions ?? this.sessions,
    reportingTimezone: reportingTimezone ?? this.reportingTimezone,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'reportingTimezone': reportingTimezone,
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'sessions': sessions.map((u) => u.toJson()).toList(),
  };

  factory LedgerData.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] is! int || ![1, 2].contains(j['schemaVersion'])) {
      throw const FormatException('Phiên bản dữ liệu chưa được hỗ trợ.');
    }
    if (j['schemaVersion'] == 1) j = migrateV1(j);
    return LedgerData(
      reportingTimezone: j['reportingTimezone'] as String,
      accounts: (j['accounts'] as List)
          .map((e) => AIAccount.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      sessions: (j['sessions'] as List)
          .map(
            (e) => UsageSession.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

/// Pure migration: no guessed model, actual cost, provider source or demo ID matching.
/// Legacy local timestamps retain their instant, then v2 serialization writes UTC.
Map<String, dynamic> migrateV1(Map<String, dynamic> old) => {
  'schemaVersion': 2,
  'reportingTimezone': 'device',
  'accounts': (old['accounts'] as List).map((raw) {
    final a = Map<String, dynamic>.from(raw as Map);
    final q = a.remove('quota');
    return {
      ...a,
      'quotaWindows': q == null
          ? []
          : [
              {
                ...Map<String, dynamic>.from(q as Map),
                'source': 'legacy',
                'unit': 'percent',
                'note': '',
              },
            ],
      'defaultModelId': null,
      'defaultPurposes': <String>[],
      'timezone': 'device',
      'dataSource': 'legacy',
      'cycleStartDay': 1,
      'isDemo': false,
    };
  }).toList(),
  'sessions': (old['sessions'] as List).map((raw) {
    final u = Map<String, dynamic>.from(raw as Map);
    return {
      ...u,
      'modelId': null,
      'dataSource': 'legacy',
      'costBasis': u['costMicros'] == null ? 'unknown' : 'unspecified',
      'isDemo': false,
    };
  }).toList(),
};
