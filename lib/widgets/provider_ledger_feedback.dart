import 'package:flutter/material.dart';

import 'provider_sync_summary.dart';

/// Companion data does not depend on Firestore's loading/error state.
class ProviderLedgerFeedback extends StatelessWidget {
  const ProviderLedgerFeedback({
    super.key,
    required this.feedback,
    this.header,
  });
  final Widget feedback;
  final Widget? header;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      header ?? const ProviderSyncSummary(),
      const SizedBox(height: 16),
      SizedBox(height: 420, child: feedback),
    ],
  );
}
