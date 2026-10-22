import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Official full-color Google asset; fixed proportions at every text size.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.working = false,
  });

  final VoidCallback? onPressed;
  final bool working;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: working ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSpace.touch, AppSpace.button),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F1F),
        side: const BorderSide(color: Color(0xFF747775)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/auth/google-g.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              working ? 'Đang đăng nhập...' : 'Đăng nhập bằng Google',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}
