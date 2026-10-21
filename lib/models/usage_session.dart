import 'ledger_enums.dart';

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
    occurredAt: decodeTimestamp(j['occurredAt']),
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
