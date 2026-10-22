import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:token_ledger/models/cloud_sync_status.dart';
import 'package:token_ledger/services/gemini_activity_import.dart';
import 'package:token_ledger/viewmodels/gemini_activity_viewmodel.dart';
import 'package:token_ledger/viewmodels/live_clock_viewmodel.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);
  Map<String, dynamic> item(
    String date, {
    String product = 'Gemini Apps',
    String title = 'private prompt',
  }) => {
    'time': date,
    'products': [product],
    'title': title,
  };
  Uint8List bytes(Object value) =>
      Uint8List.fromList(utf8.encode(jsonEncode(value)));
  test('Takeout imports only Gemini activity in 30 days, dedupes and discards content', () {
    final rows = [
      item('2026-10-22T10:00:00Z'),
      item('2026-10-22T10:00:00Z'),
      item('2026-10-21T10:00:00Z'),
      item('2026-10-22T11:00:00Z', product: 'Search'),
      item('2026-08-01T11:00:00Z'),
      item('2026-10-23T10:00:00Z'),
    ];
    final result = parseGeminiActivityFile((bytes: bytes(rows), now: now));
    expect(result.activityCount, 2);
    expect(result.activeDays, 2);
    expect(result.dailyCounts.keys, ['2026-10-22', '2026-10-21']);
    expect(result.dailyCounts.toString(), isNot(contains('private prompt')));
  });
  test('unrecognized schema, invalid timestamps and ZIP are rejected', () {
    for (final data in [
      bytes({'messages': []}),
      bytes([item('no-date')]),
      Uint8List.fromList([80, 75, 3, 4]),
      bytes([item('2026-10-22T10:00:00Z', product: 'Search')]),
    ]) {
      expect(
        () => parseGeminiActivityFile((bytes: data, now: now)),
        throwsFormatException,
      );
    }
  });
  test('known but older activity is measured zero in the selected period', () {
    expect(
      parseGeminiActivityFile((
        bytes: bytes([item('2025-01-01T00:00:00Z')]),
        now: now,
      )).activityCount,
      0,
    );
  });
  test('reimport replaces aggregates; malformed file retains last valid data; UID containers isolate', () async {
    final c = ProviderContainer(
      overrides: [
        cloudOwnerProvider.overrideWithValue('A'),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    final b = ProviderContainer(
      overrides: [cloudOwnerProvider.overrideWithValue('B')],
    );
    addTearDown(c.dispose);
    addTearDown(b.dispose);
    final vm = c.read(geminiActivityProvider.notifier);
    final input = bytes([item('2026-10-22T10:00:00Z')]);
    await vm.importBytes(input);
    await vm.importBytes(input);
    expect(c.read(geminiActivityProvider).summary!.activityCount, 1);
    await vm.importBytes(bytes({'invalid': []}));
    expect(c.read(geminiActivityProvider).summary!.activityCount, 1);
    expect(c.read(geminiActivityProvider).error, isNotNull);
    expect(b.read(geminiActivityProvider).summary, isNull);
    vm.clear();
    expect(c.read(geminiActivityProvider).summary, isNull);
  });
  test('signed out cannot import a source', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c
        .read(geminiActivityProvider.notifier)
        .importBytes(bytes([item('2026-10-22T10:00:00Z')]));
    expect(c.read(geminiActivityProvider).summary, isNull);
  });
}
