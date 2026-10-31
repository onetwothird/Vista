import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/themes/palette.dart';

enum ToastType { success, error, info }

/// Floating toast with the Vista pup's face, coloured by [ToastType].
abstract final class VistaToast {
  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final (accent, tint, pose, icon) = switch (type) {
      ToastType.success => (
        Palette.success,
        Palette.successTint,
        MascotPose.celebrating,
        Icons.check_circle_rounded,
      ),
      ToastType.error => (
        Palette.alert,
        Palette.alertTint,
        MascotPose.sad,
        Icons.error_rounded,
      ),
      ToastType.info => (
        Palette.violet,
        Palette.violetTint,
        MascotPose.welcome,
        Icons.info_rounded,
      ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          content: _ToastCard(
            message: message,
            accent: accent,
            tint: tint,
            pose: pose,
            icon: icon,
          ),
        ),
      );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.message,
    required this.accent,
    required this.tint,
    required this.pose,
    required this.icon,
  });

  final String message;
  final Color accent;
  final Color tint;
  final String pose;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 24),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Palette.ink.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
        child: Row(
          children: [
            // Pup's face, cropped from the full pose.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: OverflowBox(
                maxWidth: 104,
                maxHeight: 104,
                alignment: const Alignment(0, -0.52),
                child: Image.asset(
                  pose,
                  width: 104,
                  height: 104,
                  cacheWidth: (104 * dpr).round(),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: accent, size: 26),
          ],
        ),
      ),
    );
  }
}
