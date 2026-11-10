import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/companion_state.dart';
import '../services/browser_login.dart';
import '../services/keychain_store.dart';

typedef SyncResult = ({List<String> providers, bool published});

/// Side effects the controller orchestrates; real ones live in services.
class CompanionDependencies {
  const CompanionDependencies({
    required this.readAccount,
    required this.readPreferences,
    required this.writePreferences,
    required this.login,
    required this.logout,
    required this.sync,
    required this.setAutoStart,
    required this.readAutoStart,
    required this.retireLegacyService,
    this.watchChanges,
    this.packaged = false,
    this.interval = const Duration(minutes: 5),
    this.retry,
  });
  final Future<CompanionAccount?> Function() readAccount;
  final Future<CompanionPreferences> Function() readPreferences;
  final Future<void> Function(CompanionPreferences) writePreferences;
  final Future<void> Function(LoginCancel cancel) login;
  final Future<void> Function() logout;
  final Future<SyncResult> Function(String uid, {bool tokensOnly}) sync;
  final Future<void> Function(bool enabled) setAutoStart;
  final bool Function() readAutoStart;
  final Future<void> Function() retireLegacyService;

  /// Starts a change watcher and returns its close callback.
  final void Function() Function(void Function() onChange)? watchChanges;
  final bool packaged;
  final Duration interval;
  final Duration? retry;
}

final companionDependenciesProvider = Provider<CompanionDependencies>(
  (ref) => throw UnimplementedError('Override in main_companion.dart'),
);

final companionControllerProvider =
    NotifierProvider<CompanionController, CompanionState>(
      CompanionController.new,
    );

const _syncFailed =
    'Chưa đồng bộ được. Kiểm tra kết nối mạng hoặc đăng nhập lại.';

String _message(Object error) => error is CompanionException
    ? error.message
    : 'Chưa hoàn tất thao tác. Hãy thử lại.';

class CompanionController extends Notifier<CompanionState> {
  late CompanionDependencies _d;
  Future<void>? _pending, _connecting;
  Timer? _timer, _retryTimer;
  void Function()? _closeWatcher;
  LoginCancel? _loginCancel;
  var _closing = false, _usageDirty = false, _retryAttempt = 0;

  @override
  CompanionState build() {
    _d = ref.watch(companionDependenciesProvider);
    ref.onDispose(close);
    return CompanionState(autoStart: _d.readAutoStart(), packaged: _d.packaged);
  }

  void reportError(String message) => state = state.copyWith(error: message);

  Future<void> _persist() => _d.writePreferences(
    CompanionPreferences(
      uid: state.account?.uid,
      enabled: state.enabled,
      consent: state.consent,
      lastSyncedAt: state.lastSyncedAt,
      providers: state.providers,
    ),
  );

  Future<void> initialize() async {
    final [account as CompanionAccount?, prefs as CompanionPreferences] =
        await Future.wait<Object?>([_d.readAccount(), _d.readPreferences()]);
    final sameOwner = account != null && prefs.uid == account.uid;
    state = state.copyWith(
      account: account,
      consent: sameOwner && prefs.consent,
      lastSyncedAt: sameOwner ? prefs.lastSyncedAt : null,
      providers: sameOwner ? prefs.providers : const [],
    );
    if (sameOwner && prefs.consent && prefs.enabled) await enable();
  }

  void _stopSchedule() {
    _timer?.cancel();
    _retryTimer?.cancel();
    _closeWatcher?.call();
    _timer = _closeWatcher = null;
    _usageDirty = false;
  }

  Future<void>? _requestUsageSync() {
    if (!state.enabled || !state.consent || _closing) return null;
    if (_pending != null) {
      _usageDirty = true;
      return _pending;
    }
    return sync(tokensOnly: true);
  }

  void _schedule() {
    _stopSchedule();
    _closeWatcher = _d.watchChanges?.call(() => unawaited(_requestUsageSync()));
    _timer = Timer.periodic(_d.interval, (_) {
      if (state.enabled) unawaited(sync());
    });
  }

  Future<void> connect({required bool consent, required bool autoStart}) =>
      _connecting ??= _finishConnection(
        consent,
        autoStart,
      ).whenComplete(() => _connecting = null);

  Future<void> _finishConnection(bool consent, bool autoStart) async {
    if (!consent) {
      throw const CompanionException(
        'Đồng ý đồng bộ số liệu trước khi kết nối.',
      );
    }
    if (state.signingIn || _closing) return;
    state = state.copyWith(signingIn: true, error: null);
    final cancel = _loginCancel = LoginCancel();
    try {
      if (state.account == null) {
        await _d.login(cancel);
        if (_closing) return;
        state = state.copyWith(account: await _d.readAccount());
      }
      if (state.account == null) {
        throw const CompanionException('Chưa lưu được tài khoản đăng nhập.');
      }
      // Preserve consent before changing OS startup settings, so a failed
      // startup registration can be retried without another Google login.
      state = state.copyWith(consent: true);
      await _persist();
      await setAutoStart(autoStart);
      await enable();
    } catch (error) {
      if (!_closing) state = state.copyWith(error: _message(error));
    } finally {
      _loginCancel = null;
      if (ref.mounted) state = state.copyWith(signingIn: false);
    }
  }

  Future<void> setAutoStart(bool value) async {
    try {
      await _d.setAutoStart(value);
    } finally {
      state = state.copyWith(autoStart: _d.readAutoStart());
    }
  }

  Future<void> enable() async {
    if (state.account == null || !state.consent || _closing) return;
    // Replace the old CLI service only after the desktop app is connected.
    await _d.retireLegacyService();
    state = state.copyWith(enabled: true, error: null);
    await _persist();
    if (!state.enabled || _closing) return;
    _retryAttempt = 0;
    _schedule();
    await sync();
  }

  Future<void> pause() async {
    _stopSchedule();
    state = state.copyWith(enabled: false);
    await _persist();
    await _pending;
  }

  Future<void> sync({bool tokensOnly = false, bool interactive = false}) {
    if (_pending != null) {
      if (interactive && !state.busy) state = state.copyWith(busy: true);
      return _pending!;
    }
    final account = state.account;
    if (account == null || !state.consent || _closing) return Future.value();
    _retryTimer?.cancel();
    if (interactive) state = state.copyWith(busy: true, error: null);
    return _pending = _runSync(account, tokensOnly);
  }

  Future<void> _runSync(CompanionAccount account, bool tokensOnly) async {
    await Future<void>.value();
    try {
      final result = await _d.sync(account.uid, tokensOnly: tokensOnly);
      _retryAttempt = 0;
      if (result.published) {
        state = state.copyWith(
          providers: result.providers,
          lastSyncedAt: DateTime.now().toUtc().toIso8601String(),
          error: null,
        );
        await _persist();
      } else if (state.error != null) {
        state = state.copyWith(error: null);
      }
    } catch (error) {
      final message = error is CompanionException ? error.message : _syncFailed;
      if (state.error != message) state = state.copyWith(error: message);
      if (state.enabled && !_closing) {
        final wait =
            _d.retry ??
            Duration(
              milliseconds: min(30000, 1000 * (1 << min(++_retryAttempt, 5))),
            );
        _retryTimer = Timer(wait, () {
          if (state.enabled && !_closing) {
            unawaited(sync(tokensOnly: tokensOnly));
          }
        });
      }
    } finally {
      _pending = null;
      if (ref.mounted && state.busy) state = state.copyWith(busy: false);
      if (_usageDirty && state.enabled && !_closing) {
        _usageDirty = false;
        scheduleMicrotask(() {
          if (state.enabled && !_closing) unawaited(sync(tokensOnly: true));
        });
      }
    }
  }

  Future<void> disconnect() async {
    if (state.signingIn) _loginCancel?.cancel();
    await _connecting;
    await pause();
    await setAutoStart(false);
    await _d.logout();
    state = state.copyWith(
      account: null,
      consent: false,
      providers: const [],
      lastSyncedAt: null,
      error: null,
    );
    await _persist();
  }

  void close() {
    _closing = true;
    _stopSchedule();
    _loginCancel?.cancel();
  }
}
