import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/ledger_validation.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/draft_guard.dart';
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
  @override
  void initState() {
    super.initState();
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

  String? _tokenValidator(String? value) {
    return LedgerValidation.tokenInput(value);
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
                  (ref
                          .read(ledgerProvider)
                          .requireValue
                          .account(_accountId!)!
                          .isDemo
                      ? DataSource.demo
                      : DataSource.manual),
              isDemo:
                  widget.session?.isDemo ??
                  ref
                      .read(ledgerProvider)
                      .requireValue
                      .account(_accountId!)!
                      .isDemo,
              costBasis: parseUsd(_cost.text) == null
                  ? CostBasis.unknown
                  : _costBasis,
            ),
          );
      if (mounted) {
        Navigator.pop(context);
        showMessage(context, 'Đã lưu phiên sử dụng trên thiết bị.');
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
    if (widget.session != null &&
        (selected == null ||
            !data.sessions.any((s) => s.id == widget.session!.id))) {
      return DraftGuard(
        controllers: _controllers,
        hasChanges: () => _hasChanges,
        saving: _saving,
        child: ContentPage(
          title: 'Sửa phiên sử dụng',
          child: EmptyFeedback(
            title: selected == null
                ? 'Không tìm thấy tài khoản'
                : 'Không tìm thấy phiên sử dụng',
            message: 'Quay lại lịch sử và tải lại dữ liệu trước khi sửa phiên.',
          ),
        ),
      );
    }
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
            if (id != null && mounted) setState(() => _selectAccount(id));
          },
        ),
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
              Text(
                widget.session?.dataSource.label ??
                    (selected?.isDemo == true
                        ? 'Demo giả định · Nhập tay'
                        : 'Dữ liệu nhập tay'),
                style: const TextStyle(color: AppColors.muted),
              ),
              if (selected?.archived == true)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.session != null
                        ? 'Tài khoản đã lưu trữ. Bạn vẫn có thể sửa phiên lịch sử này.'
                        : 'Tài khoản đã lưu trữ. Chọn tài khoản đang hoạt động để ghi phiên mới.',
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_accountId),
                initialValue: selected?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tài khoản AI'),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.alias}${a.archived ? ' · Đã lưu trữ' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.session != null || _saving
                    ? null
                    : (v) => setState(() => _selectAccount(v)),
                validator: (v) => v == null
                    ? 'Chọn tài khoản.'
                    : widget.session == null &&
                          data.account(v)?.archived == true
                    ? 'Chọn tài khoản đang hoạt động.'
                    : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                maxLength: LedgerValidation.titleLimit,
                decoration: const InputDecoration(
                  labelText: 'Đã dùng AI cho việc gì?',
                  hintText: 'Ví dụ: Sửa lỗi Google Sign-In',
                ),
                validator: (v) => LedgerValidation.text(
                  v,
                  'tên công việc',
                  LedgerValidation.titleLimit,
                ),
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
                  if (p != null && mounted) {
                    setState(() {
                      _purpose = p;
                      _purposeTouched = true;
                    });
                  }
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
              TextFormField(
                key: const ValueKey('usage-model'),
                controller: _model,
                maxLength: LedgerValidation.shortTextLimit,
                onChanged: (_) => _modelTouched = true,
                decoration: const InputDecoration(
                  labelText: 'Model sử dụng (tùy chọn)',
                  helperText: 'Gợi ý từ tài khoản; để trống nếu chưa biết.',
                ),
                validator: (v) => LedgerValidation.text(
                  v,
                  'model',
                  LedgerValidation.shortTextLimit,
                  required: false,
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
                      decoration: const InputDecoration(
                        labelText: 'Input token',
                      ),
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
              DropdownButtonFormField<CostBasis>(
                isExpanded: true,
                initialValue: _costBasis,
                decoration: const InputDecoration(
                  labelText: 'Loại chi phí',
                  helperText: 'Không tự ước tính giá. Dữ liệu cũ không tự coi là chi phí thực.',
                ),
                items:
                    [CostBasis.manual, CostBasis.actual, CostBasis.unspecified]
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: _saving
                    ? null
                    : (b) => setState(() => _costBasis = b!),
              ),
              const SizedBox(height: 24),
              Text(
                'Ngày sử dụng nhập theo giờ thiết bị; lịch sử và biểu đồ dùng múi giờ báo cáo đã chọn.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = ref.read(clockProvider)().toLocal();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date.isAfter(now) ? now : _date,
                    firstDate: DateTime(2020),
                    lastDate: now,
                  );
                  if (date != null && mounted) {
                    final candidate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      _date.hour,
                      _date.minute,
                    );
                    setState(
                      () => _date = candidate.isAfter(now) ? now : candidate,
                    );
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Ngày sử dụng: ${shortDate(_date)}/${_date.year}'),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('usage-note'),
                controller: _note,
                validator: (v) => LedgerValidation.text(
                  v,
                  'ghi chú',
                  LedgerValidation.noteLimit,
                  required: false,
                ),
                maxLines: 3,
                maxLength: LedgerValidation.noteLimit,
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
      ),
    );
  }
}
