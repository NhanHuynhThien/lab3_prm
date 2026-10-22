import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/provider_connections_screen.dart';
import '../viewmodels/provider_sync_viewmodel.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../viewmodels/gemini_activity_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'common.dart';
import 'provider_overview_card.dart';
import 'provider_source_picker.dart';

class ProviderSyncSummary extends ConsumerWidget {
  const ProviderSyncSummary({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerSyncProvider);
    final rows = ref.watch(providerSourcesProvider);
    final selected = ref.watch(selectedSourceProvider);
    final usage = rows.firstWhere((r) => r.id == selected);
    final now = ref.watch(nowProvider);
    void open() => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ProviderConnectionsScreen(),
      ),
    );
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
                  : open,
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
        Text(
          state.working
              ? 'Đang cập nhật nguồn trên Mac...'
              : '${rows.where((r) => r.status == 'ready').length}/${rows.length} nguồn có dữ liệu · Chọn nguồn để xem',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        const ProviderSourcePicker(),
        const SizedBox(height: 16),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (state.working && rows.every((r) => r.status != 'ready'))
          const LinearProgressIndicator(semanticsLabel: 'Đang đọc nguồn AI'),
        ProviderOverviewCard(
          name: usage.name,
          usage: usage,
          now: now,
          onDetails: open,
          activity: ref.watch(geminiActivityProvider).summary,
        ),
      ],
    );
  }
}
