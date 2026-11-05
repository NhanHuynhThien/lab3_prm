import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/ledger_validation.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/account_form_fields.dart';
import '../widgets/common.dart';
import '../widgets/draft_guard.dart';
import '../widgets/ledger_feedback.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});
  final AIAccount? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _alias,
      _product,
      _plan,
      _budget,
      _model,
      _timezone,
      _cycle;
  late Set<Purpose> _purposes;
  late final Set<Purpose> _initialPurposes;
  late String _provider;
  late BillingMode _billing;
  late final String _id;
  late final DateTime _createdAt;
  late final int? _revision;
  late final List<String> _initialText;
  late final String _initialProvider;
  late final BillingMode _initialBilling;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _createdAt = a?.createdAt ?? ref.read(clockProvider)();
    _alias = TextEditingController(text: a?.alias ?? '');
    _product = TextEditingController(text: a?.product ?? 'Claude');
    _plan = TextEditingController(text: a?.plan ?? 'Cá nhân');
    _budget = TextEditingController(text: usdInput(a?.budgetMicros));
    _model = TextEditingController(text: a?.defaultModelId ?? '');
    _timezone = TextEditingController(text: a?.timezone ?? 'Asia/Ho_Chi_Minh');
    _cycle = TextEditingController(text: (a?.cycleStartDay ?? 1).toString());
    _purposes = {...?a?.defaultPurposes};
    _initialPurposes = {..._purposes};
    _provider = a?.provider ?? 'Anthropic';
    _billing = a?.billingMode ?? BillingMode.subscription;
    _id = a?.id ?? ref.read(ledgerProvider.notifier).newId();
    _revision = a == null
        ? (ref.read(ledgerProvider.notifier).isCloud ? 0 : null)
        : ref.read(ledgerProvider.notifier).accountRevision(a.id);
    _initialText = _controllers.map((c) => c.text).toList();
    _initialProvider = _provider;
    _initialBilling = _billing;
  }

  List<TextEditingController> get _controllers => [
    _alias,
    _product,
    _plan,
    _budget,
    _model,
    _timezone,
    _cycle,
  ];

  bool get _hasChanges =>
      !_purposes.containsAll(_initialPurposes) ||
      !_initialPurposes.containsAll(_purposes) ||
      _provider != _initialProvider ||
      _billing != _initialBilling ||
      List.generate(
        _controllers.length,
        (i) => i,
      ).any((i) => _controllers[i].text != _initialText[i]);

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Moves an untouched product suggestion along; typed names are kept.
  void _pickProvider(String next) {
    const suggested = {
      'Anthropic': 'Claude',
      'OpenAI': 'Codex',
      'Google': 'Gemini',
    };
    if (_product.text.trim() == (suggested[_provider] ?? '')) {
      _product.text = suggested[next] ?? '';
    }
    _provider = next;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_key.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final vm = ref.read(ledgerProvider.notifier);
      final account = AIAccount(
        id: _id,
        alias: _alias.text.trim(),
        provider: _provider,
        product: _product.text.trim(),
        billingMode: _billing,
        plan: _plan.text.trim(),
        budgetMicros: parseUsd(_budget.text),
        createdAt: _createdAt,
        archived: widget.account?.archived ?? false,
        quotaWindows:
            ref.read(ledgerProvider).requireValue.account(_id)?.quotaWindows ??
            const [],
        defaultModelId: _model.text.trim().isEmpty ? null : _model.text.trim(),
        defaultPurposes: Purpose.values.where(_purposes.contains).toList(),
        timezone: _timezone.text.trim(),
        cycleStartDay: int.parse(_cycle.text.trim()),
        isDemo: widget.account?.isDemo ?? false,
        dataSource: widget.account?.dataSource ?? DataSource.manual,
      );
      await vm.saveAccount(account, expectedRevision: _revision);
      if (mounted) {
        Navigator.pop(context, account.id);
        showMessage(context, 'Đã lưu tài khoản.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = errorText(e));
        showMessage(context, 'Chưa lưu được thay đổi. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => DraftGuard(
    controllers: _controllers,
    hasChanges: () => _hasChanges,
    saving: _saving,
    child:
        ledgerFeedback(
          ref.watch(ledgerProvider),
          'Tài khoản',
          missing:
              widget.account != null &&
              ref
                      .watch(ledgerProvider)
                      .asData
                      ?.value
                      .account(widget.account!.id) ==
                  null,
        ) ??
        ContentPage(
          title: widget.account == null ? 'Thêm tài khoản AI' : 'Sửa tài khoản',
          footer: SaveButton(
            label: 'Lưu tài khoản',
            saving: _saving,
            onPressed: _save,
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
                  maxLength: LedgerValidation.aliasLimit,
                  decoration: const InputDecoration(
                    labelText: 'Tên tài khoản',
                    hintText: 'Ví dụ: Codex học tập',
                  ),
                  validator: (v) => LedgerValidation.text(
                    v,
                    'tên tài khoản',
                    LedgerValidation.aliasLimit,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _provider,
                  decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
                  items: LedgerValidation.providers
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (s) => setState(() => _pickProvider(s!)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _product,
                  maxLength: LedgerValidation.shortTextLimit,
                  decoration: const InputDecoration(
                    labelText: 'Công cụ / sản phẩm',
                    hintText: 'Claude, Codex, Gemini...',
                  ),
                  validator: (v) => LedgerValidation.text(
                    v,
                    'tên công cụ',
                    LedgerValidation.shortTextLimit,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BillingMode>(
                  isExpanded: true,
                  initialValue: _billing,
                  decoration: const InputDecoration(labelText: 'Cách tính phí'),
                  items: BillingMode.values
                      .map(
                        (b) => DropdownMenuItem(value: b, child: Text(b.label)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (b) => setState(() => _billing = b!),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _plan,
                  validator: (v) => LedgerValidation.text(
                    v,
                    'tên gói',
                    LedgerValidation.shortTextLimit,
                    required: false,
                  ),
                  maxLength: LedgerValidation.shortTextLimit,
                  decoration: const InputDecoration(
                    labelText: 'Tên gói (tùy chọn)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('account-model'),
                  controller: _model,
                  maxLength: LedgerValidation.shortTextLimit,
                  decoration: const InputDecoration(
                    labelText: 'Model mặc định (tùy chọn)',
                    helperText: 'Tên model, không phải tên công cụ. Có thể đổi theo phiên.',
                  ),
                  validator: (v) => LedgerValidation.text(
                    v,
                    'model mặc định',
                    LedgerValidation.shortTextLimit,
                    required: false,
                  ),
                ),
                const SizedBox(height: 16),
                PurposeChipsSelector(
                  purposes: _purposes,
                  onChanged: (p) => setState(() => _purposes = p),
                  enabled: !_saving,
                ),
                const SizedBox(height: 24),
                AccountCycleFields(
                  timezoneController: _timezone,
                  cycleController: _cycle,
                  budgetController: _budget,
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
        ),
  );
}
