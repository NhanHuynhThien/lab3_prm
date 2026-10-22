import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cloud_sync_status.dart';
import '../models/gemini_activity_summary.dart';
import '../services/gemini_activity_import.dart';
import 'live_clock_viewmodel.dart';

class GeminiActivityState {
  const GeminiActivityState({this.summary, this.working = false, this.error});
  final GeminiActivitySummary? summary;
  final bool working;
  final String? error;
}

/// Session-scoped aggregate only. A new UID gets a new container and no import.
class GeminiActivityViewModel extends Notifier<GeminiActivityState> {
  int _epoch = 0;
  @override
  GeminiActivityState build() {
    ref.onDispose(() => _epoch++);
    return const GeminiActivityState();
  }

  Future<void> importBytes(Uint8List bytes) async {
    if (state.working || ref.read(cloudOwnerProvider) == null) return;
    final epoch = ++_epoch;
    final previous = state.summary;
    state = GeminiActivityState(summary: previous, working: true);
    try {
      final result = await compute(parseGeminiActivityFile, (
        bytes: bytes,
        now: ref.read(clockProvider)(),
      ));
      if (ref.mounted && epoch == _epoch) {
        state = GeminiActivityState(summary: result);
      }
    } catch (error) {
      if (ref.mounted && epoch == _epoch) {
        state = GeminiActivityState(
          summary: previous,
          error: error is FormatException
              ? error.message
              : 'Chưa đọc được file. Hãy thử lại.',
        );
      }
    }
  }

  void clear() {
    _epoch++;
    state = const GeminiActivityState();
  }
}

final geminiActivityProvider =
    NotifierProvider<GeminiActivityViewModel, GeminiActivityState>(
      GeminiActivityViewModel.new,
    );
