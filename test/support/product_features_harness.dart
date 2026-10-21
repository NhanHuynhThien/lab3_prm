import 'dart:async';

import 'package:token_ledger/services/analytics_service.dart';
import 'package:token_ledger/services/remote_config_service.dart';

class FakeAnalyticsTransport implements AnalyticsTransport {
  final calls = <String>[];
  final events =
      <({String name, Map<String, Object> parameters, String? uid})>[];
  String? uid;
  Object? error;
  Completer<void>? identifyGate;

  @override
  Future<void> enable(bool enabled) async {
    calls.add('enable:$enabled');
    if (error != null) throw error!;
  }

  @override
  Future<void> identify(String? value) async {
    if (identifyGate != null) await identifyGate!.future;
    calls.add('identify:$value');
    uid = value;
  }

  @override
  Future<void> event(String name, Map<String, Object> parameters) async {
    if (error != null) throw error!;
    events.add((name: name, parameters: Map.of(parameters), uid: uid));
    calls.add('event:$name');
  }
}

class FakeConfigTransport implements ConfigTransport {
  ConfigPayload payload = const ConfigPayload({}, {});
  int prepares = 0, fetches = 0;
  Object? prepareError, fetchError;
  Completer<void>? gate;

  @override
  Future<void> prepare() async {
    prepares++;
    if (prepareError != null) throw prepareError!;
  }

  @override
  Future<void> fetch() async {
    fetches++;
    if (gate != null) await gate!.future;
    if (fetchError != null) throw fetchError!;
  }

  @override
  ConfigPayload read() => payload;

  void remote(int limit, int warning) => payload = ConfigPayload(
    {'overview_recent_limit': '$limit', 'budget_warning_percent': '$warning'},
    {'overview_recent_limit': 'remote', 'budget_warning_percent': 'remote'},
  );
}
