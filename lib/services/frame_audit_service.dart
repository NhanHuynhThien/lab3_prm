import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in profile measurements only. No user data or network collection.
abstract final class FrameAuditService {
  static void start() {
    if (!kProfileMode || !const bool.fromEnvironment('UI_PERFORMANCE_AUDIT')) {
      return;
    }
    final frames = <FrameTiming>[];
    SchedulerBinding.instance.addTimingsCallback(frames.addAll);
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (frames.isEmpty) return;
      final sample = List<FrameTiming>.of(frames);
      frames.clear();
      final display = PlatformDispatcher.instance.views.firstOrNull?.display;
      final hz = display?.refreshRate ?? 60;
      final budget = 1000 / (hz > 0 ? hz : 60);
      final build =
          sample.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
            ..sort();
      final raster =
          sample.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()
            ..sort();
      double p95(List<double> values) =>
          values[((values.length - 1) * .95).ceil()];
      final missed = sample
          .where(
            (f) =>
                f.buildDuration.inMicroseconds / 1000 > budget ||
                f.rasterDuration.inMicroseconds / 1000 > budget,
          )
          .length;
      debugPrint(
        'UI_FRAME_AUDIT ${jsonEncode({'frames': sample.length, 'budget_ms': budget, 'build_p95_ms': p95(build), 'raster_p95_ms': p95(raster), 'over_budget_frames': missed})}',
      );
    });
  }
}
