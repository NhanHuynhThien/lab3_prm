import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/reporting_calendar.dart';
import '../viewmodels/ledger_viewmodel.dart';
import 'common.dart';
import 'draft_guard.dart';
import 'ledger_feedback.dart';

class DataScopePicker extends ConsumerWidget {
  const DataScopePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = ref.watch(ledgerProvider).asData?.value.reportingTimezone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            PopupMenuButton<DataScope>(
              tooltip: 'Chọn nguồn dữ liệu báo cáo',
              initialValue: ref.watch(effectiveDataScopeProvider),
              onSelected: (scope) =>
                  ref.read(dataScopeProvider.notifier).select(scope),
              itemBuilder: (_) => DataScope.values
                  .map(
                    (scope) =>
                        PopupMenuItem(value: scope, child: Text(scope.label)),
                  )
                  .toList(),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ref.watch(effectiveDataScopeProvider).label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text('Múi giờ báo cáo'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const _ReportingSettingsScreen(),
                ),
              ),
            ),
          ],
        ),
        if (zone != null)
          Text(
            ReportingCalendar.zoneLabel(zone),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _ReportingSettingsScreen extends ConsumerStatefulWidget {
  const _ReportingSettingsScreen();
  @override
  ConsumerState<_ReportingSettingsScreen> createState() =>
      _ReportingSettingsState();
}

class _ReportingSettingsState extends ConsumerState<_ReportingSettingsScreen> {
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
      if (mounted) setState(() => _error = e.toString());
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
