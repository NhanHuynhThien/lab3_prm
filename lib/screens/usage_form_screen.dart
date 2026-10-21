import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/ledger_validation.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/draft_guard.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/usage_empty_view.dart';
import '../widgets/usage_form_fields.dart';

class UsageFormScreen extends ConsumerStatefulWidget {
  const UsageFormScreen({super.key, this.accountId, this.session});
  final String? accountId;
  final UsageSession? session;

  @override
  ConsumerState<UsageFormScreen> createState() => _UsageFormScreenState();
}

class _UsageFormScreenState extends ConsumerState<UsageFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title,
      _input,
      _output,
      _cost,
      _note,
      _model;
  CostBasis _costBasis = CostBasis.manual;
  late final CostBasis _initialCostBasis;
  bool _modelTouched = false, _purposeTouched = false;
  late final String _id;
  String? _accountId, _error;
  Purpose _purpose = Purpose.code;
  late DateTime _date;
  bool _saving = false;
  late final List<String> _initialText;
  late final String? _initialAccountId;
  late final Purpose _initialPurpose;
  late final DateTime _initialDate;
  late final int? _revision;

  @override
  void initState() {
    super.initState();
    _revision = widget.session == null
        ? (ref.read(ledgerProvider.notifier).isCloud ? 0 : null)
        : ref.read(ledgerProvider.notifier).usageRevision(widget.session!.id);
    final s = widget.session;
    _id = s?.id ?? ref.read(ledgerProvider.notifier).newId();
    final initialData = ref.read(ledgerProvider).asData?.value;
    final scope = ref.read(effectiveDataScopeProvider);
    final suggested = initialData?.accounts
        .where(
          (a) => !a.archived && scope.includesAccount(a, initialData.sessions),
        )
        .firstOrNull;
    _accountId = s?.accountId ?? widget.accountId ?? suggested?.id;
    _title = TextEditingController(text: s?.title ?? '');
    _input = TextEditingController(text: s?.inputTokens?.toString() ?? '');
    _output = TextEditingController(text: s?.outputTokens?.toString() ?? '');
    _cost = TextEditingController(text: usdInput(s?.costMicros));
    _note = TextEditingController(text: s?.note ?? '');
    final account = ref
        .read(ledgerProvider)
        .asData
        ?.value
        .account(_accountId ?? '');
    _model = TextEditingController(
      text: s?.modelId ?? (s == null ? account?.defaultModelId : null) ?? '',
    );
    _costBasis = s?.costMicros == null
        ? CostBasis.manual
        : s!.effectiveCostBasis;
    _initialCostBasis = _costBasis;
    _purpose =
        s?.purpose ?? account?.defaultPurposes.firstOrNull ?? Purpose.code;
    _date = (s?.occurredAt ?? ref.read(clockProvider)()).toLocal();
    _initialText = _controllers.map((c) => c.text).toList();
    _initialAccountId = _accountId;
    _initialPurpose = _purpose;
    _initialDate = _date;
  }

  List<TextEditingController> get _controllers => [
    _title,
    _input,
    _output,
    _cost,
    _note,
    _model,
  ];

  bool get _hasChanges =>
      _costBasis != _initialCostBasis ||
      _accountId != _initialAccountId ||
      _purpose != _initialPurpose ||
      _date != _initialDate ||
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

  void _selectAccount(String? id) {
    _accountId = id;
    final account = ref.read(ledgerProvider).asData?.value.account(id ?? '');
    if (!_modelTouched) _model.text = account?.defaultModelId ?? '';
    if (!_purposeTouched) {
      _purpose = account?.defaultPurposes.firstOrNull ?? Purpose.code;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
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
    FocusScope.of(context).unfocus();
    try {
      final account = ref
          .read(ledgerProvider)
          .requireValue
          .account(_accountId!)!;
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
              modelId: _model.text.trim().isEmpty ? null : _model.text.trim(),
              dataSource:
                  widget.session?.dataSource ??
                  (account.isDemo ? DataSource.demo : DataSource.manual),
              isDemo: widget.session?.isDemo ?? account.isDemo,
              costBasis: parseUsd(_cost.text) == null
                  ? CostBasis.unknown
                  : _costBasis,
            ),
            expectedRevision: _revision,
          );
      if (mounted) {
        Navigator.pop(context);
        showMessage(
          context,
          ref.read(ledgerProvider.notifier).isCloud
              ? 'Đã lưu phiên sử dụng trên Firestore.'
              : 'Đã lưu phiên sử dụng trên thiết bị.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        showMessage(context, 'Chưa lưu được thay đổi. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Ghi phiên sử dụng');
    if (feedback != null) {
      return DraftGuard(
        controllers: _controllers,
        hasChanges: () => _hasChanges,
        saving: _saving,
        child: feedback,
      );
    }
    final data = state.requireValue;
    final selected = data.account(_accountId ?? '');
    final accounts = data.accounts
        .where((a) => !a.archived || a.id == _accountId)
        .toList();
    final emptyGuard = checkUsageEmptyGuards(
      context: context,
      data: data,
      accountId: _accountId,
      session: widget.session,
      accounts: accounts,
      onAccountCreated: (id) {
        if (mounted) setState(() => _selectAccount(id));
      },
    );
    if (emptyGuard != null) {
      return DraftGuard(
        controllers: _controllers,
        hasChanges: () => _hasChanges,
        saving: _saving,
        child: emptyGuard,
      );
    }
    return DraftGuard(
      controllers: _controllers,
      hasChanges: () => _hasChanges,
      saving: _saving,
      child: ContentPage(
        title: widget.session == null
            ? 'Ghi phiên sử dụng'
            : 'Sửa phiên sử dụng',
        footer: SaveButton(
          label: 'Lưu phiên sử dụng',
          saving: _saving,
          onPressed: _save,
        ),
        child: Form(
          key: _key,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              UsageAccountSelector(
                selectedAccount: selected,
                accounts: accounts,
                session: widget.session,
                saving: _saving,
                onAccountSelected: (v) => setState(() => _selectAccount(v)),
              ),
              UsageTitleField(controller: _title),
              const SizedBox(height: 16),
              UsagePurposeSelector(
                purpose: _purpose,
                onPurposeChanged: (p) => setState(() {
                  _purpose = p;
                  _purposeTouched = true;
                }),
              ),
              const SizedBox(height: 24),
              UsageModelField(
                controller: _model,
                onChanged: (_) => _modelTouched = true,
              ),
              const SizedBox(height: 24),
              UsageTokenInputs(
                inputController: _input,
                outputController: _output,
                validator: LedgerValidation.tokenInput,
              ),
              const SizedBox(height: 24),
              UsageCostSection(
                costController: _cost,
                costBasis: _costBasis,
                onCostBasisChanged: (b) => setState(() => _costBasis = b),
                date: _date,
                onDateChanged: (d) => setState(() => _date = d),
                now: ref.read(clockProvider)().toLocal(),
                saving: _saving,
              ),
              const SizedBox(height: 24),
              UsageNoteField(controller: _note),
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
}
