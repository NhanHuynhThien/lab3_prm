import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/ai_account.dart';
import 'package:token_ledger/models/ledger_enums.dart';
import 'package:token_ledger/models/usage_session.dart';
import 'package:token_ledger/services/pdf_report_service.dart';

void main() {
  group('PdfReportService', () {
    const service = PdfReportService();

    test(
      'generateReportBytes produces valid PDF bytes with header %PDF-',
      () async {
        final account = AIAccount(
          id: 'acc_1',
          alias: 'OpenAI GPT-4',
          provider: 'OpenAI',
          product: 'ChatGPT',
          billingMode: BillingMode.subscription,
          plan: 'Plus',
          createdAt: DateTime(2026, 1, 1),
        );

        final session = UsageSession(
          id: 'sess_1',
          accountId: 'acc_1',
          title: 'Refactor authentication module',
          purpose: Purpose.code,
          occurredAt: DateTime(2026, 10, 15, 10, 30),
          costMicros: 250000, // $0.25
          inputTokens: 1500,
          outputTokens: 500,
        );

        final bytes = await service.generateReportBytes(
          userEmail: 'developer@example.com',
          periodLabel: 'Tháng 10/2026',
          accounts: [account],
          sessions: [session],
        );

        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(500));

        // PDF signature: starts with %PDF- (0x25, 0x50, 0x44, 0x46, 0x2D)
        expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
      },
    );

    test(
      'generateReportBytes handles empty sessions and accounts without error',
      () async {
        final bytes = await service.generateReportBytes(
          userEmail: 'test@example.com',
          periodLabel: 'Toàn bộ dữ liệu',
          accounts: [],
          sessions: [],
        );

        expect(bytes, isNotEmpty);
        expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
      },
    );
  });
}
