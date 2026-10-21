import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/ledger_validation.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/draft_guard.dart';
import '../widgets/ledger_feedback.dart';
import '../widgets/quota_form_fields.dart';

class QuotaFormScreen extends ConsumerStatefulWidget {
  const QuotaFormScreen({
    super.key,
    required this.account,
    this.quota,
    this.newWindow = false,
  });

  final AIAccount account;
  final QuotaSnapshot? quota;
  final bool newWindow;

  @override
  ConsumerState<QuotaFormScreen> createState() => _QuotaFormScreenState();
}

class _QuotaFormScreenState extends ConsumerState<QuotaFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _percent, _window, _source, _note;
  late final List<String> _initialText;
  late DateTime _observed;
  late final DateTime _initialObserved;
  QuotaSnapshot? get _original =>
      widget.newWindow ? null : widget.quota ?? widget.account.quota;

  List<TextEditingController> get _controllers => [
    _percent,
    _window,
    _source,
    _note,
  ];

  late DateTime _reset;
  late final DateTime _initialReset;
  late final String _initialPercent, _initialWindow;
  bool _saving = false;
  late final int? _revision;
  String? _error;

  @override
  void initState() {
    super.initState();
    _revision = _original == null
        ? (ref.read(ledgerProvider.notifier).isCloud ? 0 : null)
        : ref
              .read(ledgerProvider.notifier)
              .quotaRevision(widget.account.id, _original!.windowKey);
    _percent = TextEditingController(
      text: _original?.usedPercent.toString() ?? '',
    );
    _window = TextEditingController(text: _original?.window ?? '5 giờ');
    _source = TextEditingController(text: _original?.sourceLabel ?? '');
    _note = TextEditingController(text: _original?.note ?? '');
    _initialText = _controllers.map((c) => c.text).toList();
    final now = ref.read(clockProvider)().toLocal();
    _observed = now;
    _initialObserved = _observed;
    _reset = (_original?.resetAt ?? now.add(const Duration(hours: 5)))
        .toLocal();
    if (!_reset.isAfter(now)) _reset = now.add(const Duration(hours: 5));
    _initialReset = _reset;
    _initialPercent = _percent.text;
    _initialWindow = _window.text;
  }

  @override
  void dispose() {
    _percent.dispose();
    _window.dispose();
    _source.dispose();
    _note.dispose();
    super.dispose();
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
      await ref
          .read(ledgerProvider.notifier)
          .updateQuota(
            widget.account.id,
            QuotaSnapshot(
              window: _window.text.trim(),
              usedPercent: int.parse(_percent.text.trim()),
              observedAt: _observed,
              windowKey: _original?.windowKey,
              source: DataSource.manual,
              sourceLabel: _source.text.trim(),
              note: _note.text.trim(),
              resetAt: _reset,
            ),
            requireExisting: _original != null,
            expectedRevision: _revision,
          );
      if (mounted) Navigator.pop(context);
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
  Widget build(BuildContext context) => DraftGuard(
    controllers: _controllers,
    hasChanges: () =>
        _controllers.indexed.any(
          (entry) => entry.$2.text != _initialText[entry.$1],
        ) ||
        _observed != _initialObserved ||
        _percent.text != _initialPercent ||
        _window.text != _initialWindow ||
        _reset != _initialReset,
    saving: _saving,
    child:
        ledgerFeedback(
          ref.watch(ledgerProvider),
          'Cập nhật hạn mức',
          missing:
              ref
                      .watch(ledgerProvider)
                      .asData
                      ?.value
                      .account(widget.account.id) ==
                  null ||
              (_original != null &&
                  !(ref
                          .watch(ledgerProvider)
                          .asData
                          ?.value
                          .account(widget.account.id)
                          ?.quotaWindows
                          .any((q) => q.windowKey == _original!.windowKey) ??
                      false)),
        ) ??
        ContentPage(
          title: 'Cập nhật hạn mức',
          footer: SaveButton(
            label: 'Lưu hạn mức nhập tay',
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
                    'Nhập số liệu bạn thấy trên trang usage của nhà cung cấp. Hạn mức này độc lập với token và ngân sách tự đặt.',
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _window,
                  maxLength: LedgerValidation.shortTextLimit,
                  decoration: const InputDecoration(
                    labelText: 'Cửa sổ hạn mức',
                    hintText: '5 giờ / hàng tuần',
                  ),
                  validator: (v) => LedgerValidation.text(
                    v,
                    'tên cửa sổ hạn mức',
                    LedgerValidation.shortTextLimit,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('quota-percent'),
                  controller: _percent,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Đã dùng · %',
                    suffixText: '%',
                  ),
                  validator: LedgerValidation.percentInput,
                ),
                const SizedBox(height: 24),
                QuotaTimePickers(
                  reset: _reset,
                  observed: _observed,
                  now: ref.read(clockProvider)().toLocal(),
                  onResetChanged: (d) => setState(() => _reset = d),
                  onObservedChanged: (d) => setState(() => _observed = d),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('quota-source'),
                  controller: _source,
                  maxLength: LedgerValidation.titleLimit,
                  decoration: const InputDecoration(
                    labelText: 'Nguồn quan sát (tùy chọn)',
                    hintText: 'Trang usage / tên báo cáo của nhà cung cấp',
                  ),
                  validator: (v) => LedgerValidation.text(
                    v,
                    'nguồn quan sát',
                    LedgerValidation.titleLimit,
                    required: false,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('quota-note'),
                  controller: _note,
                  maxLines: 3,
                  maxLength: LedgerValidation.noteLimit,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú hạn mức (tùy chọn)',
                  ),
                  validator: (v) => LedgerValidation.text(
                    v,
                    'ghi chú hạn mức',
                    LedgerValidation.noteLimit,
                    required: false,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mỗi cửa sổ được lưu riêng. Tên trùng khi thêm mới sẽ cập nhật cửa sổ đó; không cộng các % với nhau. Reset và quan sát nhập theo giờ thiết bị.',
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
        ),
  );
}
