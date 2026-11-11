import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/manual_report_projection.dart';
import '../services/report_summary.dart';
import 'ledger_viewmodel.dart';

/// What a PDF for [period] would contain, for the export dialog preview.
class ReportPreview {
  const ReportPreview(this.projection, this.summary);
  final ManualReportProjection projection;
  final ReportSummary summary;
  int get accountCount => projection.accounts.length;
}

/// Null until the ledger has loaded.
final reportPreviewProvider = Provider.autoDispose
    .family<ReportPreview?, String>((ref, period) {
      final data = ref.watch(ledgerProvider).asData?.value;
      if (data == null) return null;
      final projection = ManualReportProjection(
        data: data,
        now: ref.watch(nowProvider),
        period: period,
        scope: ref.watch(effectiveDataScopeProvider),
      );
      return ReportPreview(
        projection,
        ReportSummary.of(projection.sessions, timezone: projection.timezone),
      );
    });
