import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/provider_usage.dart';
import '../theme/app_theme.dart';

class ProviderBrandIcon extends StatelessWidget {
  const ProviderBrandIcon(this.sourceId, {super.key, this.size = 32});
  final String sourceId;
  final double size;
  @override
  Widget build(BuildContext context) {
    final asset = switch (sourceId) {
      'codex' => 'assets/providers/openai.svg',
      'claude' => 'assets/providers/claude.png',
      'google' || 'gemini-web' => 'assets/providers/gemini.png',
      'antigravity' => 'assets/providers/antigravity.svg',
      _ => null,
    };
    return Semantics(
      label: 'Logo ${providerNames[sourceId] ?? 'nguồn AI'}',
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size + AppSpace.lg,
        height: size + AppSpace.lg,
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        ),
        child: asset == null
            ? Icon(Icons.hub_outlined, size: size)
            : asset.endsWith('.svg')
            ? SvgPicture.asset(asset, width: size, height: size)
            : Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
