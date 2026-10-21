import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/reporting_calendar.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/data_scope_picker.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/range_picker.dart';
import '../widgets/usage_detail_sheet.dart';
import '../widgets/usage_row.dart';

export '../widgets/usage_detail_sheet.dart';

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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _useAccountCycle = widget.useAccountCycle;
  }

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
