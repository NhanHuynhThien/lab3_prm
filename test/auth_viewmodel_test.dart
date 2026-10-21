import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token_ledger/models/auth_session.dart';
import 'package:token_ledger/viewmodels/auth_viewmodel.dart';

import 'support/auth_fakes.dart';

void main() {
  late FakeAuthService service;
  late ProviderContainer container;
  void watchAuth() {
    container.listen(authSessionProvider, (_, _) {});
  }

  setUp(() {
    service = FakeAuthService();
    container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(service)],
    );
  });
  tearDown(() async {
    container.dispose();
    await service.changes.close();
  });

  test(
    'sign-in waits for auth restore and double tap produces one operation',
    () async {
      service.initializationGate = Completer<void>();
      watchAuth();
      final vm = container.read(authActionProvider.notifier);
      await vm.signIn();
      expect(service.signIns, 0);
      service.initializationGate!.complete();
      await container.read(authSessionProvider.future);
      service.signInGate = Completer<void>();
      final pending = vm.signIn();
      await vm.signIn();
      expect(service.signIns, 1);
      expect(container.read(authActionProvider).working, isTrue);
      service.signInGate!.complete();
      await pending;
      expect(container.read(authActionProvider).working, isFalse);
    },
  );

  test(
    'cancel/network feedback is retryable and never publishes a fake user',
    () async {
      watchAuth();
      await container.read(authSessionProvider.future);
      final vm = container.read(authActionProvider.notifier);
      service.signInError = const AuthFailure(
        AuthProblem.cancelled,
        'Hủy đăng nhập',
      );
      await vm.signIn();
      expect(
        container.read(authActionProvider).failure!.isCancellation,
        isTrue,
      );
      expect(container.read(authSessionProvider).requireValue, isNull);
      service.signInError = const AuthFailure(
        AuthProblem.network,
        'Kiểm tra mạng',
      );
      await vm.signIn();
      expect(
        container.read(authActionProvider).failure!.problem,
        AuthProblem.network,
      );
      service.signInError = null;
      await vm.signIn();
      expect(container.read(authActionProvider).failure, isNull);
      expect(service.signIns, 3);
      expect(container.read(authSessionProvider).requireValue, isNull);
    },
  );

  test('connection failure retry recreates the auth stream', () async {
    service.initializationError = const AuthFailure(
      AuthProblem.network,
      'Không kết nối',
    );
    watchAuth();
    await expectLater(
      container.read(authSessionProvider.future),
      throwsA(isA<AuthFailure>()),
    );
    service.initializationError = null;
    container.read(authActionProvider.notifier).retryConnection();
    expect(await container.read(authSessionProvider.future), isNull);
    expect(service.initializations, 2);
  });

  test(
    'dispose during pending sign-in does not mutate disposed state',
    () async {
      watchAuth();
      await container.read(authSessionProvider.future);
      service.signInGate = Completer<void>();
      final pending = container.read(authActionProvider.notifier).signIn();
      container.invalidate(authActionProvider);
      service.signInGate!.complete();
      await pending;
      expect(container.read(authActionProvider).failure, isNull);
      expect(container.read(authActionProvider).working, isFalse);
    },
  );

  test('failed logout keeps real session and permits retry', () async {
    service.user = const AuthUser(uid: 'A');
    watchAuth();
    await container.read(authSessionProvider.future);
    final vm = container.read(authActionProvider.notifier);
    service.signOutError = const AuthFailure(
      AuthProblem.network,
      'Lỗi đăng xuất',
    );
    await vm.signOut();
    expect(container.read(authSessionProvider).requireValue!.uid, 'A');
    expect(
      container.read(authActionProvider).failure!.problem,
      AuthProblem.network,
    );
    service.signOutError = null;
    await vm.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authSessionProvider).requireValue, isNull);
  });
}
