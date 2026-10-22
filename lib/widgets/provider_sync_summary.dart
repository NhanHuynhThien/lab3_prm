import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/provider_connections_screen.dart';
import '../theme/app_theme.dart';
import '../viewmodels/provider_sync_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'common.dart';
import 'provider_overview_card.dart';

class ProviderSyncSummary extends ConsumerStatefulWidget {
  const ProviderSyncSummary({super.key});
  @override
  ConsumerState<ProviderSyncSummary> createState() => _ProviderSummaryState();
}

class _ProviderSummaryState extends ConsumerState<ProviderSyncSummary> {
  String _selected = 'codex';
  static const _labels = {
    'codex': 'Codex',
    'claude': 'Claude',
    'google': 'Gemini',
    'antigravity': 'Antigravity',
  };

  void _open() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const ProviderConnectionsScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerSyncProvider);
    final rows = state.snapshot?.providers ?? [];
    final usage = rows.where((r) => r.id == _selected).firstOrNull;
    final now = ref.watch(nowProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle('Hoạt động AI')),
            IconButton(
              tooltip: state.enabled ? 'Cập nhật nguồn AI' : 'Kết nối nguồn AI',
              onPressed: state.working
                  ? null
                  : state.enabled
                  ? ref.read(providerSyncProvider.notifier).refresh
                  : _open,
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        Text(
          state.working
              ? 'Đang đọc nguồn trên Mac...'
              : rows.isEmpty
              ? 'Chưa kết nối nguồn dữ liệu'
              : '${rows.where((r) => r.status == 'ready').length}/3 nguồn đã có số liệu',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _labels.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _selected == entry.key,
                onSelected: (_) => setState(() => _selected = entry.key),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.working && rows.isEmpty)
          const LinearProgressIndicator(semanticsLabel: 'Đang đọc nguồn AI'),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              state.error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 12),
        ],
        AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.short),
          child: ProviderOverviewCard(
            key: ValueKey(_selected),
            name: _labels[_selected]!,
            usage: usage,
            now: now,
            onDetails: _open,
            unsupported: _selected == 'antigravity',
          ),
        ),
      ],
    );
  }
}
