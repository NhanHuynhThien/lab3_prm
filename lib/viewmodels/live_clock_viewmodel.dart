import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ledger_viewmodel.dart' show ledgerProvider;

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final nowProvider = NotifierProvider.autoDispose<LiveClockViewModel, DateTime>(
  LiveClockViewModel.new,
);

/// One lightweight timer: minute boundary, or the next quota reset if earlier.
/// No background polling or writes; resume immediately refreshes projections.
class LiveClockViewModel extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    final now = ref.watch(clockProvider)().toLocal();
    ref.watch(ledgerProvider.select((value) => value.asData?.value));
    final lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed) {
          refresh();
        } else {
          _timer?.cancel();
        }
      },
    );
    ref.onDispose(() {
      _timer?.cancel();
      lifecycle.dispose();
    });
    ref.onCancel(() => _timer?.cancel());
    ref.onResume(() => scheduleMicrotask(refresh));
    _schedule(now);
    return now;
  }

  void refresh() {
    if (!ref.mounted) return;
    final now = ref.read(clockProvider)().toLocal();
    state = now;
    _schedule(now);
  }

  void _schedule(DateTime now) {
    _timer?.cancel();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    // Advance on the time line, including a repeated/skipped local hour.
    var next = now.add(
      const Duration(minutes: 1) -
          Duration(
            seconds: now.second,
            milliseconds: now.millisecond,
            microseconds: now.microsecond,
          ),
    );
    for (final account
        in ref.read(ledgerProvider).asData?.value.accounts ?? []) {
      for (final quota in account.quotaWindows) {
        final reset = quota.resetAt;
        if (reset.isAfter(now) && reset.isBefore(next)) next = reset;
      }
    }
    _timer = Timer(next.difference(now), refresh);
  }
}
