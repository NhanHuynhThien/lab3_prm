import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gemini_analysis.dart';
import '../services/gemini_aggregate.dart';
import 'auth_viewmodel.dart';
import 'ledger_viewmodel.dart';
import 'product_features_viewmodel.dart';

final geminiAggregateProvider = Provider<GeminiAggregate>(
  (ref) => GeminiAggregate(
    ref.watch(filteredSessionsProvider),
    ref.watch(nowProvider),
  ),
);

class GeminiAnalysisViewModel extends Notifier<AsyncValue<GeminiAnalysis?>> {
  @override
  AsyncValue<GeminiAnalysis?> build() => const AsyncData(null);
  Future<void> analyze(GeminiAggregate aggregate) async {
    if (state.isLoading || !aggregate.eligible) return;
    final uid = ref.read(authSessionProvider).asData?.value?.uid;
    final api = ref.read(platformApiProvider);
    if (uid == null || api == null) {
      state = AsyncError(
        'Backend phân tích chưa sẵn sàng.',
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    try {
      final result = await api.request(
        uid,
        '/v1/me/analyses',
        method: 'POST',
        body: aggregate.payload,
      );
      if (!ref.mounted ||
          ref.read(authSessionProvider).asData?.value?.uid != uid) {
        return;
      }
      state = AsyncData(
        GeminiAnalysis({
          ...result,
          'periodStart': aggregate.start.toIso8601String(),
          'periodEnd': aggregate.end.toIso8601String(),
          'sampleSessions': aggregate.sessionCount,
        }),
      );
    } catch (e, stack) {
      if (ref.mounted &&
          ref.read(authSessionProvider).asData?.value?.uid == uid) {
        state = AsyncError(e, stack);
      }
    }
  }
}

final geminiAnalysisProvider =
    NotifierProvider<GeminiAnalysisViewModel, AsyncValue<GeminiAnalysis?>>(
      GeminiAnalysisViewModel.new,
    );
