import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/usage_calculator.dart';
import '../utils/formatters.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  UsageMetric _metric = UsageMetric.cost;
  @override
  Widget build(BuildContext context) {
    final projection = ref.watch(analyticsProjectionProvider(_metric));
    final summary = projection.summary;
    final shares = projection.shares;
    final total = projection.total;
    String format(int v) => switch (_metric) {
      UsageMetric.cost => money(v),
      UsageMetric.tokens => compactTokens(v),
      UsageMetric.sessions => '$v',
    };
    return ListView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 28),
      children: [
        const PageHeading(
          'Phân tích sử dụng',
          'Công việc nào đang dùng nhiều nguồn lực AI nhất?',
        ),
        const RangePicker(),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<UsageMetric>(
            segments: UsageMetric.values
                .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                .toList(),
            selected: {_metric},
            onSelectionChanged: (s) => setState(() => _metric = s.first),
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('Theo mục đích · ${_metric.label.toLowerCase()}'),
              if (total == 0)
                const EmptyFeedback(
                  title: 'Chưa có số liệu cho chỉ số này',
                  message: 'Bạn có thể đổi sang số phiên hoặc bổ sung dữ liệu sử dụng.',
                )
              else
                LayoutBuilder(
                  builder: (context, c) {
                    final legend = Column(
                      children: shares
                          .map(
                            (p) => InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      HistoryScreen(purpose: p.purpose),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color:
                                            PurposeRing.colors[shares
                                                .indexOf(p)
                                                .clamp(0, 3)],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(p.purpose.label)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(p.value / total * 100).toStringAsFixed(1)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      format(p.value),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                    final ring = Semantics(
                      label:
                          'Tổng ${format(total)}. Chi tiết từng mục đích ở danh sách.',
                      child: PurposeRing(shares: shares, center: format(total)),
                    );
                    return c.maxWidth >= 660
                        ? Row(
                            children: [
                              SizedBox(width: 240, child: Center(child: ring)),
                              const SizedBox(width: 32),
                              Expanded(child: legend),
                            ],
                          )
                        : Column(
                            children: [
                              ring,
                              const SizedBox(height: 20),
                              legend,
                            ],
                          );
                  },
                ),
              const SizedBox(height: 16),
              Text(
                '${summary.unknownCost} phiên thiếu chi phí · ${summary.unknownTokens} phiên thiếu token. Không tính dữ liệu thiếu là 0.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('So sánh tài khoản'),
              ...projection.comparisons.map((comparison) {
                final a = comparison.account;
                final s = comparison.summary;
                final value = comparison.value;
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(accountId: a.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                a.alias,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            Text(format(value)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedProgress(value: total == 0 ? 0 : value / total),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${s.count} phiên · ${s.unknownCost} phiên chưa biết chi phí',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (projection.comparisons.isEmpty)
                const Text('Chưa có tài khoản để so sánh.'),
            ],
          ),
        ),
      ],
    );
  }
}
