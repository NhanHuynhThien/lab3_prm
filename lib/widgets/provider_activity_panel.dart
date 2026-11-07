import 'package:flutter/material.dart';

import '../models/provider_activity.dart';
import '../models/ledger_enums.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'provider_task_list.dart';

class ProviderActivityPanel extends StatelessWidget {
  const ProviderActivityPanel({
    super.key,
    required this.activity,
    this.tips = const [],
  });
  final ProviderActivity activity;
  final List<String> tips;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Token đã dùng cho việc gì?'),
              Text(
                '${exactTokens(activity.tokens.total)} token',
                style: text.headlineSmall,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                '${fullDate(activity.start)} → ${fullDate(activity.end)} · 30 ngày',
                style: text.bodySmall,
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.xl,
                runSpacing: AppSpace.sm,
                children: [
                  _Fact(Icons.forum_outlined, '${activity.sessionCount} phiên'),
                  _Fact(
                    Icons.task_alt_rounded,
                    '${activity.taskCount} công việc',
                  ),
                  _Fact(
                    Icons.calendar_month_outlined,
                    '${activity.activeDays} ngày có token',
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              if (activity.partial) ...[
                const StatusTag('Dữ liệu một phần', warning: true),
                const SizedBox(height: AppSpace.sm),
                const Text(
                  'Một số tệp không đọc được hoặc vượt giới hạn. Tổng dưới đây chỉ gồm phần đã đọc.',
                ),
                const SizedBox(height: AppSpace.lg),
              ],
              TokenBreakdown(tokens: activity.tokens),
              const Divider(height: AppSpace.xxl),
              Text(
                'Chi phí đã thanh toán: Chưa có hóa đơn',
                style: text.titleSmall,
              ),
              const SizedBox(height: AppSpace.sm),
              const Text(
                'Chưa xác định phí cho từng công việc. Token trong gói thuê bao không được quy đổi thành tiền đã trừ. Chi phí tự ghi được báo cáo riêng bên dưới.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Gợi ý tối ưu'),
              if (tips.isEmpty)
                Text(
                  'Chưa thấy điểm cần tối ưu trong 30 ngày qua.',
                  style: text.bodySmall,
                ),
              for (final tip in tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Phân bổ theo mục đích'),
              const Text(
                'Phân loại tự động bằng từ khóa; mục mơ hồ được giữ là Khác. Chạm một mục để xem công việc tương ứng.',
              ),
              for (final p in activity.purposes) ...[
                const SizedBox(height: AppSpace.lg),
                ActionSurface(
                  onTap: () => _details(context, p.purpose),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              purposeIcon(p.purpose),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Text(
                                p.purpose.label,
                                style: text.titleSmall,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          '${exactTokens(p.tokens.total)} token · ${(activity.share(p.tokens) * 100).toStringAsFixed(1)}%',
                        ),
                        const SizedBox(height: AppSpace.sm),
                        LinearProgressIndicator(
                          value: activity.share(p.tokens),
                          semanticsLabel: p.purpose.label,
                          semanticsValue:
                              '${(activity.share(p.tokens) * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Sử dụng theo thời gian'),
              Text(
                '${exactTokens(activity.recentSevenTokens)} token · 7 ngày UTC gần nhất',
                style: text.titleSmall,
              ),
              const SizedBox(height: AppSpace.sm),
              const Text(
                'Ngày bên dưới tính theo UTC để đối chiếu log. Thời điểm công việc hiển thị theo giờ thiết bị.',
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Xem từng ngày và input/output'),
                children: [
                  for (final d in activity.daily.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${fullDate(d.day)} · ${exactTokens(d.tokens.total)} token',
                            style: text.titleSmall,
                          ),
                          Text(
                            'Input ${exactTokens(d.tokens.input)} · Output ${exactTokens(d.tokens.output)}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Divider(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _details(context, null),
                  icon: const Icon(Icons.manage_search_rounded),
                  label: const Text('Xem từng công việc và thời lượng'),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Cách tính và giới hạn dữ liệu'),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.lg),
                    child: Text(activity.method),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _details(BuildContext context, Purpose? purpose) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) =>
          ProviderTaskList(activity: activity, initialPurpose: purpose),
    ),
  );
}

class TokenBreakdown extends StatelessWidget {
  const TokenBreakdown({super.key, required this.tokens});
  final ActivityTokens tokens;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final row in [
        ('Input · gồm ngữ cảnh và cache', tokens.input),
        ('Output', tokens.output),
        ('Cache đọc · nằm trong input', tokens.cached),
        ('Cache ghi · nằm trong input', tokens.cacheWrite),
        ('Reasoning · nằm trong output', tokens.reasoning),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: AdaptivePair(
            breakpoint: 260,
            leading: Text(row.$1),
            trailing: Text(
              exactTokens(row.$2),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: AppSpace.sm),
      Flexible(child: Text(label)),
    ],
  );
}
