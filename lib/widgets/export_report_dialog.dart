import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_report.dart';
import '../models/ledger.dart';
import '../services/manual_report_projection.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'export_report_views.dart';
import 'action_buttons.dart';

class ExportReportDialog extends ConsumerStatefulWidget {
  const ExportReportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ExportReportDialog(),
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
    final data = ref.watch(ledgerProvider).asData?.value;
    final projection = ManualReportProjection(
      data: data ?? LedgerData(accounts: [], sessions: []),
      now: ref.watch(nowProvider),
      period: _selectedPeriod,
      scope: ref.watch(effectiveDataScopeProvider),
    );
    final accounts = projection.accounts;
    final sessions = projection.sessions;

    int totalCostMicros = 0;
    int totalTokens = 0;
    for (final s in sessions) {
      if (s.costMicros != null) totalCostMicros += s.costMicros!;
      if (s.knownTokens != null) totalTokens += s.knownTokens!;
    }

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
                'Báo cáo các phiên trong sổ ghi nhận theo kỳ bên dưới. Số liệu nguồn AI/CLI được xem riêng trong Phân tích.',
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
              ExportReportPreviewCard(
                sessionCount: sessions.length,
                totalCostMicros: totalCostMicros,
                accountCount: accounts.length,
                totalTokens: totalTokens,
                knownCostCount: sessions
                    .where((s) => s.costMicros != null)
                    .length,
                knownTokensCount: sessions
                    .where((s) => s.knownTokens != null)
                    .length,
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
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return ActionButtons(
      children: [
        TextButton(
          onPressed: _isWorking ? null : () => Navigator.pop(context),
          child: Text(_completedReport != null ? 'Đóng' : 'Hủy'),
        ),
        if (_completedReport == null) ...[
          FilledButton.icon(
            onPressed: _isWorking ? null : _generate,
            icon: const Icon(Icons.file_open_outlined, size: 18),
            label: const Text('Tạo PDF trên máy'),
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
