import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({
    super.key,
    required this.title,
    required this.child,
    this.footer,
  });
  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: math.max(
        kToolbarHeight,
        MediaQuery.textScalerOf(context).scale(26) * 2 + AppSpace.xs,
      ),
      title: Tooltip(
        message: title,
        child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 720, child: child),
    ),
    bottomNavigationBar: footer == null
        ? null
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Center(
                  heightFactor: 1,
                  child: SizedBox(width: 688, child: footer),
                ),
              ),
            ),
          ),
  );
}
