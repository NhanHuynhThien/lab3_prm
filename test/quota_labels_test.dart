import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/provider_usage.dart';
import 'package:token_ledger/utils/formatters.dart';

void main() {
  test('quota copy says used and left, without provider bucket names', () {
    final q = ProviderQuota(
      'Claude and GPT models · Weekly Limit Remaining · weekly',
      75,
      DateTime(2026, 11, 14, 10, 45),
      group: 'Claude and GPT models',
      window: 'weekly',
    );
    expect(q.usageLabel, 'Đã dùng 75% · còn 25%');
    expect(q.scopeLabel, 'Claude và GPT · 7 ngày');
    expect(q.scopeLabel, isNot(contains('Remaining')));
    final codex = ProviderQuota('codex · 300 phút', 10, DateTime(2026));
    expect(codex.scopeLabel, '5 giờ');
  });

  test('reset label names the day unless it is today', () {
    final now = DateTime(2026, 11, 10, 9);
    expect(resetLabel(DateTime(2026, 11, 10, 10, 45), now), '10:45 hôm nay');
    expect(resetLabel(DateTime(2026, 11, 14, 10, 45), now), '10:45 ngày 14/11');
  });
}
