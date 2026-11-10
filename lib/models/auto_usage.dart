import 'ai_account.dart';
import 'ledger_enums.dart';
import 'usage_session.dart';

/// Companion sources that write per-task rows, and the ledger identity each
/// one is shown under. Gemini web (Takeout) and Antigravity have no per-task
/// token counts, so they stay out of the automatic ledger.
const autoProviders = {
  'codex': (provider: 'OpenAI', product: 'Codex CLI'),
  'claude': (provider: 'Anthropic', product: 'Claude Code'),
  'google': (provider: 'Google', product: 'Gemini CLI'),
};

String autoAccountId(String provider) => 'auto-$provider';

/// Automatic accounts and sessions share this ID prefix; manual IDs never do.
bool isAutoId(String id) => id.startsWith('auto-');

/// Companion accounts fill themselves; only active manual ones take entries.
bool acceptsManualUsage(AIAccount a) => !a.archived && !isAutoId(a.id);

/// One CLI task on one local day, written by the Companion to
/// `users/{uid}/auto_usage/{id}`. Counts, time and the detected purpose belong
/// to the Companion; [purpose], [title], [note] and [hidden] are the user's
/// edits, which the Companion never overwrites.
class AutoUsageEntry {
  const AutoUsageEntry({
    required this.id,
    required this.provider,
    required this.detectedPurpose,
    required this.inputTokens,
    required this.outputTokens,
    required this.occurredAt,
    this.startedAt,
    this.modelId,
    this.purpose,
    this.title,
    this.note = '',
    this.hidden = false,
  });

  final String id, provider;
  final Purpose detectedPurpose;
  final Purpose? purpose;
  final String? modelId, title;
  final String note;
  final int inputTokens, outputTokens;
  final DateTime occurredAt;
  final DateTime? startedAt;
  final bool hidden;

  Purpose get effectivePurpose => purpose ?? detectedPurpose;
  String get product => autoProviders[provider]!.product;
  String get defaultTitle => '$product · ${effectivePurpose.label}';

  UsageSession toSession() => UsageSession(
    id: id,
    accountId: autoAccountId(provider),
    title: title ?? defaultTitle,
    purpose: effectivePurpose,
    occurredAt: occurredAt,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    note: note,
    modelId: modelId,
    dataSource: DataSource.companion,
  );

  /// Parses a stored row whose timestamps are already [DateTime]s. Returns
  /// null for rows this app version cannot show instead of failing the
  /// whole ledger.
  static AutoUsageEntry? tryParse(String id, Map<String, Object?> d) {
    try {
      final provider = d['provider'];
      final input = d['inputTokens'], output = d['outputTokens'];
      final at = d['occurredAt'];
      // Retired by the Companion: the same work now lives under another id.
      if (d['superseded'] == true) return null;
      if (!isAutoId(id) ||
          provider is! String ||
          !autoProviders.containsKey(provider) ||
          input is! int ||
          output is! int ||
          input < 0 ||
          output < 0 ||
          at is! DateTime) {
        return null;
      }
      final model = d['model'];
      final title = d['title'];
      final purpose = d['purpose'];
      final started = d['startedAt'];
      return AutoUsageEntry(
        id: id,
        provider: provider,
        detectedPurpose: _purpose(d['detectedPurpose']) ?? Purpose.other,
        purpose: purpose == null ? null : _purpose(purpose),
        inputTokens: input,
        outputTokens: output,
        occurredAt: at,
        startedAt: started is DateTime ? started : null,
        modelId:
            model is String && model.trim().isNotEmpty && model.length <= 60
            ? model
            : null,
        title: title is String && title.trim().isNotEmpty ? title : null,
        note: d['note'] is String ? d['note'] as String : '',
        hidden: d['hidden'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static Purpose? _purpose(Object? name) =>
      Purpose.values.where((p) => p.name == name).firstOrNull;
}
