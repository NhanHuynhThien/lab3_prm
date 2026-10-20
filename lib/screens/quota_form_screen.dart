import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/common.dart';

class QuotaFormScreen extends ConsumerStatefulWidget {
  const QuotaFormScreen({super.key, required this.account});
  final AIAccount account;
  @override
  ConsumerState<QuotaFormScreen> createState() => _QuotaFormScreenState();
}

class _QuotaFormScreenState extends ConsumerState<QuotaFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _percent, _window;
  late DateTime _reset;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _percent = TextEditingController(
      text: '${widget.account.quota?.usedPercent ?? 0}',
    );
    _window = TextEditingController(
      text: widget.account.quota?.window ?? '5 giờ',
    );
    final now = ref.read(clockProvider)();
    _reset = widget.account.quota?.resetAt ?? now.add(const Duration(hours: 5));
    if (!_reset.isAfter(now)) _reset = now.add(const Duration(hours: 5));
  }

  @override
  void dispose() {
    _percent.dispose();
    _window.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(ledgerProvider.notifier)
          .updateQuota(
            widget.account.id,
            QuotaSnapshot(
              window: _window.text.trim(),
              usedPercent: int.parse(_percent.text),
              observedAt: ref.read(clockProvider)(),
              resetAt: _reset,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Cập nhật hạn mức',
    footer: FilledButton(
      onPressed: _saving ? null : _save,
      child: Text(_saving ? 'Đang lưu...' : 'Lưu hạn mức nhập tay'),
    ),
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Panel(
            color: AppColors.soft,
            child: Text(
              'Nhập số liệu bạn thấy trên trang usage của nhà cung cấp. Hạn mức này độc lập với token và ngân sách tự đặt.',
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _window,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Cửa sổ hạn mức',
              hintText: '5 giờ / hàng tuần',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Nhập tên cửa sổ hạn mức.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _percent,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Đã dùng · %',
              suffixText: '%',
            ),
            validator: (v) {
              final p = int.tryParse(v ?? '');
              return p == null || p < 0 || p > 100
                  ? 'Nhập số nguyên từ 0 đến 100.'
                  : null;
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final now = ref.read(clockProvider)();
              final date = await showDatePicker(
                context: context,
                initialDate: _reset,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 366)),
              );
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_reset),
              );
              if (time != null && mounted) {
                setState(
                  () => _reset = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            },
            icon: const Icon(Icons.schedule),
            label: Text('Reset ${shortDate(_reset)} lúc ${shortTime(_reset)}'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Khi quá thời gian reset, app sẽ yêu cầu cập nhật thay vì tự suy ra quota đã về 100%.',
            style: TextStyle(color: AppColors.muted),
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
