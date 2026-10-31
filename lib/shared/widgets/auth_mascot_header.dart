import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/shared/widgets/vista_sky.dart';
import 'package:seelai_app/themes/palette.dart';

/// Midnight hero for sign-in and sign-up. The golden pup stands in a glowing
/// teal "lens" (the light from its goggles) while a honey spark orbits the
/// ring. The page's sheet curves up over the bottom edge.
/// Drive the pup through [mascotKey].
class AuthMascotHeader extends StatefulWidget {
  const AuthMascotHeader({
    super.key,
    required this.mascotKey,
    required this.pose,
    this.lines = const [],
    this.height = 300,
    this.onBack,
    this.sheetColor = Palette.paper,
  });

  final GlobalKey<VistaMascotState> mascotKey;
  final String pose;
  final List<String> lines;
  final double height;
  final VoidCallback? onBack;
  final Color sheetColor;

  @override
  State<AuthMascotHeader> createState() => _AuthMascotHeaderState();
}

class _AuthMascotHeaderState extends State<AuthMascotHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _orbit.stop();
    } else if (!_orbit.isAnimating) {
      _orbit.repeat();
    }
  }

  @override
  void dispose() {
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final mascotSize = widget.height - 96;
    final lens = mascotSize * 1.12;

    return SizedBox(
      height: topInset + widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Same dusk sky and hills as onboarding, so the flow feels
          // like one place.
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _orbit,
                builder: (context, _) => CustomPaint(
                  painter: VistaSkyPainter(
                    t: _orbit.value,
                    page: 0,
                    horizon: topInset + widget.height - 4,
                  ),
                ),
              ),
            ),
          ),
          // The lens: teal glow, two rings and an orbiting honey spark.
          Positioned(
            bottom: 34 - lens * 0.12,
            child: IgnorePointer(
              child: SizedBox(
                width: lens,
                height: lens,
                child: AnimatedBuilder(
                  animation: _orbit,
                  builder: (context, _) =>
                      CustomPaint(painter: LensPainter(_orbit.value)),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            child: VistaMascot(
              key: widget.mascotKey,
              pose: widget.pose,
              size: mascotSize,
              lines: widget.lines,
              bubbleColor: Palette.honey,
              bubbleTextColor: Palette.violetDeep,
            ),
          ),
          // Sheet edge.
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: widget.sheetColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
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
                  onPressed: widget.onBack ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                  iconSize: 28,
                  tooltip: 'Go back',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    minimumSize: const Size(52, 52),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Vista',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Teal lens glow with rings and a honey spark at [t] (0..1) around the ring.
class LensPainter extends CustomPainter {
  LensPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.tealBright.withValues(alpha: 0.38),
            Palette.tealBright.withValues(alpha: 0.10),
            Palette.tealBright.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    ring.color = Palette.tealBright.withValues(alpha: 0.55);
    canvas.drawCircle(c, r * 0.78, ring);
    ring.color = Palette.tealBright.withValues(alpha: 0.22);
    canvas.drawCircle(c, r * 0.98, ring);

    final a = t * 2 * math.pi - math.pi / 2;
    final spark = c + Offset(math.cos(a), math.sin(a)) * r * 0.78;
    canvas.drawCircle(
      spark,
      10,
      Paint()..color = Palette.honey.withValues(alpha: 0.25),
    );
    canvas.drawCircle(spark, 5, Paint()..color = Palette.honey);
  }

  @override
  bool shouldRepaint(LensPainter old) => old.t != t;
}
