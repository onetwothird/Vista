import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';

/// Shown when a list has nothing in it yet: the pup, a plain title saying
/// what is missing, and a line saying what to do about it.
class VistaEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final bool isDarkMode;
  final Widget? action;
  final double mascotSize;

  const VistaEmptyState({
    super.key,
    required this.title,
    this.message,
    required this.isDarkMode,
    this.action,
    this.mascotSize = 150,
  });

  static const asset = 'assets/vista-icons/empty-state-vista.png';

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    return Semantics(
      container: true,
      label: message == null ? title : '$title. $message',
      excludeSemantics: action == null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: BoxDecoration(
          color: Palette.card(dark),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Palette.border(dark)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: mascotSize,
              height: mascotSize,
              cacheWidth: (mascotSize * 3).round(),
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Palette.text(dark),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Palette.muted(dark),
                  ),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
