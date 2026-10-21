import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ledger.dart';
import '../services/usage_calculator.dart';
import 'ledger_viewmodel.dart';

class DemoSessionViewModel extends Notifier<bool> {
  @override
  bool build() => Uri.base.queryParameters['demo'] == '1';
  void enter() => state = true;
  void leave() => state = false;
}

final demoSessionProvider = NotifierProvider<DemoSessionViewModel, bool>(
  DemoSessionViewModel.new,
);

class RangeViewModel extends Notifier<UsageRange> {
  @override
  UsageRange build() => UsageRange.month;
  void select(UsageRange range) => state = range;
}

final rangeProvider = NotifierProvider<RangeViewModel, UsageRange>(
  RangeViewModel.new,
);

final filteredSessionsProvider = Provider.autoDispose<List<UsageSession>>((
  ref,
) {
  final data = ref.watch(ledgerProvider).asData?.value;
  return UsageCalculator.filter(
    data?.sessions ?? [],
    ref.watch(nowProvider),
    range: ref.watch(rangeProvider),
    timezone: data?.reportingTimezone ?? 'device',
    scope: ref.watch(effectiveDataScopeProvider),
  );
});

class DataScopeViewModel extends Notifier<DataScope?> {
  @override
  DataScope? build() => null;
  void select(DataScope scope) => state = scope;
}

final dataScopeProvider = NotifierProvider<DataScopeViewModel, DataScope?>(
  DataScopeViewModel.new,
);

final effectiveDataScopeProvider = Provider.autoDispose<DataScope>((ref) {
  final selected = ref.watch(dataScopeProvider);
  if (selected != null) return selected;
  final data = ref.watch(ledgerProvider).asData?.value;
  if ((data?.sessions.any((s) => DataScope.manual.includes(s)) ?? false) ||
      (data?.accounts.any((a) => a.dataSource == DataSource.manual) ?? false)) {
    return DataScope.manual;
  }
  if ((data?.sessions.any((s) => DataScope.legacy.includes(s)) ?? false) ||
      (data?.accounts.any((a) => a.dataSource == DataSource.legacy) ?? false)) {
    return DataScope.legacy;
  }
  return data?.accounts.any((a) => a.isDemo) == true
      ? DataScope.demo
      : DataScope.manual;
});
