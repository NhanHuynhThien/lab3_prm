import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';
import 'usage_form_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.accountId, this.purpose});
  final String? accountId;
  final Purpose? purpose;
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ledgerProvider).requireValue;
    final projection = ref.watch(
      historyProjectionProvider((widget.accountId, widget.purpose, _search)),
    );
    final sessions = projection.sessions;
    final summary = projection.summary;
    return ContentPage(
      title: 'Lịch sử sử dụng',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.purpose != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: StatusTag(widget.purpose!.label),
            ),
          if (widget.accountId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                data.account(widget.accountId!)?.alias ?? 'Tài khoản',
              ),
            ),
          const RangePicker(),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm công việc',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 24),
          Text(
            '${summary.count} phiên · ${money(summary.costMicros)} đã ghi · ${compactTokens(summary.tokens)} token',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.unknownCost} phiên chưa biết chi phí',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            const EmptyFeedback(
              title: 'Không có phiên phù hợp',
              message: 'Thử đổi khoảng thời gian hoặc từ khóa.',
            ),
          ...sessions.map(
            (s) => Column(
              children: [
                UsageRow(
                  session: s,
                  account: data.account(s.accountId),
                  onTap: () => showUsageDetail(context, s),
                ),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showUsageDetail(BuildContext context, UsageSession session) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _UsageDetailSheet(sessionId: session.id),
    );

class _UsageDetailSheet extends ConsumerWidget {
  const _UsageDetailSheet({required this.sessionId});
  final String sessionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ledgerProvider).requireValue;
    final session = data.sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Phiên không còn tồn tại.'),
      );
    }
    final account = data.account(session.accountId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '${account?.alias ?? 'Tài khoản'} · ${session.purpose.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _DetailLine('Chi phí nhập tay', money(session.costMicros)),
            _DetailLine(
              'Input token',
              session.inputTokens?.toString() ?? 'Chưa biết',
            ),
            _DetailLine(
              'Output token',
              session.outputTokens?.toString() ?? 'Chưa biết',
            ),
            _DetailLine(
              'Ngày sử dụng',
              '${shortDate(session.occurredAt)}/${session.occurredAt.year}',
            ),
            const _DetailLine('Nguồn', 'Nhập tay · local demo'),
            if (session.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(session.note),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (account != null && !account.archived)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UsageFormScreen(session: session),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa phiên'),
                  ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () async {
                    if (!await confirmAction(
                      context,
                      'Xóa phiên sử dụng?',
                      '${session.title} sẽ bị xóa; tổng chi phí và token được tính lại.',
                      confirm: 'Xóa phiên',
                    )) {
                      return;
                    }
                    try {
                      await ref
                          .read(ledgerProvider.notifier)
                          .deleteUsage(session.id);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) showMessage(context, e.toString());
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa phiên'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 16),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
