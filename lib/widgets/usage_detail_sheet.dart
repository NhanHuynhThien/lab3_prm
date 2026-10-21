import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../screens/usage_form_screen.dart';
import '../services/reporting_calendar.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'ledger_feedback.dart';

Future<void> showUsageDetail(BuildContext context, UsageSession session) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(productFeaturesProvider.notifier).detail('usage');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (_) => UsageDetailSheet(sessionId: session.id),
  );
}

class UsageDetailSheet extends ConsumerWidget {
  const UsageDetailSheet({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerProvider);
    final feedback = ledgerFeedback(state, 'Lịch sử sử dụng');
    if (feedback != null) return feedback;
    final data = state.requireValue;
    final session = data.sessions.where((s) => s.id == sessionId).firstOrNull;
    if (session == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Phiên không còn tồn tại.'),
      );
    }
    final account = data.account(session.accountId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '${account?.alias ?? 'Tài khoản'} · ${session.purpose.label}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _DetailLine('Chi phí nhập tay', money(session.costMicros)),
            _DetailLine(
              'Input token',
              session.inputTokens?.toString() ?? 'Chưa biết',
            ),
            _DetailLine(
              'Output token',
              session.outputTokens?.toString() ?? 'Chưa biết',
            ),
            _DetailLine(
              'Ngày sử dụng',
              ReportingCalendar.dayKey(
                session.occurredAt,
                data.reportingTimezone,
              ),
            ),
            _DetailLine(
              'Giờ báo cáo',
              '${shortTime(session.occurredAt, timezone: data.reportingTimezone)} · ${ReportingCalendar.zoneLabel(data.reportingTimezone)}',
            ),
            _DetailLine('Nguồn', session.dataSource.label),
            _DetailLine('Loại chi phí', session.effectiveCostBasis.label),
            _DetailLine(
              'Phân loại',
              session.isDemo ? 'Demo giả định' : 'Dữ liệu theo dõi',
            ),
            _DetailLine('Model', session.modelId ?? 'Chưa biết'),
            if (session.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(session.note),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (account != null)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UsageFormScreen(session: session),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa phiên'),
                  ),
                ConfirmedActionButton(
                  label: 'Xóa phiên',
                  icon: Icons.delete_outline,
                  destructive: true,
                  title: 'Xóa phiên sử dụng?',
                  message:
                      '${session.title} sẽ bị xóa; tổng chi phí và token được tính lại. Không thể hoàn tác.',
                  onConfirm: () =>
                      ref.read(ledgerProvider.notifier).deleteUsage(session.id),
                  onSuccess: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 16),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
