import 'package:flutter/material.dart';

import '../models/provider_activity.dart';
import '../models/ledger_enums.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'provider_activity_panel.dart';

class ProviderTaskList extends StatefulWidget {
  const ProviderTaskList({
    super.key,
    required this.activity,
    this.initialPurpose,
  });
  final ProviderActivity activity;
  final Purpose? initialPurpose;
  @override
  State<ProviderTaskList> createState() => _ProviderTaskListState();
}

class _ProviderTaskListState extends State<ProviderTaskList> {
  Purpose? _purpose;
  int _limit = 10;
  @override
  void initState() {
    super.initState();
    _purpose = widget.initialPurpose;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.activity.tasksFor(_purpose);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết công việc')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpace.dashboardWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              const Text(
                'Chỉ hiện nhãn mục đích và mã đối chiếu. Nội dung yêu cầu/chat không nằm trong báo cáo.',
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _purpose == null,
                    onSelected: (_) => setState(() {
                      _purpose = null;
                      _limit = 10;
                    }),
                  ),
                  for (final p in widget.activity.purposes)
                    ChoiceChip(
                      label: Text(p.purpose.label),
                      selected: _purpose == p.purpose,
                      onSelected: (_) => setState(() {
                        _purpose = p.purpose;
                        _limit = 10;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Text('${tasks.length} công việc trong danh sách gần nhất'),
              if (widget.activity.omittedTasks > 0)
                Text(
                  'Đã thu gọn ${widget.activity.omittedTasks} công việc cũ. Tổng token và phân bổ mục đích vẫn gồm toàn bộ phần log đã đọc.',
                ),
              if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpace.xl),
                  child: Text(
                    'Không có chi tiết công việc trong phần lịch sử gần nhất.',
                  ),
                ),
              for (final task in tasks.take(_limit))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.lg),
                  child: _TaskCard(task),
                ),
              if (tasks.length > _limit)
                TextButton(
                  onPressed: () => setState(() => _limit += 10),
                  child: const Text('Xem thêm 10 công việc'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard(this.task);
  final ActivityTask task;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String time(DateTime d) => '${fullDate(d.toLocal())} ${shortTime(d)}';
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(purposeIcon(task.purpose), color: AppColors.primary),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(task.purpose.label, style: text.titleLarge)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          SelectableText(
            'Công việc ${task.id.substring(0, 8)} · Phiên ${task.sessionId.substring(0, 8)}',
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            '${exactTokens(task.tokens.total)} token',
            style: text.headlineSmall,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Model: ${task.models.isEmpty ? 'Chưa xác định' : task.models.join(', ')}',
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Bắt đầu: ${task.startedAt == null ? 'Không có mốc trong log' : time(task.startedAt!)}',
          ),
          Text('Token cuối: ${time(task.endedAt)}'),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Khoảng ghi nhận: ${elapsedLabel(task.elapsedSeconds)}',
            style: text.titleSmall,
          ),
          const Text(
            'Bao gồm thời gian chờ/nghỉ giữa các lượt; không đo thời gian model chạy thực tế.',
          ),
          const Divider(height: AppSpace.xxl),
          TokenBreakdown(tokens: task.tokens),
          const Divider(height: AppSpace.xxl),
          const Text('Chi phí công việc: Chưa xác định'),
          const Text('Chưa có hóa đơn hoặc đơn giá đã xác nhận cho phiên này.'),
        ],
      ),
    );
  }
}
