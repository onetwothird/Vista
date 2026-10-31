import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';

/// The Vista backdrop shared by onboarding, role selection and auth:
/// a dusk sky over rolling hills, the "vista".
/// Stars twinkle, aurora glows drift, and a sunrise glow behind the hills
/// takes each slide's colour. The hills slide a little with every swipe.
class VistaSkyPainter extends CustomPainter {
  VistaSkyPainter({required this.t, required this.page, required this.horizon});

  final double t;
  final double page;
  final double horizon;

  static const _accents = [
    Palette.honey,
    Palette.tealBright,
    Palette.tongue,
    Palette.honey,
  ];

  static final _stars = () {
    final r = math.Random(7);
    return List.generate(
      30,
      (_) => (
        x: r.nextDouble(),
        y: r.nextDouble(),
        s: 0.8 + r.nextDouble() * 1.6,
        p: r.nextDouble(),
      ),
    );
  }();

  Color get _accent {
    final i = page.floor().clamp(0, _accents.length - 1);
    final j = (i + 1).clamp(0, _accents.length - 1);
    return Color.lerp(_accents[i], _accents[j], page - page.floor())!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final full = Offset.zero & size;
    final accent = _accent;
    final wave = t * 2 * math.pi;

    // Sky.
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1424), Palette.violetDeep, Color(0xFF223F63)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(full),
    );

    void glow(Offset c, double radius, Color color, double alpha) {
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }

    // Drifting aurora.
    glow(
      Offset(w * (0.12 + 0.06 * math.sin(wave)), horizon * 0.22),
      w * 0.7,
      Palette.tealBright,
      0.20,
    );
    glow(
      Offset(w * (0.92 - 0.06 * math.cos(wave)), horizon * 0.12),
      w * 0.55,
      accent,
      0.14,
    );

    // Stars.
    final star = Paint();
    for (final s in _stars) {
      final twinkle = 0.5 + 0.5 * math.sin(2 * math.pi * (t * 3 + s.p));
      star.color = Colors.white.withValues(alpha: 0.15 + 0.55 * twinkle);
      canvas.drawCircle(Offset(s.x * w, s.y * horizon * 0.6), s.s, star);
    }

    // Sunrise behind the hills, in the slide's colour.
    glow(Offset(w * 0.5, horizon - 30), w * 0.95, accent, 0.45);

    // Rolling hills; the back row drifts slower than the front.
    Path hills(double base, double amp, double shift, double freq) {
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= w + 1; x += 6) {
        final y =
            base +
            amp * math.sin((x / w) * math.pi * freq + shift) +
            amp * 0.4 * math.sin((x / w) * math.pi * freq * 2.3 + shift * 1.7);
        path.lineTo(x, y);
      }
      return path
        ..lineTo(w, size.height)
        ..close();
    }

    final back = hills(horizon - 78, 22, page * 0.5 + 0.6, 2.2);
    canvas.drawPath(back, Paint()..color = const Color(0xFF1A3150));
    canvas.drawPath(
      back,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.35),
    );
    final front = hills(horizon - 34, 16, page * 0.9 + 2.4, 1.6);
    canvas.drawPath(front, Paint()..color = const Color(0xFF13223A));
    canvas.drawPath(
      front,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(VistaSkyPainter old) =>
      old.t != t || old.page != page || old.horizon != horizon;
}
