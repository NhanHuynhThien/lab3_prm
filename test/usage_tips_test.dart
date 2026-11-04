import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ledger_enums.dart';
import 'package:token_ledger/models/provider_activity.dart';
import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/services/usage_tips.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 12);
  ActivityTokens tokens(int total, {int? input, int? output, int? cached}) =>
      ActivityTokens(total, input, output, cached, null, null, 1);
  ProviderActivity activity(ActivityTokens t, List<ActivityPurpose> p) =>
      ProviderActivity(
        start: now.subtract(const Duration(days: 30)),
        end: now,
        partial: false,
        tokens: t,
        sessionCount: 1,
        taskCount: 1,
        activeDays: 1,
        omittedTasks: 0,
        purposes: p,
        daily: const [],
        tasks: const [],
        method: 'keywords',
      );
  ProviderUsage usage([List<ProviderQuota> windows = const []]) =>
      ProviderUsage(
        id: 'codex',
        status: 'ready',
        source: 'Phiên lưu trên máy',
        coverage: '',
        observedAt: now,
        windows: windows,
      );

  test('heavy context, low cache, vague and debug-heavy usage get tips', () {
    final tips = usageTips(
      activity(tokens(1000, input: 990, output: 5, cached: 100), [
        ActivityPurpose(Purpose.other, tokens(500)),
        ActivityPurpose(Purpose.debug, tokens(300)),
      ]),
      usage([
        ProviderQuota('Weekly', 95, now.add(const Duration(days: 1))),
      ]),
      now,
    );
    expect(tips, hasLength(5));
    expect(tips[0], contains('198 lần'));
    expect(tips[1], contains('10%'));
    expect(tips[2], contains('50%'));
    expect(tips[3], contains('30%'));
    expect(tips[4], contains('Weekly chỉ còn 5%'));
  });

  test('balanced usage and missing counters give no tips', () {
    final tips = usageTips(
      activity(tokens(100, input: 60, output: 40, cached: 50), [
        ActivityPurpose(Purpose.code, tokens(100)),
      ]),
      usage(),
      now,
    );
    expect(tips, isEmpty);
    expect(usageTips(activity(tokens(0), const []), usage(), now), isEmpty);
  });
}
