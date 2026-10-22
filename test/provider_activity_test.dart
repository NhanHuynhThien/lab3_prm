import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/provider_activity.dart';
import 'package:token_ledger/models/ledger_enums.dart';
import 'package:token_ledger/theme/app_theme.dart';
import 'package:token_ledger/utils/formatters.dart';
import 'package:token_ledger/widgets/provider_activity_panel.dart';
import 'package:token_ledger/widgets/provider_task_list.dart';

Map<String, dynamic> fixture() {
  final totals = {
    'totalTokens': 120,
    'inputTokens': 100,
    'outputTokens': 20,
    'cachedInputTokens': 60,
    'cacheWriteTokens': null,
    'reasoningTokens': 5,
    'eventCount': 1,
  };
  return {
    'periodStart': '2026-09-22T10:00:00Z',
    'periodEnd': '2026-10-22T10:00:00Z',
    'partial': false,
    ...totals,
    'sessionCount': 1,
    'taskCount': 1,
    'activeDays': 1,
    'omittedTasks': 0,
    'method': 'Phân loại từ khóa; thời gian gồm chờ.',
    'daily': [
      {'day': '2026-10-22', ...totals},
    ],
    'purposes': [
      {'purpose': 'code', ...totals},
    ],
    'tasks': [
      {
        'id': 'a' * 16,
        'sessionId': 'b' * 16,
        'purpose': 'code',
        'models': ['test-model'],
        'startedAt': '2026-10-22T09:00:00Z',
        'endedAt': '2026-10-22T09:05:00Z',
        'elapsedSeconds': 300,
        ...totals,
      },
    ],
  };
}

void main() {
  test('parses breakdown and attribution without inventing billing', () {
    final a = ProviderActivity.fromJson(fixture());
    expect(a.tokens.total, 120);
    expect(a.tokens.cacheWrite, isNull);
    expect(a.recentSevenTokens, 120);
    expect(a.share(a.tokens), 1);
    expect(a.tasksFor(Purpose.code).single.elapsedSeconds, 300);
    expect(a.tasksFor(Purpose.test), isEmpty);
    expect(exactTokens(1234567), '1.234.567');
    expect(elapsedLabel(90061), '1 ngày 1 giờ 1 phút 1 giây');
    expect(preciseMoney(1234), r'$0.001234');
  });
  test('rejects malformed, duplicate and inconsistent summaries', () {
    for (var i = 0; i < 6; i++) {
      final j = jsonDecode(jsonEncode(fixture())) as Map<String, dynamic>;
      switch (i) {
        case 0:
          j['daily'][0]['totalTokens'] = 119;
        case 1:
          j['tasks'][0]['elapsedSeconds'] = 301;
        case 2:
          j['tasks'][0]['id'] = 'raw private id';
        case 3:
          j['purposes'].add(j['purposes'][0]);
        case 4:
          j['totalTokens'] = -1;
        case 5:
          j['tasks'][0]['endedAt'] = '2026-10-23T00:00:00Z';
      }
      expect(() => ProviderActivity.fromJson(j), throwsFormatException);
    }
  });
  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('activity/tasks fit $width text $scale', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final activity = ProviderActivity.fromJson(fixture());
        Widget app(Widget child) => MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: child,
        );
        await tester.pumpWidget(
          app(
            Scaffold(
              body: SingleChildScrollView(
                child: ProviderActivityPanel(activity: activity),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Token đã dùng cho việc gì?'), findsOneWidget);
        await tester.pumpWidget(app(ProviderTaskList(activity: activity)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Chi tiết công việc'), findsOneWidget);
      });
    }
  }
}
