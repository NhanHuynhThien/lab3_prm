import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/companion_state.dart';
import 'companion_cloud.dart';
import 'companion_io.dart';
import 'keychain_store.dart';

/// Cancels a pending browser sign-in.
class LoginCancel {
  final _completer = Completer<void>();
  bool get isCancelled => _completer.isCompleted;
  Future<void> get whenCancelled => _completer.future;
  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Signs in once with the user's Google account in the default browser.
/// A loopback page runs Firebase Auth and posts the refresh token back with
/// a one-time state value; the token goes straight into the Keychain.
class BrowserLogin {
  BrowserLogin(
    this.cloud, {
    this.accounts = const AccountFile(),
    this.timeout = const Duration(minutes: 3),
    Future<void> Function(Uri url)? open,
  }) : open = open ?? _openInBrowser;

  final CompanionCloud cloud;
  final AccountFile accounts;
  final Duration timeout;
  final Future<void> Function(Uri url) open;

  static Future<void> _openInBrowser(Uri url) async {
    final result = await Process.run('/usr/bin/open', [url.toString()]);
    if (result.exitCode != 0) throw const FileSystemException('open');
  }

  Future<CompanionAccount> login({LoginCancel? cancel}) async {
    if (cancel?.isCancelled ?? false) {
      throw const CompanionException('Đã hủy đăng nhập.');
    }
    final state = randomHex(32);
    final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    } catch (_) {
      throw const CompanionException('Chưa mở được trang đăng nhập trên máy.');
    }
    final done = Completer<CompanionAccount>();
    void finish({CompanionAccount? account, String? error}) {
      if (done.isCompleted) return;
      error == null
          ? done.complete(account)
          : done.completeError(CompanionException(error));
    }

    final timer = Timer(
      timeout,
      () => finish(error: 'Hết thời gian đăng nhập. Hãy thử lại.'),
    );
    unawaited(
      cancel?.whenCancelled.then((_) => finish(error: 'Đã hủy đăng nhập.')),
    );
    var accepting = false;
    final authority = 'localhost:${server.port}';
    server.listen((request) async {
      final res = request.response;
      res.headers
        ..set('Cache-Control', 'no-store')
        ..set('X-Content-Type-Options', 'nosniff')
        ..set('Referrer-Policy', 'no-referrer');
      Future<void> send(int status, [String text = '']) async {
        res.statusCode = status;
        res.write(text);
        await res.close();
      }

      if (request.headers.value('host') != authority) return send(403);
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/') {
        res.headers.contentType = ContentType.html;
        return send(200, _loginPage(state));
      }
      if (request.method != 'POST' || path != '/session') return send(404);
      if (request.headers.value('origin') != 'http://$authority' ||
          !(request.headers.contentType?.mimeType == 'application/json')) {
        return send(403);
      }
      if (accepting || done.isCompleted) return send(409);
      try {
        final raw = await _readLimited(request, 16384);
        final body = asJson(jsonDecode(raw));
        final token = body?['refreshToken'];
        if (body?['state'] != state ||
            token is! String ||
            token.length > 4096 ||
            accepting ||
            done.isCompleted) {
          return await send(400);
        }
        accepting = true;
        final session = await cloud.exchange(token);
        if (session.uid != body!['uid']) throw const FormatException('uid');
        if (done.isCompleted) return await send(409);
        await cloud.secrets.save(session.refreshToken ?? token);
        if (done.isCompleted) return await send(409);
        final email = body['email'];
        final account = CompanionAccount(
          uid: session.uid,
          email: email is String
              ? email.substring(0, email.length.clamp(0, 254))
              : null,
        );
        await accounts.write(account);
        // Let the browser receive the successful response before closing.
        await send(204);
        finish(account: account);
      } catch (_) {
        accepting = false;
        if (!done.isCompleted) await send(400);
      }
    });
    try {
      await open(Uri.parse('http://$authority/'));
    } catch (_) {
      finish(error: 'Chưa mở được trình duyệt đăng nhập.');
    }
    try {
      return await done.future;
    } finally {
      timer.cancel();
      await server.close(force: true);
    }
  }

  static Future<String> _readLimited(HttpRequest request, int limit) async {
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > limit) throw const FormatException('too large');
    }
    return utf8.decode(bytes);
  }

  String _loginPage(String state) {
    const v = '10.12.2';
    final cfg = jsonEncode(cloud.config.toJson());
    return '''<!doctype html><meta charset="utf-8"><title>TokenLedger Companion</title>
<body style="font:16px system-ui;max-width:520px;margin:64px auto;padding:0 16px">
<h2>TokenLedger Companion</h2>
<p>Đăng nhập đúng tài khoản Google bạn dùng trong app. Companion sẽ ghi số liệu token của máy này vào tài khoản đó.</p>
<button id="go" style="font:inherit;padding:12px 20px">Đăng nhập Google</button><p id="msg"></p>
<script type="module">
import { initializeApp } from 'https://www.gstatic.com/firebasejs/$v/firebase-app.js';
import { getAuth, setPersistence, inMemoryPersistence, GoogleAuthProvider, signInWithPopup } from 'https://www.gstatic.com/firebasejs/$v/firebase-auth.js';
const auth = getAuth(initializeApp($cfg));
const msg = document.getElementById('msg');
document.getElementById('go').onclick = async () => {
  try {
    await setPersistence(auth, inMemoryPersistence);
    const { user } = await signInWithPopup(auth, new GoogleAuthProvider());
    const res = await fetch('/session', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({
      state: ${jsonEncode(state)}, uid: user.uid, email: user.email, refreshToken: user.refreshToken }) });
    msg.textContent = res.ok ? 'Xong. ' + user.email + ' đã được kết nối, có thể đóng tab này.' : 'Không lưu được phiên.';
  } catch (e) { msg.textContent = 'Đăng nhập chưa hoàn tất: ' + e.code; }
};
</script>''';
  }
}
