import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agent_dashboard.dart';
import '../theme/app_theme.dart';
import '../viewmodels/token_limit_viewmodel.dart';
import 'common.dart';

/// Overall verdict across connected agents, shown above the agent cards.
///
/// Takes the already built [dashboard] so the projection is computed once.
class AgentSummaryCard extends ConsumerWidget {
  const AgentSummaryCard({
    super.key,
    required this.dashboard,
    required this.attentionOnly,
    required this.onAttentionTap,
  });
  final AgentDashboard dashboard;

  /// Whether the agent list below is filtered to agents needing attention.
  final bool attentionOnly;
  final VoidCallback onAttentionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(tokenLimitsProvider.select((m) => m.length));
    final attention = dashboard.attention;
    final ok = attention == 0;
    return Panel(
      color: ok ? AppColors.soft : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.verified_outlined : Icons.info_outline_rounded,
                color: ok ? AppColors.primary : AppColors.amber,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  ok ? 'Mọi agent đều ổn' : '$attention agent cần chú ý',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _Stat(
                icon: Icons.hub_outlined,
                color: AppColors.primary,
                value: dashboard.connected.length,
                label: 'Agent theo dõi',
              ),
              _Stat(
                icon: Icons.warning_amber_rounded,
                color: ok ? AppColors.muted : AppColors.amber,
                value: attention,
                label: attentionOnly ? 'Bỏ lọc' : 'Cần chú ý',
                selected: attentionOnly,
                onTap: ok ? null : onAttentionTap,
              ),
              _Stat(
                icon: Icons.notifications_active_outlined,
                color: AppColors.primary,
                value: alerts,
                label: 'Cảnh báo đã đặt',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.selected = false,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final bool selected;

  /// Null for read-only figures.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppSpace.controlRadius);
    return Expanded(
      child: Semantics(
        button: onTap != null,
        selected: selected,
        child: Material(
          color: selected ? AppColors.amberSoft : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpace.touch),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Column(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      '$value',
                      style: text.headlineMedium?.copyWith(color: color),
                    ),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
