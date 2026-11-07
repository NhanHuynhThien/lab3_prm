import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:token_ledger/services/token_alert_store.dart';

void main() {
  test(
    'alerts once at 80% and once at 100% per cycle; new cycle re-arms',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = TokenAlertStore();
      Future<int?> claim(int tokens, [String cycle = 'c1']) => store.claimLevel(
        accountId: 'agent:codex',
        cycle: cycle,
        tokens: tokens,
        limit: 1000,
      );
      expect(await claim(700), isNull);
      expect(await claim(800), 80);
      expect(await claim(900), isNull);
      expect(await claim(1000), 100);
      expect(await claim(1200), isNull);
      expect(await claim(1200, 'c2'), 100);
      await store.saveLimit('agent:codex', 1000);
      expect(await store.loadLimits(), {'agent:codex': 1000});
      await store.saveLimit('agent:codex', null);
      expect(await store.loadLimits(), isEmpty);
    },
  );
}
