/// Primary workspace destinations, in navigation order.
///
/// [name] doubles as the analytics screen name and the notification route
/// segment (`/overview`, `/accounts`, ...), so tabs, telemetry and deep links
/// cannot drift apart.
enum WorkspaceTab {
  overview('Tổng quan'),
  accounts('Tài khoản'),
  analytics('Phân tích'),
  profile('Cá nhân');

  const WorkspaceTab(this.label);

  /// Navigation label; a tab's page heading reuses it so the two match.
  final String label;

  String get route => '/$name';

  static WorkspaceTab? fromRoute(String route) {
    for (final tab in values) {
      if (tab.route == route) return tab;
    }
    return null;
  }

  static bool isScreenName(String screen) =>
      values.any((tab) => tab.name == screen);
}
