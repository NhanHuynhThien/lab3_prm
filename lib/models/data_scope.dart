import 'ai_account.dart';
import 'ledger_enums.dart';
import 'usage_session.dart';

enum DataScope {
  /// The user's real ledger: manual entries plus Companion auto-imports.
  manual('Dữ liệu của bạn'),
  demo('Dữ liệu demo'),
  legacy('Dữ liệu cũ');

  const DataScope(this.label);
  final String label;

  static bool _real(DataSource source) =>
      source == DataSource.manual || source == DataSource.companion;

  bool includes(UsageSession session) => switch (this) {
    DataScope.demo => session.isDemo,
    DataScope.manual => !session.isDemo && _real(session.dataSource),
    DataScope.legacy =>
      !session.isDemo && session.dataSource == DataSource.legacy,
  };

  bool includesAccount(AIAccount account, List<UsageSession> sessions) {
    if (account.isDemo != (this == DataScope.demo)) return false;
    final own = switch (this) {
      DataScope.manual => _real(account.dataSource),
      DataScope.demo => account.dataSource == DataSource.demo,
      DataScope.legacy => account.dataSource == DataSource.legacy,
    };
    return own || sessions.any((s) => s.accountId == account.id && includes(s));
  }
}
