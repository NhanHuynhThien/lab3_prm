import 'ai_account.dart';
import 'ledger_enums.dart';
import 'usage_session.dart';

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
