import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/reporting_calendar.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/reporting_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/data_scope_picker.dart';
import '../widgets/history_filter_bar.dart';
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
  late String? _accountId, _provider;
  late Purpose? _purpose;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _useAccountCycle = widget.useAccountCycle;
    _accountId = widget.accountId;
    _provider = widget.provider;
    _purpose = widget.purpose;
  }

  void _selectAccount(String? id) => setState(() {
    _accountId = id;
    _useAccountCycle = _useAccountCycle && id != null;
  });

  /// An account of another provider could never match, so it is cleared.
  void _selectProvider(String? provider, LedgerData data) => setState(() {
    _provider = provider;
    final account = data.account(_accountId ?? '');
    if (provider != null && account != null && account.provider != provider) {
      _accountId = null;
      _useAccountCycle = false;
    }
  });

  void _clearFilters() => setState(() {
    _accountId = null;
    _provider = null;
    _purpose = null;
    _useAccountCycle = false;
  });

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
        accountId: _accountId,
        purpose: _purpose,
        provider: _provider,
        search: _search,
        useAccountCycle: _useAccountCycle,
      )),
    );
    final sessions = projection.sessions;
    final summary = projection.summary;

    final zone = data.reportingTimezone;
    final header = <Widget>[
      const DataScopePicker(),
      const SizedBox(height: 16),
      HistoryFilterBar(
        accounts: data.accounts,
        accountId: _accountId,
        purpose: _purpose,
        provider: _provider,
        onAccount: _selectAccount,
        onPurpose: (p) => setState(() => _purpose = p),
        onProvider: (p) => _selectProvider(p, data),
      ),
      if (_accountId != null || _purpose != null || _provider != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _clearFilters,
            child: const Text('Xóa bộ lọc'),
          ),
        ),
      const SizedBox(height: 16),
      if (_accountId != null)
        OutlinedButton(
          onPressed: () => setState(() => _useAccountCycle = !_useAccountCycle),
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
          message: 'Thử đổi khoảng thời gian, bộ lọc hoặc từ khóa.',
        ),
    ];

    // Built lazily: a long history only lays out the rows on screen.
    return ContentPage(
      title: 'Lịch sử sử dụng',
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: header.length + sessions.length,
        itemBuilder: (context, index) {
          if (index < header.length) return header[index];
          final i = index - header.length;
          final session = sessions[i];
          final day = ReportingCalendar.dayKey(session.occurredAt, zone);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (i == 0 ||
                  day !=
                      ReportingCalendar.dayKey(
                        sessions[i - 1].occurredAt,
                        zone,
                      ))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              UsageRow(
                timezone: zone,
                session: session,
                account: data.account(session.accountId),
                onTap: () => showUsageDetail(context, session),
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}
