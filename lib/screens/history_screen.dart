import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/data_scope_picker.dart';
import '../services/reporting_calendar.dart';
import '../widgets/ledger_feedback.dart';
import 'dashboard_screen.dart';
import 'usage_form_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    super.key,
    this.accountId,
    this.purpose,
    this.provider,
    this.useAccountCycle = false,
  });
  final String? accountId;
  final Purpose? purpose;
  final String? provider;
  final bool useAccountCycle;
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _search = '';
  late bool _useAccountCycle;
  @override
  void initState() {
    super.initState();
    _useAccountCycle = widget.useAccountCycle;
  }

  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Lịch sử sử dụng');
    if (feedback != null) return feedback;
    final data = state.requireValue;
    final projection = ref.watch(
      historyQueryProjectionProvider((
        accountId: widget.accountId,
        purpose: widget.purpose,
        provider: widget.provider,
        search: _search,
        useAccountCycle: _useAccountCycle,
      )),
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
          if (widget.provider != null)
            StatusTag('Nhà cung cấp: ${widget.provider}'),
          const DataScopePicker(),
          const SizedBox(height: 16),
          if (widget.accountId != null)
            OutlinedButton(
              onPressed: () =>
                  setState(() => _useAccountCycle = !_useAccountCycle),
              child: Text(
                _useAccountCycle
                    ? 'Kỳ ngân sách tài khoản · Đổi sang kỳ báo cáo'
                    : 'Xem kỳ ngân sách tài khoản',
              ),
            ),
          if (!_useAccountCycle) const RangePicker(),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
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
          for (var i = 0; i < sessions.length; i++) ...[
            if (i == 0 ||
                ReportingCalendar.dayKey(
                      sessions[i].occurredAt,
                      data.reportingTimezone,
                    ) !=
                    ReportingCalendar.dayKey(
                      sessions[i - 1].occurredAt,
                      data.reportingTimezone,
                    ))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  ReportingCalendar.dayKey(
                    sessions[i].occurredAt,
                    data.reportingTimezone,
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            UsageRow(
              timezone: data.reportingTimezone,
              session: sessions[i],
              account: data.account(sessions[i].accountId),
              onTap: () => showUsageDetail(context, sessions[i]),
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}

Future<void> showUsageDetail(BuildContext context, UsageSession session) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
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
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Lịch sử sử dụng');
    if (feedback != null) return feedback;
    final data = state.requireValue;
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
              ReportingCalendar.dayKey(
                session.occurredAt,
                data.reportingTimezone,
              ),
            ),
            _DetailLine(
              'Giờ báo cáo',
              '${shortTime(session.occurredAt, timezone: data.reportingTimezone)} · ${ReportingCalendar.zoneLabel(data.reportingTimezone)}',
            ),
            _DetailLine('Nguồn', session.dataSource.label),
            _DetailLine('Loại chi phí', session.effectiveCostBasis.label),
            _DetailLine(
              'Phân loại',
              session.isDemo ? 'Demo giả định' : 'Dữ liệu theo dõi',
            ),
            _DetailLine('Model', session.modelId ?? 'Chưa biết'),
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
                if (account != null)
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
                ConfirmedActionButton(
                  label: 'Xóa phiên',
                  icon: Icons.delete_outline,
                  destructive: true,
                  title: 'Xóa phiên sử dụng?',
                  message:
                      '${session.title} sẽ bị xóa; tổng chi phí và token được tính lại. Không thể hoàn tác.',
                  onConfirm: () =>
                      ref.read(ledgerProvider.notifier).deleteUsage(session.id),
                  onSuccess: () => Navigator.pop(context),
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
