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

class QuotaSnapshot {
  const QuotaSnapshot({
    required this.window,
    required this.usedPercent,
    required this.observedAt,
    required this.resetAt,
  });
  final String window;
  final int usedPercent;
  final DateTime observedAt;
  final DateTime resetAt;
  bool isStale(DateTime now) => !now.isBefore(resetAt);
  int get remainingPercent => 100 - usedPercent;
  Map<String, dynamic> toJson() => {
    'window': window,
    'usedPercent': usedPercent,
    'observedAt': observedAt.toIso8601String(),
    'resetAt': resetAt.toIso8601String(),
  };
  factory QuotaSnapshot.fromJson(Map<String, dynamic> j) => QuotaSnapshot(
    window: j['window'] as String,
    usedPercent: j['usedPercent'] as int,
    observedAt: DateTime.parse(j['observedAt'] as String),
    resetAt: DateTime.parse(j['resetAt'] as String),
  );
}

class AIAccount {
  const AIAccount({
    required this.id,
    required this.alias,
    required this.provider,
    required this.product,
    required this.billingMode,
    required this.plan,
    required this.createdAt,
    this.budgetMicros,
    this.archived = false,
    this.quota,
  });
  final String id, alias, provider, product, plan;
  final BillingMode billingMode;
  final DateTime createdAt;
  final int? budgetMicros;
  final bool archived;
  final QuotaSnapshot? quota;
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
  }) => AIAccount(
    id: id,
    alias: alias ?? this.alias,
    provider: provider ?? this.provider,
    product: product ?? this.product,
    billingMode: billingMode ?? this.billingMode,
    plan: plan ?? this.plan,
    budgetMicros: clearBudget ? null : budgetMicros ?? this.budgetMicros,
    archived: archived ?? this.archived,
    quota: quota ?? this.quota,
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
    'createdAt': createdAt.toIso8601String(),
    'quota': quota?.toJson(),
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
    createdAt: DateTime.parse(j['createdAt'] as String),
    quota: j['quota'] == null
        ? null
        : QuotaSnapshot.fromJson(Map<String, dynamic>.from(j['quota'] as Map)),
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
  });
  final String id, accountId, title, note;
  final Purpose purpose;
  final DateTime occurredAt;
  final int? inputTokens, outputTokens, costMicros;
  int? get knownTokens => inputTokens == null && outputTokens == null
      ? null
      : (inputTokens ?? 0) + (outputTokens ?? 0);
  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'title': title,
    'purpose': purpose.name,
    'occurredAt': occurredAt.toIso8601String(),
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
    occurredAt: DateTime.parse(j['occurredAt'] as String),
    inputTokens: j['inputTokens'] as int?,
    outputTokens: j['outputTokens'] as int?,
    costMicros: j['costMicros'] as int?,
    note: j['note'] as String? ?? '',
  );
}

class LedgerData {
  LedgerData({
    required List<AIAccount> accounts,
    required List<UsageSession> sessions,
  }) : accounts = List.unmodifiable(accounts),
       sessions = List.unmodifiable(sessions);
  final List<AIAccount> accounts;
  final List<UsageSession> sessions;
  AIAccount? account(String id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  LedgerData copyWith({
    List<AIAccount>? accounts,
    List<UsageSession>? sessions,
  }) => LedgerData(
    accounts: accounts ?? this.accounts,
    sessions: sessions ?? this.sessions,
  );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'sessions': sessions.map((u) => u.toJson()).toList(),
  };
  factory LedgerData.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('Phiên bản dữ liệu chưa được hỗ trợ.');
    }
    return LedgerData(
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
