import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_report.dart';
import '../services/manual_report_projection.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import '../viewmodels/report_export_viewmodel.dart';
import 'export_report_views.dart';
import 'action_buttons.dart';

class ExportReportDialog extends ConsumerStatefulWidget {
  const ExportReportDialog({super.key});

  /// Dialogs open on the root navigator, outside the per-UID workspace
  /// container; carry the caller's container so the ledger is the user's.
  static Future<void> show(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return showDialog<void>(
      context: context,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: const ExportReportDialog(),
      ),
    );
  }

  @override
  ConsumerState<ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends ConsumerState<ExportReportDialog> {
  String _selectedPeriod = 'Tháng này';
  bool _isWorking = false;
  String _statusText = '';
  ExportReport? _completedReport;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(reportPreviewProvider(_selectedPeriod));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'Xuất báo cáo PDF',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              const Text(
                'Tổng hợp token, phiên, model, mục đích và hạn mức hiện tại của các agent trong kỳ đã chọn. File lưu trên máy, không tải lên cloud.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: AppSpace.md),
              ExportReportPeriodSelector(
                selectedPeriod: _selectedPeriod,
                isWorking: _isWorking,
                // A finished report belongs to the old period: start over.
                onSelected: (val) => setState(() {
                  _selectedPeriod = val;
                  _completedReport = null;
                  _errorMessage = null;
                }),
              ),
              const SizedBox(height: AppSpace.md),
              if (preview == null)
                const LinearProgressIndicator()
              else
                ExportReportPreviewCard(
                  summary: preview.summary,
                  accountCount: preview.accountCount,
                ),
              if (_isWorking) ...[
                const SizedBox(height: AppSpace.md),
                LinearProgressIndicator(
                  backgroundColor: AppColors.frame,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
              if (_completedReport != null) ...[
                const SizedBox(height: AppSpace.md),
                ExportCompletedCard(report: _completedReport!),
              ],
              const SizedBox(height: AppSpace.lg),
              _buildActions(context, ready: preview != null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, {required bool ready}) {
    return ActionButtons(
      children: [
        TextButton(
          onPressed: _isWorking ? null : () => Navigator.pop(context),
          child: Text(_completedReport != null ? 'Đóng' : 'Hủy'),
        ),
        if (_completedReport == null) ...[
          FilledButton.icon(
            onPressed: _isWorking || !ready ? null : _generate,
            icon: const Icon(Icons.file_open_outlined, size: 18),
            label: const Text('Xuất PDF'),
          ),
        ] else ...[
          if (_completedReport!.localPath != null)
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref
                      .read(reportManagementServiceProvider)
                      .openLocalReport(_completedReport!.id);
                } catch (e) {
                  if (mounted) setState(() => _errorMessage = errorText(e));
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Mở PDF'),
            ),
        ],
      ],
    );
  }

  Future<void> _generate() async {
    setState(() {
      _isWorking = true;
      _errorMessage = null;
      _statusText = 'Đang khởi tạo tài liệu PDF...';
    });

    try {
      final reportManager = ref.read(reportManagementServiceProvider);
      final data = ref.read(ledgerProvider).requireValue;
      final projection = ManualReportProjection(
        data: data,
        now: ref.read(clockProvider)(),
        period: _selectedPeriod,
        scope: ref.read(effectiveDataScopeProvider),
      );
      final user = ref.read(authSessionProvider).asData?.value;

      final report = await reportManager.generateReport(
        periodLabel: projection.label,
        accounts: projection.accounts,
        sessions: projection.sessions,
        userEmail: user?.email,
        timezone: projection.timezone,
      );

      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _completedReport = report;
        _statusText = 'Đã tạo báo cáo.';
      });
      if (report.localPath != null) {
        await reportManager.openLocalReport(report.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage = e is StateError
              ? errorText(e)
              : 'Chưa tạo được báo cáo. Kiểm tra dung lượng máy rồi thử lại.';
        });
      }
    }
  }
}
