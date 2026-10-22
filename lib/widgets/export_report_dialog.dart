import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_report.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/ledger_viewmodel.dart';
import '../viewmodels/product_features_viewmodel.dart';
import 'common.dart';
import 'export_report_views.dart';

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
  double _uploadProgress = 0.0;
  String _statusText = '';
  ExportReport? _completedReport;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(ledgerProvider).value?.accounts ?? [];
    final sessions = ref.watch(filteredSessionsProvider);

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
                'Tạo tài liệu PDF chuyên nghiệp thống kê các phiên sử dụng, chi phí USD và hạn mức AI.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: AppSpace.md),
              ExportReportPeriodSelector(
                selectedPeriod: _selectedPeriod,
                isWorking: _isWorking,
                onSelected: (val) => setState(() => _selectedPeriod = val),
              ),
              const SizedBox(height: AppSpace.md),
              ExportReportPreviewCard(
                sessionCount: sessions.length,
                totalCostMicros: totalCostMicros,
                accountCount: accounts.length,
                totalTokens: totalTokens,
              ),
              if (_isWorking) ...[
                const SizedBox(height: AppSpace.md),
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
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
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isWorking ? null : () => Navigator.pop(context),
          child: Text(_completedReport != null ? 'Đóng' : 'Hủy'),
        ),
        const SizedBox(width: AppSpace.sm),
        if (_completedReport == null) ...[
          OutlinedButton.icon(
            onPressed: _isWorking
                ? null
                : () => _generate(uploadToCloud: false),
            icon: const Icon(Icons.file_open_outlined, size: 18),
            label: const Text('Mở trên máy'),
          ),
          const SizedBox(width: AppSpace.sm),
          FilledButton.icon(
            onPressed: _isWorking ? null : () => _generate(uploadToCloud: true),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text('Tải lên Cloud'),
          ),
        ] else ...[
          if (_completedReport!.localPath != null)
            OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(reportManagementServiceProvider)
                    .openLocalReport(_completedReport!.id);
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Mở PDF'),
            ),
          if (_completedReport!.storageUrl != null) ...[
            const SizedBox(width: AppSpace.sm),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: _completedReport!.storageUrl!),
                );
                showMessage(context, 'Đã sao chép link Cloud Storage!');
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Sao chép link'),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _generate({required bool uploadToCloud}) async {
    setState(() {
      _isWorking = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
      _statusText = 'Đang khởi tạo tài liệu PDF...';
    });

    try {
      final reportManager = ref.read(reportManagementServiceProvider);
      final accounts = ref.read(ledgerProvider).value?.accounts ?? [];
      final sessions = ref.read(filteredSessionsProvider);
      final user = ref.read(authSessionProvider).asData?.value;

      final report = await reportManager.generateReport(
        periodLabel: _selectedPeriod,
        accounts: accounts,
        sessions: sessions,
        userEmail: user?.email,
      );

      if (uploadToCloud) {
        setState(() {
          _statusText = 'Đang tải lên Firebase Cloud Storage...';
          _uploadProgress = 0.3;
        });

        final uploaded = await reportManager.uploadToCloudStorage(
          reportId: report.id,
          onProgress: (prog) {
            if (mounted) setState(() => _uploadProgress = prog);
          },
        );

        if (mounted) {
          setState(() {
            _isWorking = false;
            _completedReport = uploaded;
            _statusText = 'Hoàn tất!';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isWorking = false;
            _completedReport = report;
            _statusText = 'Đã tạo xong!';
          });
        }
        if (report.localPath != null) {
          await reportManager.openLocalReport(report.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage = 'Lỗi xử lý báo cáo: ${e.toString()}';
        });
      }
    }
  }
}
