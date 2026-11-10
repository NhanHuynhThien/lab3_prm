import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/brand_mark.dart';
import '../models/companion_state.dart';
import 'companion_panels.dart';

const _sources = {
  'codex': 'Codex',
  'claude': 'Claude Code',
  'google': 'Gemini CLI',
  'antigravity': 'Antigravity',
};

class CompanionHeader extends StatelessWidget {
  const CompanionHeader({super.key, required this.state});
  final CompanionState state;
  @override
  Widget build(BuildContext context) {
    final s = state;
    final (label, tone) = s.signingIn
        ? ('Chờ đăng nhập', BadgeTone.neutral)
        : s.busy
        ? ('Đang đồng bộ', BadgeTone.neutral)
        : s.error != null
        ? ('Cần kiểm tra', BadgeTone.error)
        : s.active
        ? ('Đã kết nối', BadgeTone.ready)
        : s.account != null
        ? ('Đã đăng nhập', BadgeTone.neutral)
        : ('Chưa kết nối', BadgeTone.neutral);
    return Row(
      children: [
        const BrandMark(size: 44),
        const SizedBox(width: AppSpace.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TokenLedger',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Companion cho máy tính',
                style: TextStyle(fontSize: 12, color: companionMuted),
              ),
            ],
          ),
        ),
        StatusBadge(label: label, tone: tone),
      ],
    );
  }
}

class CompanionIntro extends StatelessWidget {
  const CompanionIntro({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 28, bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số liệu trên máy.\nLiền mạch với điện thoại.',
          style: TextStyle(
            fontSize: 29,
            height: 1.2,
            letterSpacing: -0.85,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpace.md),
        Text(
          'Kết nối một lần để đồng bộ token, model và mục đích sử dụng từ các nguồn AI trên máy này.',
          style: TextStyle(color: companionMuted, fontSize: 14),
        ),
      ],
    ),
  );
}

class SourcesPanel extends StatelessWidget {
  const SourcesPanel({super.key, required this.state});
  final CompanionState state;
  @override
  Widget build(BuildContext context) {
    final s = state;
    return CompanionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nguồn trên máy này',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpace.sm),
          for (final MapEntry(key: id, value: name) in _sources.entries)
            SourceRow(
              name: name,
              ready: s.providers.contains(id),
              status: s.providers.contains(id)
                  ? 'Đã đồng bộ'
                  : s.lastSyncedAt != null
                  ? 'Chưa có số liệu'
                  : 'Chờ đồng bộ',
            ),
          const CompanionClock(),
        ],
      ),
    );
  }
}
