import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/draft_guard.dart';
import '../widgets/usage_empty_view.dart';
import '../widgets/usage_form_fields.dart';

/// Edits a Companion row. Counts, model and time come from the CLI logs and
/// stay read-only; the user can only correct the purpose, title and note.
class AutoUsageEditScreen extends ConsumerStatefulWidget {
  const AutoUsageEditScreen({super.key, required this.session});
  final UsageSession session;

  @override
  ConsumerState<AutoUsageEditScreen> createState() => _State();
}

class _State extends ConsumerState<AutoUsageEditScreen> {
  final _key = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.session.title);
  late final _note = TextEditingController(text: widget.session.note);
  late Purpose _purpose = widget.session.purpose;
  bool _saving = false;
  String? _error;

  bool get _hasChanges =>
      _purpose != widget.session.purpose ||
      _title.text != widget.session.title ||
      _note.text != widget.session.note;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    final s = widget.session;
    try {
      await ref
          .read(ledgerProvider.notifier)
          .saveUsage(
            UsageSession(
              id: s.id,
              accountId: s.accountId,
              title: _title.text.trim(),
              purpose: _purpose,
              occurredAt: s.occurredAt,
              inputTokens: s.inputTokens,
              outputTokens: s.outputTokens,
              note: _note.text.trim(),
              modelId: s.modelId,
              dataSource: s.dataSource,
            ),
          );
      if (mounted) {
        Navigator.pop(context);
        showMessage(context, 'Đã lưu phiên sử dụng.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.muted);
    return DraftGuard(
      controllers: [_title, _note],
      hasChanges: () => _hasChanges,
      saving: _saving,
      child: ContentPage(
        title: 'Sửa phiên tự động',
        footer: FormSaveFooter(
          error: _error,
          child: SaveButton(
            label: 'Lưu thay đổi',
            saving: _saving,
            onPressed: _save,
          ),
        ),
        child: Form(
          key: _key,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${s.dataSource.label} · ${compactTokens(s.knownTokens)} token'
                '${s.modelId == null ? '' : ' · ${s.modelId}'} · '
                '${shortTime(s.occurredAt)}',
                style: muted,
              ),
              const SizedBox(height: 4),
              Text(
                'Token, model và thời gian lấy từ log CLI nên không sửa tay. '
                'Mục đích được đoán từ từ khóa, hãy chỉnh nếu chưa đúng.',
                style: muted,
              ),
              const SizedBox(height: 24),
              UsageTitleField(controller: _title),
              const SizedBox(height: 16),
              UsagePurposeSelector(
                purpose: _purpose,
                onPurposeChanged: (p) => setState(() => _purpose = p),
              ),
              const SizedBox(height: 24),
              UsageNoteField(controller: _note),
            ],
          ),
        ),
      ),
    );
  }
}
