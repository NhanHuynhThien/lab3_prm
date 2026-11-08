import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_features.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'crash_diagnostics_panel.dart';
import 'settings_group.dart';

/// Evidence controls (Remote Config, Analytics, Crashlytics), collapsed by
/// default because they are for verification rather than daily use.
class DiagnosticsGroup extends StatelessWidget {
  const DiagnosticsGroup({super.key});

  @override
  Widget build(BuildContext context) => const SettingsGroup(
    title: 'Chẩn đoán',
    children: [
      _CollapsibleRow(
        icon: Icons.tune_rounded,
        title: 'Thông tin kỹ thuật',
        child: _TechnicalInfo(),
      ),
      _CollapsibleRow(
        icon: Icons.bug_report_outlined,
        title: 'Chẩn đoán Crashlytics',
        child: CrashDiagnosticsActions(),
      ),
    ],
  );
}

class _CollapsibleRow extends StatelessWidget {
  const _CollapsibleRow({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: AppSpace.lg),
    shape: const Border(),
    collapsedShape: const Border(),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title),
    children: [child],
  );
}

class _TechnicalInfo extends ConsumerWidget {
  const _TechnicalInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(productConfigProvider);
    final analytics =
        ref.watch(analyticsStatusProvider).asData?.value ??
        const AnalyticsStatus();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phiên gần đây: ${config.recentLimit} · nguồn ${config.recentSource}',
          key: const ValueKey('config-recent-value'),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Cảnh báo ngân sách: ${config.warningPercent}% · nguồn ${config.warningSource}',
          key: const ValueKey('config-warning-value'),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          config.fetchedAt == null
              ? 'Chưa có lần lấy cấu hình thành công trong phiên app này.'
              : 'Kiểm tra cấu hình: ${shortDate(config.fetchedAt!)} lúc ${shortTime(config.fetchedAt!)}',
        ),
        if (config.error != null) ...[
          const SizedBox(height: AppSpace.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              config.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('refresh-product-config'),
            onPressed: config.refreshing
                ? null
                : () async {
                    final success = await ref
                        .read(productFeaturesProvider.notifier)
                        .refreshConfig();
                    if (context.mounted) {
                      showMessage(
                        context,
                        success
                            ? 'Đã lấy cấu hình khả dụng.'
                            : 'Chưa lấy được cấu hình. Giá trị cũ được giữ.',
                      );
                    }
                  },
            icon: const Icon(Icons.refresh),
            label: Text(
              config.refreshing ? 'Đang lấy cấu hình...' : 'Làm mới cấu hình',
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        const Divider(),
        const SizedBox(height: AppSpace.sm),
        Text(
          analytics.error ??
              (analytics.enabled
                  ? 'Analytics SDK: Sẵn sàng ghi nhận sự kiện.'
                  : 'Analytics: Chưa sẵn sàng.'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (analytics.lastEvent != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              'Sự kiện SDK nhận gần nhất: ${analytics.lastEvent}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
