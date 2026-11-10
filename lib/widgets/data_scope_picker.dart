import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/reporting_calendar.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'common.dart';
import 'draft_guard.dart';
import 'ledger_feedback.dart';
import 'range_picker.dart';

class DataScopePicker extends ConsumerWidget {
  const DataScopePicker({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(effectiveDataScopeProvider);
    final data = ref.watch(ledgerProvider).asData?.value;
    // Only old local snapshots carry legacy data; otherwise there is no choice.
    final hasChoice =
        scope != DataScope.manual ||
        (data?.sessions.any(DataScope.legacy.includes) ?? false) ||
        (data?.accounts.any((a) => a.dataSource == DataSource.legacy) ?? false);
    // Nothing to choose: render nothing rather than a lone control.
    if (!hasChoice) return const SizedBox.shrink();
    final picker = PopupMenuButton<DataScope>(
      tooltip: 'Chọn nguồn dữ liệu báo cáo',
      icon: compact ? const Icon(Icons.filter_alt_outlined) : null,
      initialValue: ref.watch(effectiveDataScopeProvider),
      onSelected: (scope) => ref.read(dataScopeProvider.notifier).select(scope),
      itemBuilder: (_) => DataScope.values
          .where((scope) => scope != DataScope.demo)
          .map((scope) => PopupMenuItem(value: scope, child: Text(scope.label)))
          .toList(),
      child: compact
          ? null
          : FilterButton(ref.watch(effectiveDataScopeProvider).label),
    );
    return compact
        ? picker
        : Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(alignment: Alignment.centerLeft, child: picker),
          );
  }
}

/// Reporting timezone, a rarely changed setting opened from Profile.
class ReportingSettingsScreen extends ConsumerStatefulWidget {
  const ReportingSettingsScreen({super.key});
  @override
  ConsumerState<ReportingSettingsScreen> createState() =>
      _ReportingSettingsState();
}

class _ReportingSettingsState extends ConsumerState<ReportingSettingsScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _zone;
  late final String _initial;
  late final int? _revision;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _revision =
        ref.read(ledgerProvider.notifier).settingsRevision ??
        (ref.read(ledgerProvider.notifier).isCloud ? 0 : null);
    _initial =
        ref.read(ledgerProvider).asData?.value.reportingTimezone ??
        'Asia/Ho_Chi_Minh';
    _zone = TextEditingController(text: _initial);
  }

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(ledgerProvider.notifier)
          .setReportingTimezone(_zone.text.trim(), expectedRevision: _revision);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => DraftGuard(
    controllers: [_zone],
    hasChanges: () => _zone.text != _initial,
    saving: _saving,
    child:
        ledgerFeedback(ref.watch(ledgerProvider), 'Múi giờ báo cáo') ??
        ContentPage(
          title: 'Múi giờ báo cáo',
          footer: SaveButton(
            label: 'Lưu múi giờ',
            saving: _saving,
            onPressed: _save,
          ),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  key: const ValueKey('reporting-timezone'),
                  controller: _zone,
                  decoration: const InputDecoration(
                    labelText: 'Múi giờ IANA',
                    helperText: 'Ví dụ Asia/Ho_Chi_Minh, UTC, America/New_York. device giữ múi giờ thiết bị.',
                  ),
                  validator: (v) {
                    try {
                      ReportingCalendar.validateZone((v ?? '').trim());
                      return null;
                    } catch (_) {
                      return 'Múi giờ IANA không hợp lệ.';
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đổi cách chia ngày/tháng của báo cáo; không sửa thời điểm usage đã lưu. Ngân sách từng tài khoản vẫn dùng múi giờ và ngày bắt đầu kỳ trên tài khoản đó.',
                ),
                if (_error != null) Text(_error!),
              ],
            ),
          ),
        ),
  );
}
