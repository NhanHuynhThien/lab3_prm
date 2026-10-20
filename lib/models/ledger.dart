DateTime _decodeTimestamp(Object? value) {
  if (value is! String) {
    throw const FormatException('Timestamp phải là chuỗi ISO.');
  }
  final parts = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,6})?(Z|[+-]\d{2}:\d{2})?$',
  ).firstMatch(value);
  if (parts == null) throw const FormatException('Timestamp ISO không hợp lệ.');
  final numbers = List.generate(6, (i) => int.parse(parts.group(i + 1)!));
  final date = DateTime.utc(
    numbers[0],
    numbers[1],
    numbers[2],
    numbers[3],
    numbers[4],
    numbers[5],
  );
  if (date.year != numbers[0] ||
      date.month != numbers[1] ||
      date.day != numbers[2] ||
      date.hour != numbers[3] ||
      date.minute != numbers[4] ||
      date.second != numbers[5]) {
    throw const FormatException('Ngày hoặc giờ không tồn tại.');
  }
  final zone = parts.group(7);
  if (zone != null &&
      zone != 'Z' &&
      (int.parse(zone.substring(1, 3)) > 23 ||
          int.parse(zone.substring(4)) > 59)) {
    throw const FormatException('UTC offset không hợp lệ.');
  }
  return DateTime.parse(value);
}

enum Purpose {
  code('Lập trình'),
  debug('Sửa lỗi'),
  review('Code review'),
  test('Kiểm thử'),
  learn('Học tập'),
  write('Viết nội dung'),
  research('Nghiên cứu'),
  design('Thiết kế'),
  other('Khác');

  const Purpose(this.label);
  final String label;
}

enum BillingMode {
  subscription('Thuê bao'),
  api('API theo sử dụng'),
  other('Khác');

  const BillingMode(this.label);
  final String label;
}

enum DataSource {
  manual('Nhập tay'),
  demo('Demo giả định'),
  legacy('Dữ liệu cũ chưa phân loại');

  const DataSource(this.label);
  final String label;
}

enum CostBasis {
  manual('Chi phí nhập tay'),
  actual('Chi phí thực đã xác nhận'),
  unspecified('Chưa xác nhận loại chi phí'),
  unknown('Chưa biết');

  const CostBasis(this.label);
  final String label;
}

enum DataScope {
  manual('Dữ liệu nhập tay'),
  demo('Dữ liệu demo'),
  legacy('Dữ liệu cũ');

  const DataScope(this.label);
  final String label;
  bool includes(UsageSession session) => switch (this) {
    DataScope.demo => session.isDemo,
    DataScope.manual =>
      !session.isDemo && session.dataSource == DataSource.manual,
    DataScope.legacy =>
      !session.isDemo && session.dataSource == DataSource.legacy,
  };
  bool includesAccount(AIAccount account, List<UsageSession> sessions) {
    if (account.isDemo != (this == DataScope.demo)) return false;
    final source = switch (this) {
      DataScope.manual => DataSource.manual,
      DataScope.demo => DataSource.demo,
      DataScope.legacy => DataSource.legacy,
    };
    return account.dataSource == source ||
        sessions.any((s) => s.accountId == account.id && includes(s));
  }
}

class QuotaSnapshot {
  const QuotaSnapshot({
    required this.window,
    required this.usedPercent,
    required this.observedAt,
    required this.resetAt,
    this.source = DataSource.manual,
    this.sourceLabel = '',
    this.note = '',
    String? windowKey,
    // Public named argument deliberately maps to a private optional override.
    // ignore: prefer_initializing_formals
  }) : _windowKey = windowKey;
  final String window;
  final String? _windowKey;
  String get windowKey => _windowKey ?? window.trim().toLowerCase();
  final DataSource source;
  final String sourceLabel;
  final String note;
  // P0 supports percent only; no implicit token/message/credit allowance.
  String get unit => 'percent';
  final int usedPercent;
  final DateTime observedAt;
  final DateTime resetAt;
  bool isStale(DateTime now) => !now.isBefore(resetAt);
  int get remainingPercent => 100 - usedPercent;
  QuotaSnapshot copyWith({
    String? window,
    String? windowKey,
    int? usedPercent,
    DateTime? observedAt,
    DateTime? resetAt,
    DataSource? source,
    String? sourceLabel,
    String? note,
  }) => QuotaSnapshot(
    window: window ?? this.window,
    windowKey: windowKey ?? this.windowKey,
    usedPercent: usedPercent ?? this.usedPercent,
    observedAt: observedAt ?? this.observedAt,
    resetAt: resetAt ?? this.resetAt,
    source: source ?? this.source,
    sourceLabel: sourceLabel ?? this.sourceLabel,
    note: note ?? this.note,
  );
  Map<String, dynamic> toJson() => {
    'window': window,
    'unit': unit,
    'windowKey': windowKey,
    'source': source.name,
    'sourceLabel': sourceLabel,
    'note': note,
    'usedPercent': usedPercent,
    'observedAt': observedAt.toUtc().toIso8601String(),
    'resetAt': resetAt.toUtc().toIso8601String(),
  };
  factory QuotaSnapshot.fromJson(Map<String, dynamic> j) {
    if (j['unit'] != 'percent') {
      throw const FormatException('Đơn vị quota chưa được hỗ trợ.');
    }
    return QuotaSnapshot(
      window: j['window'] as String,
      windowKey: j['windowKey'] as String?,
      source: j.containsKey('source')
          ? DataSource.values.byName(j['source'] as String)
          : DataSource.legacy,
      sourceLabel: j['sourceLabel'] as String? ?? '',
      note: j['note'] as String? ?? '',
      usedPercent: j['usedPercent'] as int,
      observedAt: _decodeTimestamp(j['observedAt']),
      resetAt: _decodeTimestamp(j['resetAt']),
    );
  }
}

class AIAccount {
  AIAccount({
    required this.id,
    required this.alias,
    required this.provider,
    required this.product,
    required this.billingMode,
    required this.plan,
    required this.createdAt,
    this.budgetMicros,
    this.archived = false,
    QuotaSnapshot? quota,
    List<QuotaSnapshot>? quotaWindows,
    this.defaultModelId,
    List<Purpose> defaultPurposes = const [],
    this.timezone = 'Asia/Ho_Chi_Minh',
    this.cycleStartDay = 1,
    this.isDemo = false,
    this.dataSource = DataSource.manual,
  }) : quotaWindows = List.unmodifiable(
         quotaWindows ?? (quota == null ? [] : [quota]),
       ),
       defaultPurposes = List.unmodifiable(defaultPurposes);
  final String id, alias, provider, product, plan;
  final BillingMode billingMode;
  final DateTime createdAt;
  final int? budgetMicros;
  final bool archived;
  final List<QuotaSnapshot> quotaWindows;
  // Compatibility for callers that display just the first window. Never sum %.
  QuotaSnapshot? get quota => quotaWindows.isEmpty ? null : quotaWindows.first;
  final String? defaultModelId;
  final List<Purpose> defaultPurposes;
  final String timezone;
  final int cycleStartDay;
  final bool isDemo;
  final DataSource dataSource;
  AIAccount copyWith({
    String? alias,
    String? provider,
    String? product,
    BillingMode? billingMode,
    String? plan,
    int? budgetMicros,
    bool clearBudget = false,
    bool? archived,
    QuotaSnapshot? quota,
    List<QuotaSnapshot>? quotaWindows,
    String? defaultModelId,
    bool clearDefaultModel = false,
    List<Purpose>? defaultPurposes,
    String? timezone,
    int? cycleStartDay,
    bool? isDemo,
    DataSource? dataSource,
  }) => AIAccount(
    id: id,
    alias: alias ?? this.alias,
    provider: provider ?? this.provider,
    product: product ?? this.product,
    billingMode: billingMode ?? this.billingMode,
    plan: plan ?? this.plan,
    budgetMicros: clearBudget ? null : budgetMicros ?? this.budgetMicros,
    archived: archived ?? this.archived,
    quotaWindows:
        quotaWindows ??
        (quota == null
            ? this.quotaWindows
            : [
                for (final q in this.quotaWindows)
                  q.windowKey == quota.windowKey ? quota : q,
                if (!this.quotaWindows.any(
                  (q) => q.windowKey == quota.windowKey,
                ))
                  quota,
              ]),
    defaultModelId: clearDefaultModel
        ? null
        : defaultModelId ?? this.defaultModelId,
    defaultPurposes: defaultPurposes ?? this.defaultPurposes,
    timezone: timezone ?? this.timezone,
    cycleStartDay: cycleStartDay ?? this.cycleStartDay,
    isDemo: isDemo ?? this.isDemo,
    dataSource: dataSource ?? this.dataSource,
    createdAt: createdAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'alias': alias,
    'provider': provider,
    'product': product,
    'billingMode': billingMode.name,
    'plan': plan,
    'budgetMicros': budgetMicros,
    'archived': archived,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'quotaWindows': quotaWindows.map((q) => q.toJson()).toList(),
    'defaultModelId': defaultModelId,
    'defaultPurposes': defaultPurposes.map((p) => p.name).toList(),
    'timezone': timezone,
    'cycleStartDay': cycleStartDay,
    'isDemo': isDemo,
    'dataSource': dataSource.name,
  };
  factory AIAccount.fromJson(Map<String, dynamic> j) => AIAccount(
    id: j['id'] as String,
    alias: j['alias'] as String,
    provider: j['provider'] as String,
    product: j['product'] as String,
    billingMode: BillingMode.values.byName(j['billingMode'] as String),
    plan: j['plan'] as String,
    budgetMicros: j['budgetMicros'] as int?,
    archived: j['archived'] as bool,
    createdAt: _decodeTimestamp(j['createdAt']),
    quotaWindows: (j['quotaWindows'] as List)
        .map((q) => QuotaSnapshot.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList(),
    defaultModelId: j['defaultModelId'] as String?,
    defaultPurposes: (j['defaultPurposes'] as List)
        .map((p) => Purpose.values.byName(p as String))
        .toList(),
    timezone: j['timezone'] as String,
    cycleStartDay: j['cycleStartDay'] as int,
    isDemo: j['isDemo'] as bool,
    dataSource: DataSource.values.byName(j['dataSource'] as String),
  );
}

class UsageSession {
  const UsageSession({
    required this.id,
    required this.accountId,
    required this.title,
    required this.purpose,
    required this.occurredAt,
    this.inputTokens,
    this.outputTokens,
    this.costMicros,
    this.note = '',
    this.modelId,
    this.dataSource = DataSource.manual,
    this.costBasis,
    this.isDemo = false,
  });
  final String? modelId;
  final DataSource dataSource;
  final CostBasis? costBasis;
  CostBasis get effectiveCostBasis => costMicros == null
      ? CostBasis.unknown
      : costBasis ?? CostBasis.unspecified;
  final bool isDemo;
  final String id, accountId, title, note;
  final Purpose purpose;
  final DateTime occurredAt;
  final int? inputTokens, outputTokens, costMicros;
  int? get knownTokens => inputTokens == null || outputTokens == null
      ? null
      : (inputTokens ?? 0) + (outputTokens ?? 0);
  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'title': title,
    'purpose': purpose.name,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'modelId': modelId,
    'dataSource': dataSource.name,
    'costBasis': effectiveCostBasis.name,
    'isDemo': isDemo,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'costMicros': costMicros,
    'note': note,
  };
  factory UsageSession.fromJson(Map<String, dynamic> j) => UsageSession(
    id: j['id'] as String,
    accountId: j['accountId'] as String,
    title: j['title'] as String,
    purpose: Purpose.values.byName(j['purpose'] as String),
    occurredAt: _decodeTimestamp(j['occurredAt']),
    inputTokens: j['inputTokens'] as int?,
    outputTokens: j['outputTokens'] as int?,
    costMicros: j['costMicros'] as int?,
    note: j['note'] as String? ?? '',
    modelId: j['modelId'] as String?,
    dataSource: DataSource.values.byName(j['dataSource'] as String),
    costBasis: CostBasis.values.byName(j['costBasis'] as String),
    isDemo: j['isDemo'] as bool,
  );
}

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
