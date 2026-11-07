import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/gemini_aggregate.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/gemini_analysis_viewmodel.dart';
import 'common.dart';

class GeminiAnalysisCard extends ConsumerWidget {
  const GeminiAnalysisCard({super.key});
  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    GeminiAggregate data,
  ) async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phân tích bằng Gemini?'),
        content: Text(
          'Gửi tổng hợp ${data.sessionCount} phiên, ${data.totalTokens} token đã biết, chi phí ${money(data.costMicros)} và phân bổ mục đích/thời điểm tới backend TokenLedger rồi Gemini.\n\nKhông gửi tiêu đề công việc, ghi chú, tên tài khoản, email hay hội thoại. Chi phí chưa có nguồn xác nhận không phải hóa đơn.\n\n${data.knownTokenSessions}/${data.sessionCount} phiên có token; ${data.knownCostSessions}/${data.sessionCount} có chi phí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý phân tích'),
          ),
        ],
      ),
    );
    if (consent == true && context.mounted) {
      await ref.read(geminiAnalysisProvider.notifier).analyze(data);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregate = ref.watch(geminiAggregateProvider),
        state = ref.watch(geminiAnalysisProvider);
    final result = state.asData?.value;
    return Panel(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        expansionAnimationStyle: AnimationStyle(
          duration: AppMotion.duration(context, AppMotion.short),
          reverseDuration: AppMotion.duration(context, AppMotion.short),
        ),
        title: Row(
          children: [
            Image.asset('assets/providers/gemini.png', width: 28, height: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Phân tích với Gemini')),
          ],
        ),
        subtitle: const Text('Mục đích, chi phí, coverage và token API'),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini diễn giải sổ ghi nhận theo bộ lọc hiện tại. Tổng, tỷ trọng và coverage được tính trong ứng dụng; AI không bổ sung số liệu thiếu.',
              ),
              const SizedBox(height: 12),
              Text(
                '${aggregate.sessionCount} phiên · ${compactTokens(aggregate.totalTokens)} token đã biết · ${money(aggregate.costMicros)} chi phí ghi nhận',
              ),
              Text(
                '${aggregate.knownTokenSessions}/${aggregate.sessionCount} phiên có token · ${aggregate.knownCostSessions}/${aggregate.sessionCount} có chi phí',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isLoading || !aggregate.eligible
                      ? null
                      : () => _confirm(context, ref, aggregate),
                  icon: state.isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: MediaQuery.disableAnimationsOf(context)
                                ? .5
                                : null,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    state.isLoading
                        ? 'Đang phân tích…'
                        : 'Phân tích dữ liệu này',
                  ),
                ),
              ),
              if (!aggregate.eligible)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Cần ít nhất một phiên có token, trong kỳ tối đa 366 ngày.',
                  ),
                ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${state.error}',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              if (result != null) ...[
                const Divider(height: 32),
                Text(
                  'Kết quả gần nhất · ${result.sampleSessions} phiên · ${shortDate(result.periodStart.toLocal())} → ${shortDate(result.periodEnd.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  result.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                for (final section in [
                  (label: 'Nhận định', items: result.findings),
                  (label: 'Đề xuất', items: result.recommendations),
                  (label: 'Giới hạn dữ liệu', items: result.limitations),
                ])
                  if (section.items.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      section.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final item in section.items)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('• $item'),
                      ),
                  ],
                const Divider(height: 32),
                Text(
                  'Lượt gọi: ${result.model} · ${(result.elapsedMs / 1000).toStringAsFixed(1)} giây',
                ),
                Text(
                  'Token API: input ${result.usage['inputTokens'] ?? '—'} · output ${result.usage['outputTokens'] ?? '—'} · cache ${result.usage['cachedInputTokens'] ?? '—'} · reasoning ${result.usage['reasoningTokens'] ?? '—'} · tổng ${result.usage['totalTokens'] ?? '—'}',
                ),
                const Text(
                  'Thời gian trên là độ trễ API, không phải thời gian làm việc. Chi phí đã thanh toán cho lượt gọi: chưa có hóa đơn xác nhận.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
