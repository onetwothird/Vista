import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';

/// The Vista backdrop shared by onboarding, role selection and auth.
///
/// A calm, flat wash of the harness navy. It deliberately carries no motion
/// or texture: the pup is the only thing on it that should draw the eye.
/// [t], [page] and [horizon] are accepted for older call sites and ignored.
class VistaSkyPainter extends CustomPainter {
  VistaSkyPainter({
    this.t = 0,
    this.page = 0,
    this.horizon = 0,
    this.dark = false,
  });

  final double t;
  final double page;
  final double horizon;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? Palette.nightSurface : Palette.mist,
    );
  }

  @override
  bool shouldRepaint(VistaSkyPainter old) => old.dark != dark;
}

/// A single still disc that sits behind the pup and frames it.
class VistaLens extends StatelessWidget {
  const VistaLens({super.key, required this.size, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? Palette.nightRaised : Palette.mistDeep,
        ),
      ),
    );
  }
}
