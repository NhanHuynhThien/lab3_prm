import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/common.dart';
import 'account_form_screen.dart';
import 'purpose_screen.dart';

class UsageFormScreen extends ConsumerStatefulWidget {
  const UsageFormScreen({super.key, this.accountId, this.session});
  final String? accountId;
  final UsageSession? session;
  @override
  ConsumerState<UsageFormScreen> createState() => _UsageFormScreenState();
}

class _UsageFormScreenState extends ConsumerState<UsageFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title, _input, _output, _cost, _note;
  late final String _id;
  String? _accountId, _error;
  Purpose _purpose = Purpose.code;
  late DateTime _date;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _id = s?.id ?? ref.read(ledgerProvider.notifier).newId();
    _accountId = s?.accountId ?? widget.accountId;
    _title = TextEditingController(text: s?.title ?? '');
    _input = TextEditingController(text: s?.inputTokens?.toString() ?? '');
    _output = TextEditingController(text: s?.outputTokens?.toString() ?? '');
    _cost = TextEditingController(text: usdInput(s?.costMicros));
    _note = TextEditingController(text: s?.note ?? '');
    _purpose = s?.purpose ?? Purpose.code;
    _date = s?.occurredAt ?? ref.read(clockProvider)();
  }

  @override
  void dispose() {
    for (final c in [_title, _input, _output, _cost, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _tokenValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value.trim());
    return n == null || n < 0 || n > 1000000000
        ? 'Nhập số nguyên từ 0 đến 1 tỷ.'
        : null;
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_input.text.trim().isEmpty != _output.text.trim().isEmpty) {
      setState(
        () => _error = 'Nhập cả input và output token, hoặc để trống cả hai nếu chưa biết.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(ledgerProvider.notifier)
          .saveUsage(
            UsageSession(
              id: _id,
              accountId: _accountId!,
              title: _title.text.trim(),
              purpose: _purpose,
              occurredAt: _date,
              inputTokens: int.tryParse(_input.text.trim()),
              outputTokens: int.tryParse(_output.text.trim()),
              costMicros: parseUsd(_cost.text),
              note: _note.text.trim(),
            ),
          );
      if (mounted) {
        Navigator.pop(context);
        showMessage(context, 'Đã lưu phiên sử dụng trên thiết bị.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref
        .watch(ledgerProvider)
        .requireValue
        .accounts
        .where((a) => !a.archived)
        .toList();
    _accountId ??= accounts.firstOrNull?.id;
    if (accounts.isEmpty) {
      return ContentPage(
        title: 'Ghi sử dụng',
        child: EmptyFeedback(
          title: 'Thêm tài khoản trước',
          message: 'Mỗi phiên cần gắn với một tài khoản AI đang hoạt động.',
          action: 'Thêm tài khoản',
          onAction: () async {
            final id = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const AccountFormScreen()),
            );
            if (id != null && mounted) setState(() => _accountId = id);
          },
        ),
      );
    }
    return ContentPage(
      title: widget.session == null ? 'Ghi phiên sử dụng' : 'Sửa phiên sử dụng',
      footer: FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Đang lưu...' : 'Lưu phiên sử dụng'),
      ),
      child: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Dữ liệu nhập tay',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(labelText: 'Tài khoản AI'),
              items: accounts
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(a.alias, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: widget.session != null || _saving
                  ? null
                  : (v) => setState(() => _accountId = v),
              validator: (v) => v == null ? 'Chọn tài khoản.' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Đã dùng AI cho việc gì?',
                hintText: 'Ví dụ: Sửa lỗi Google Sign-In',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nhập tên công việc.' : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                final p = await Navigator.push<Purpose>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PurposeScreen(selected: _purpose),
                  ),
                );
                if (p != null && mounted) setState(() => _purpose = p);
              },
              child: Row(
                children: [
                  Icon(purposeIcon(_purpose)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Mục đích: ${_purpose.label}')),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Token sử dụng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Chưa biết số token? Để trống cả hai ô, không nhập 0 thay cho dữ liệu thiếu.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _input,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Input token'),
                    validator: _tokenValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _output,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Output token',
                    ),
                    validator: _tokenValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Chi phí đã biết · USD',
                hintText: '0.00',
                helperText: 'Để trống nếu chưa biết. Không tự quy đổi phí gói thành giá token.',
              ),
              validator: (v) {
                try {
                  parseUsd(v ?? '');
                  return null;
                } catch (e) {
                  return 'Nhập số USD không âm hợp lệ.';
                }
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final now = ref.read(clockProvider)();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: now,
                );
                if (date != null && mounted) {
                  setState(
                    () => _date = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      _date.hour,
                      _date.minute,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text('Ngày sử dụng: ${shortDate(_date)}/${_date.year}'),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _note,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
