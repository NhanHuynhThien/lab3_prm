import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/companion/models/companion_state.dart';
import 'package:token_ledger/companion/services/keychain_store.dart';
import 'package:token_ledger/companion/viewmodels/companion_controller.dart';

/// Records side effects of the controller without touching the machine.
class FakeHost {
  CompanionAccount? account;
  CompanionPreferences prefs = const CompanionPreferences();
  final calls = <String>[];
  Completer<SyncResult>? gate;
  Object? syncError;
  var published = true;
  void Function()? onChange;
  var watcherClosed = false;

  CompanionDependencies deps() => CompanionDependencies(
    readAccount: () async => account,
    readPreferences: () async => prefs,
    writePreferences: (value) async => prefs = value,
    login: (cancel) async {
      calls.add('login');
      account = const CompanionAccount(uid: 'u1', email: 'qa@example.test');
    },
    logout: () async {
      calls.add('logout');
      account = null;
    },
    sync: (uid, {tokensOnly = false}) async {
      calls.add(tokensOnly ? 'tokens:$uid' : 'sync:$uid');
      if (syncError != null) throw syncError!;
      if (gate != null) return gate!.future;
      return (providers: ['codex'], published: published);
    },
    setAutoStart: (value) async => calls.add('autoStart:$value'),
    readAutoStart: () => false,
    retireLegacyService: () async => calls.add('retire'),
    watchChanges: (callback) {
      onChange = callback;
      return () => watcherClosed = true;
    },
    retry: const Duration(hours: 1),
  );
}

(ProviderContainer, CompanionController) start(FakeHost host) {
  final container = ProviderContainer(
    overrides: [companionDependenciesProvider.overrideWithValue(host.deps())],
  );
  addTearDown(container.dispose);
  return (container, container.read(companionControllerProvider.notifier));
}

void main() {
  test('a remembered account requires consent before syncing', () async {
    final host = FakeHost()
      ..account = const CompanionAccount(uid: 'u1')
      ..prefs = const CompanionPreferences(uid: 'u1', enabled: true);
    final (c, controller) = start(host);
    await controller.initialize();
    expect(c.read(companionControllerProvider).enabled, isFalse);
    expect(host.calls, isEmpty);
  });

  test('connect retires legacy service, persists consent and syncs', () async {
    final host = FakeHost();
    final (c, controller) = start(host);
    await controller.connect(consent: true, autoStart: false);
    final state = c.read(companionControllerProvider);
    expect(host.calls, ['login', 'autoStart:false', 'retire', 'sync:u1']);
    expect(state.active, isTrue);
    expect(state.providers, ['codex']);
    expect(host.prefs.consent, isTrue);
    expect(host.prefs.uid, 'u1');
  });

  test('preferences for another UID never start collection', () async {
    final host = FakeHost()
      ..account = const CompanionAccount(uid: 'u2')
      ..prefs = const CompanionPreferences(
        uid: 'u1',
        consent: true,
        enabled: true,
        providers: ['codex'],
      );
    final (c, controller) = start(host);
    await controller.initialize();
    final state = c.read(companionControllerProvider);
    expect(state.consent, isFalse);
    expect(state.providers, isEmpty);
    expect(host.calls, isEmpty);
  });

  test('concurrent syncs share one call and logout waits for it', () async {
    final host = FakeHost();
    final (c, controller) = start(host);
    await controller.connect(consent: true, autoStart: false);
    host.calls.clear();
    host.gate = Completer();
    final first = controller.sync(interactive: true);
    final second = controller.sync(interactive: true);
    expect(c.read(companionControllerProvider).busy, isTrue);
    final logout = controller.disconnect();
    host.gate!.complete((providers: ['claude'], published: true));
    await Future.wait([first, second, logout]);
    expect(host.calls.where((e) => e.startsWith('sync')).length, 1);
    final state = c.read(companionControllerProvider);
    expect(state.account, isNull);
    expect(state.busy, isFalse);
    expect(host.calls.last, 'logout');
  });

  test('a failed sync shows a safe message and does not stay busy', () async {
    final host = FakeHost();
    final (c, controller) = start(host);
    await controller.connect(consent: true, autoStart: false);
    host.syncError = StateError('socket details');
    await controller.sync(interactive: true);
    var state = c.read(companionControllerProvider);
    expect(state.error, contains('Chưa đồng bộ được'));
    expect(state.busy, isFalse);
    host.syncError = null;
    await controller.sync(interactive: true);
    state = c.read(companionControllerProvider);
    expect(state.error, isNull);
  });

  test('pause persists disabled; resume performs a fresh sync', () async {
    final host = FakeHost();
    final (c, controller) = start(host);
    await controller.connect(consent: true, autoStart: false);
    await controller.pause();
    expect(host.prefs.enabled, isFalse);
    expect(host.watcherClosed, isTrue);
    host.calls.clear();
    await controller.enable();
    expect(host.calls, ['retire', 'sync:u1']);
    expect(c.read(companionControllerProvider).active, isTrue);
  });

  test('a usage change during upload schedules one token refresh', () async {
    final host = FakeHost();
    final (_, controller) = start(host);
    await controller.connect(consent: true, autoStart: false);
    host.calls.clear();
    host.gate = Completer();
    final running = controller.sync();
    host.onChange!();
    host.onChange!();
    host.gate!.complete((providers: ['codex'], published: true));
    host.gate = null;
    await running;
    await pumpEventQueue();
    expect(host.calls, ['sync:u1', 'tokens:u1']);
  });

  test('unchanged background refresh leaves last sync untouched', () async {
    final host = FakeHost();
    final (c, controller) = start(host);
    await controller.connect(consent: true, autoStart: false);
    final before = c.read(companionControllerProvider).lastSyncedAt;
    host.published = false;
    await controller.sync(tokensOnly: true);
    final state = c.read(companionControllerProvider);
    expect(state.lastSyncedAt, before);
    expect(state.busy, isFalse);
  });

  test('connect without consent is rejected', () async {
    final (_, controller) = start(FakeHost());
    expect(
      controller.connect(consent: false, autoStart: false),
      throwsA(isA<CompanionException>()),
    );
  });
}
