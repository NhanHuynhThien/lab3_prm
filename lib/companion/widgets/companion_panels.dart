import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const companionMuted = Color(0xFF52625C);

class CompanionPanel extends StatelessWidget {
  const CompanionPanel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

enum BadgeTone { neutral, ready, error }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});
  final String label;
  final BadgeTone tone;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.ready => (AppColors.soft, AppColors.primary),
      BadgeTone.error => (AppColors.error, const Color(0xFF8D2217)),
      BadgeTone.neutral => (const Color(0xFFECEFEA), companionMuted),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(label, style: TextStyle(fontSize: 12, color: fg)),
        ),
      ),
    );
  }
}

class ConsentCheck extends StatelessWidget {
  const ConsentCheck({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.touch),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged!(v ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, height: 1.55),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SourceRow extends StatelessWidget {
  const SourceRow({
    super.key,
    required this.name,
    required this.status,
    required this.ready,
  });
  final String name;
  final String status;
  final bool ready;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: AppSpace.touch),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: ready ? AppColors.primary : companionMuted,
            fontWeight: ready ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

/// Local clock that ticks every second, using the computer's time zone.
class CompanionClock extends StatefulWidget {
  const CompanionClock({super.key});
  @override
  State<CompanionClock> createState() => _CompanionClockState();
}

class _CompanionClockState extends State<CompanionClock> {
  late DateTime _now = DateTime.now();
  late final Timer _timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() => _now = DateTime.now()),
  );

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final n = _now;
    final text =
        '${two(n.hour)}:${two(n.minute)}:${two(n.second)} ${two(n.day)}/${two(n.month)}/${n.year}';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Giờ hiện tại',
              style: TextStyle(fontSize: 12, color: companionMuted),
            ),
          ),
          ExcludeSemantics(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
