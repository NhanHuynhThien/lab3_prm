import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';
import 'remote_config_service.dart';

class FirebaseAnalyticsTransport implements AnalyticsTransport {
  FirebaseAnalytics get _sdk => FirebaseAnalytics.instance;
  @override
  Future<void> enable(bool enabled) =>
      _sdk.setAnalyticsCollectionEnabled(enabled);
  @override
  Future<void> identify(String? uid) => _sdk.setUserId(id: uid);
  @override
  Future<void> event(String name, Map<String, Object> parameters) =>
      _sdk.logEvent(
        name: name,
        parameters: {
          ...parameters,
          if (const bool.fromEnvironment('FIREBASE_ANALYTICS_DEBUG'))
            'debug_mode': 1,
        },
      );
}

class FirebaseConfigTransport implements ConfigTransport {
  FirebaseRemoteConfig get _sdk => FirebaseRemoteConfig.instance;
  @override
  Future<void> prepare() async {
    await _sdk.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 12),
      ),
    );
    await _sdk.setDefaults(RemoteConfigService.defaults);
    await _sdk.ensureInitialized();
  }

  @override
  Future<void> fetch() async {
    await _sdk.fetchAndActivate();
  }

  @override
  ConfigPayload read() {
    final values = _sdk.getAll();
    return ConfigPayload(
      {
        for (final key in RemoteConfigService.defaults.keys)
          key: values[key]?.asString() ?? '',
      },
      {
        for (final key in RemoteConfigService.defaults.keys)
          key: values[key]?.source == ValueSource.valueRemote
              ? 'remote'
              : 'default',
      },
    );
  }
}
