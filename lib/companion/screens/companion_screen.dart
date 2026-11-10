import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../models/companion_state.dart';
import '../viewmodels/companion_controller.dart';
import '../widgets/companion_panels.dart';
import '../widgets/companion_sections.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});
  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  var _working = false, _consentChoice = false, _autoStartChoice = true;

  CompanionController get _controller =>
      ref.read(companionControllerProvider.notifier);

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } catch (error) {
      _controller.reportError(
        error.toString().isEmpty
            ? 'Chưa hoàn tất thao tác. Hãy thử lại.'
            : '$error',
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(companionControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final setup = _setupPanel(s);
    final sources = SourcesPanel(state: s);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CompanionHeader(state: s),
                    const CompanionIntro(),
                    _accountPanel(s),
                    const SizedBox(height: AppSpace.lg),
                    if (wide)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 11, child: setup),
                            const SizedBox(width: AppSpace.lg),
                            Expanded(flex: 10, child: sources),
                          ],
                        ),
                      )
                    else ...[
                      setup,
                      const SizedBox(height: AppSpace.lg),
                      sources,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountPanel(CompanionState s) => CompanionPanel(
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const ExcludeSemantics(
            child: Text(
              'G',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.account != null
                    ? 'Tài khoản đã kết nối'
                    : 'Kết nối tài khoản của bạn',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                s.account?.email ??
                    'Dùng cùng tài khoản Google với ứng dụng TokenLedger.',
                style: const TextStyle(fontSize: 12, color: companionMuted),
              ),
            ],
          ),
        ),
        if (s.account != null)
          TextButton(
            onPressed: _working || s.signingIn || s.busy
                ? null
                : () => _run(() {
                    _consentChoice = false;
                    return _controller.disconnect();
                  }),
            child: const Text('Đăng xuất'),
          ),
      ],
    ),
  );

  Widget _setupPanel(CompanionState s) {
    final consentChecked = s.consent || _consentChoice;
    final connected = s.account != null && s.consent;
    final autoStart = connected ? s.autoStart : _autoStartChoice;
    return CompanionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.active
                ? 'Đang đồng bộ realtime'
                : s.consent
                ? 'Đã ngắt đồng bộ'
                : 'Bắt đầu đồng bộ',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            s.active
                ? 'Số liệu mới được gửi ngay khi log CLI thay đổi; hạn mức kiểm tra mỗi 5 phút.'
                : s.consent
                ? 'Bấm Đồng bộ để gửi số liệu và tự cập nhật realtime.'
                : 'Đăng nhập trong trình duyệt của bạn, sau đó quay lại đây.',
            style: const TextStyle(fontSize: 12, color: companionMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          if (!s.consent)
            ConsentCheck(
              label: 'Tôi đồng ý đồng bộ số liệu tổng hợp từ máy này vào tài khoản TokenLedger.',
              value: consentChecked,
              onChanged: _working || s.signingIn
                  ? null
                  : (v) => setState(() => _consentChoice = v),
            ),
          ConsentCheck(
            label: 'Tự mở Companion khi đăng nhập máy tính',
            value: autoStart,
            onChanged: _working || s.signingIn
                ? null
                : (v) {
                    setState(() => _autoStartChoice = v);
                    if (connected) _run(() => _controller.setAutoStart(v));
                  },
          ),
          const SizedBox(height: AppSpace.sm),
          if (!connected) _connectButton(s, consentChecked),
          if (connected) _controls(s),
          if (s.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.md),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  s.error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ),
            ),
          if (s.signingIn)
            const Padding(
              padding: EdgeInsets.only(top: AppSpace.md),
              child: Text(
                'Hoàn tất đăng nhập trong trình duyệt. Cửa sổ này sẽ tự cập nhật.',
                style: TextStyle(fontSize: 12, color: companionMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _connectButton(CompanionState s, bool consentChecked) => SizedBox(
    height: AppSpace.button,
    child: FilledButton(
      onPressed: _working || s.signingIn || !consentChecked
          ? null
          : () => _run(
              () => _controller.connect(
                consent: consentChecked,
                autoStart: _autoStartChoice,
              ),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.account == null) ...[
            Image.asset('assets/auth/google-g.png', width: 20, height: 20),
            const SizedBox(width: 10),
          ],
          Text(
            s.signingIn
                ? 'Đang chờ đăng nhập…'
                : s.account != null
                ? 'Bật đồng bộ nền'
                : 'Đăng nhập Google',
          ),
        ],
      ),
    ),
  );

  /// One switch: on means an immediate sync, then realtime updates from the
  /// CLI log watcher; off stops every background upload.
  Widget _controls(CompanionState s) {
    final on = s.enabled;
    final disabled = _working || s.signingIn;
    final label = disabled && !s.signingIn
        ? (on ? 'Đang ngắt…' : 'Đang bật đồng bộ…')
        : s.busy
        ? 'Đang đồng bộ…'
        : on
        ? 'Ngắt đồng bộ'
        : 'Đồng bộ';
    void toggle() =>
        _run(() => on ? _controller.pause() : _controller.enable());
    return SizedBox(
      height: AppSpace.button,
      child: on
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              onPressed: disabled ? null : toggle,
              icon: const Icon(Icons.sync_disabled_rounded, size: 20),
              label: Text(label),
            )
          : FilledButton.icon(
              onPressed: disabled ? null : toggle,
              icon: const Icon(Icons.sync_rounded, size: 20),
              label: Text(label),
            ),
    );
  }
}
