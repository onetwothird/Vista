import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/shared/widgets/vista_sky.dart';
import 'package:seelai_app/themes/palette.dart';

/// Hero for sign-in, sign-up and role selection. The pup stands on a single
/// still disc over a pale navy wash; the page's sheet curves up over the
/// bottom edge. Drive the pup through [mascotKey].
class AuthMascotHeader extends StatelessWidget {
  const AuthMascotHeader({
    super.key,
    required this.mascotKey,
    required this.pose,
    this.lines = const [],
    this.height = 300,
    this.onBack,
    this.sheetColor,
  });

  final GlobalKey<VistaMascotState> mascotKey;
  final String pose;
  final List<String> lines;
  final double height;
  final VoidCallback? onBack;

  /// Defaults to the page colour, so the sheet edge is seamless.
  final Color? sheetColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.of(context).padding.top;
    final mascotSize = height - 96;
    final lens = mascotSize * 0.96;
    final ink = dark ? Palette.nightText : Palette.ink;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: SizedBox(
        height: topInset + height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: dark ? Palette.nightSurface : Palette.mist,
              ),
            ),
            Positioned(
              bottom: 30 + mascotSize * 0.04,
              child: VistaLens(size: lens, dark: dark),
            ),
            Positioned(
              bottom: 30,
              child: VistaMascot(
                key: mascotKey,
                pose: pose,
                size: mascotSize,
                lines: lines,
              ),
            ),
            // Sheet edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: sheetColor ?? Palette.page(dark),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
              ),
            ),
            Positioned(
              top: topInset + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: ink,
                    iconSize: 26,
                    tooltip: 'Go back',
                    style: IconButton.styleFrom(
                      backgroundColor: dark
                          ? Palette.nightRaised
                          : Colors.white.withValues(alpha: 0.7),
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Vista',
                        style: TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
