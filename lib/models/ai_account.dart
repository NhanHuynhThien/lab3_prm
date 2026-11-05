import 'ledger_enums.dart';
import 'quota_snapshot.dart';

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

  /// The window closest to running out; expired snapshots only as a fallback.
  QuotaSnapshot? limitingQuota(DateTime now) {
    final live = quotaWindows.where((q) => !q.isStale(now)).toList()
      ..sort((a, b) => b.usedPercent.compareTo(a.usedPercent));
    return live.firstOrNull ?? quota;
  }

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
    createdAt: decodeTimestamp(j['createdAt']),
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
