import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/common.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});
  final AIAccount? account;
  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _alias, _product, _plan, _budget;
  late String _provider;
  late BillingMode _billing;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _alias = TextEditingController(text: a?.alias ?? '');
    _product = TextEditingController(text: a?.product ?? 'Claude');
    _plan = TextEditingController(text: a?.plan ?? 'Cá nhân');
    _budget = TextEditingController(text: usdInput(a?.budgetMicros));
    _provider = a?.provider ?? 'Anthropic';
    _billing = a?.billingMode ?? BillingMode.subscription;
  }

  @override
  void dispose() {
    for (final c in [_alias, _product, _plan, _budget]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final vm = ref.read(ledgerProvider.notifier);
      final account = AIAccount(
        id: widget.account?.id ?? vm.newId(),
        alias: _alias.text.trim(),
        provider: _provider,
        product: _product.text.trim(),
        billingMode: _billing,
        plan: _plan.text.trim(),
        budgetMicros: parseUsd(_budget.text),
        createdAt: widget.account?.createdAt ?? ref.read(clockProvider)(),
        archived: widget.account?.archived ?? false,
        quota: widget.account?.quota,
      );
      await vm.saveAccount(account);
      if (mounted) {
        Navigator.pop(context, account.id);
        showMessage(context, 'Đã lưu tài khoản trên thiết bị.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ContentPage(
    title: widget.account == null ? 'Thêm tài khoản AI' : 'Sửa tài khoản',
    footer: FilledButton(
      onPressed: _saving ? null : _save,
      child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Lưu tài khoản'),
    ),
    child: Form(
      key: _key,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Panel(
            color: AppColors.soft,
            child: Text(
              'Đây là hồ sơ theo dõi tài khoản AI. Bạn không cần nhập mật khẩu hoặc API key.',
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _alias,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Tên tài khoản',
              hintText: 'Ví dụ: Codex học tập',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập tên tài khoản.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _provider,
            decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
            items: [
              'Anthropic',
              'OpenAI',
              'Google',
              'Khác',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: _saving ? null : (s) => setState(() => _provider = s!),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _product,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Công cụ / sản phẩm',
              hintText: 'Claude, Codex, Gemini...',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nhập tên công cụ.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BillingMode>(
            initialValue: _billing,
            decoration: const InputDecoration(labelText: 'Cách tính phí'),
            items: BillingMode.values
                .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
                .toList(),
            onChanged: _saving ? null : (b) => setState(() => _billing = b!),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _plan,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Tên gói (tùy chọn)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Ngân sách theo dõi mỗi tháng · USD',
              hintText: '20.00',
              helperText: 'Để trống nếu chưa đặt ngân sách.',
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
          const Text(
            'Ngân sách tự đặt không phải số dư API hay hạn mức thuê bao. Chu kỳ demo là tháng dương lịch trên thiết bị.',
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
