import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usage_tips.dart';
import '../models/provider_analysis.dart';
import '../theme/app_theme.dart';
import '../viewmodels/gemini_activity_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/provider_sources_viewmodel.dart';
import '../viewmodels/provider_sync_viewmodel.dart';
import 'common.dart';
import 'gemini_web_import_panel.dart';
import 'provider_source_picker.dart';
import 'provider_usage_card.dart';
import 'antigravity_analysis_panel.dart';
import 'provider_activity_panel.dart';
import 'provider_brand_icon.dart';

class ProviderAnalyticsPanel extends ConsumerWidget {
  const ProviderAnalyticsPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(providerSourcesProvider);
    final selected = ref.watch(selectedSourceProvider);
    final source = sources.firstWhere((s) => s.id == selected);
    final now = ref.watch(nowProvider);
    final state = ref.watch(providerSyncProvider);
    final assessment = ProviderAnalysis.evaluate(source, now);
    final activity = ref.watch(geminiActivityProvider).summary;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProviderSourcePicker(),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProviderBrandIcon(source.id),
                  const SizedBox(width: 12),
                  Expanded(child: Text(source.name, style: theme.titleLarge)),
                  if (state.enabled)
                    IconButton(
                      tooltip: 'Cập nhật số liệu',
                      onPressed: state.working
                          ? null
                          : ref.read(providerSyncProvider.notifier).refresh,
                      icon: const Icon(Icons.sync_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              StatusTag(
                source.status == 'ready' ? 'Có dữ liệu' : 'Chờ kết nối',
                neutral: source.status != 'ready',
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: Icon(
                  assessment.warning
                      ? Icons.info_outline
                      : Icons.insights_outlined,
                  color: assessment.warning
                      ? AppColors.amber
                      : AppColors.primary,
                ),
                title: Text(assessment.title, style: theme.titleSmall),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(assessment.message),
                  ),
                ],
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (source.activity != null) ...[
          const SizedBox(height: 16),
          ProviderActivityPanel(
            activity: source.activity!,
            tips: usageTips(source.activity!, source, now),
          ),
        ],
        if (source.id == 'gemini-web') ...[
          if (activity != null) ...[
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Tần suất Gemini web · 30 ngày'),
                  Text(
                    '${activity.activityCount} hoạt động',
                    style: theme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${activity.activeDays} ngày có sử dụng · Cao nhất ${activity.busiestDayCount} hoạt động/ngày',
                  ),
                  const SizedBox(height: 24),
                  const Text('7 ngày gần nhất · ngày UTC'),
                  const SizedBox(height: 16),
                  _ActivityBars(
                    daily: activity.dailyCounts,
                    now: activity.importedAt,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const GeminiWebImportPanel(),
        ] else if (source.id == 'antigravity' && source.status == 'ready') ...[
          AntigravityAnalysisPanel(source: source, now: now),
        ] else if (source.status == 'ready') ...[
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Quota, gói và phạm vi nguồn'),
            initiallyExpanded: source.activity == null,
            children: [
              ProviderUsageCard(usage: source, now: now, showModels: false),
            ],
          ),
        ] else
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Báo cáo sẽ có khi nối nguồn'),
                Text(source.coverage),
              ],
            ),
          ),
        if (source.models.isNotEmpty) ...[
          const SizedBox(height: 16),
          Panel(child: _ModelDistribution(sourceId: source.id)),
        ],
      ],
    );
  }
}

class _ModelDistribution extends ConsumerWidget {
  const _ModelDistribution({required this.sourceId});
  final String sourceId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref
        .watch(providerSourcesProvider)
        .firstWhere((s) => s.id == sourceId);
    final models = [...source.models]
      ..sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    final total = models.fold<int>(0, (n, m) => n + m.totalTokens);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Phân bố token giữa các model'),
        Text(
          'Tỷ trọng trong các model có ghi nhận của cùng nguồn. ${source.modelsCoverage}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final model in models) ...[
          const SizedBox(height: 20),
          Text(model.model, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total == 0 ? 0 : model.totalTokens / total,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: model.model,
            semanticsValue: total == 0
                ? '0%'
                : '${(model.totalTokens / total * 100).toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          Text(
            '${model.totalTokens} token · ${total == 0 ? '0' : (model.totalTokens / total * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ActivityBars extends StatelessWidget {
  const _ActivityBars({required this.daily, required this.now});
  final Map<String, int> daily;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (i) => now.toUtc().subtract(Duration(days: 6 - i)),
    );
    final values = dates
        .map((d) => daily[d.toIso8601String().substring(0, 10)] ?? 0)
        .toList();
    final max = values.fold<int>(1, (a, b) => a > b ? a : b);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 48 * MediaQuery.textScalerOf(context).scale(1),
                child: Column(
                  children: [
                    Text(
                      '${values[i]}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: values[i] == 0 ? 2 : 100 * values[i] / max,
                          width: 24,
                          decoration: BoxDecoration(
                            color: values[i] == 0
                                ? AppColors.line
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${dates[i].day}/${dates[i].month}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
