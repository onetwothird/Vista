import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';

/// Full-screen loader: the Vista pup running across a scrolling track.
class LoadingOverlay extends StatefulWidget {
  final String message;
  final bool isVisible;

  const LoadingOverlay({
    super.key,
    required this.message,
    this.isVisible = true,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  static const _asset = 'assets/vista-icons/vista-preloader.png';

  late final AnimationController _fade = AnimationController(
    duration: const Duration(milliseconds: 250),
    vsync: this,
  );

  /// One gallop stride.
  late final AnimationController _stride = AnimationController(
    duration: const Duration(milliseconds: 420),
    vsync: this,
  );

  /// Ground and speed lines scrolling past.
  late final AnimationController _ground = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_asset), context);
  }

  void _start() {
    _fade.forward();
    final reduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (!reduce) {
      _stride.repeat();
      _ground.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _start();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _fade.reverse();
      _stride.stop();
      _ground.stop();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _stride.dispose();
    _ground.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    final pupSize = math.min(width * 0.62, 260.0);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final label = widget.message.isEmpty ? 'One moment...' : widget.message;

    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.white,
        child: Semantics(
          label: 'Loading. $label',
          liveRegion: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width,
                  height: pupSize + 40,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_stride, _ground]),
                    builder: (context, child) {
                      final s = _stride.value;
                      // Gallop: two bounces per stride, body rocks fore/aft.
                      final bounce = math.sin(s * 2 * math.pi).abs();
                      final rock = math.sin(s * 2 * math.pi) * 0.06;
                      final squash = 1 - (1 - bounce) * 0.04;

                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _TrackPainter(
                                phase: _ground.value,
                                pupSize: pupSize,
                                bounce: bounce,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 28 + bounce * 18,
                            child: Transform.rotate(
                              angle: rock,
                              alignment: Alignment.bottomCenter,
                              child: Transform.scale(
                                scaleX: 1 / squash,
                                scaleY: squash,
                                alignment: Alignment.bottomCenter,
                                child: child,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    child: Image.asset(
                      _asset,
                      width: pupSize,
                      height: pupSize,
                      cacheWidth: (pupSize * dpr).round(),
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 16),
                _Dots(controller: _ground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ground line with dashes scrolling left, a shadow that tightens as the
/// pup lands, speed streaks behind it and puffs of dust at its back feet.
class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.phase,
    required this.pupSize,
    required this.bounce,
  });

  final double phase;
  final double pupSize;
  final double bounce;

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height - 22;
    final cx = size.width / 2;

    // Shadow.
    final shadowW = pupSize * (0.62 - bounce * 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + 2),
        width: shadowW,
        height: 14 - bounce * 4,
      ),
      Paint()..color = Palette.ink.withValues(alpha: 0.10 - bounce * 0.04),
    );

    // Scrolling dashes along the ground.
    final dash = Paint()
      ..color = Palette.lineStrong
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const gap = 46.0;
    final offset = phase * gap * 2;
    for (double x = -gap * 2 + (gap * 2 - offset); x < size.width; x += gap) {
      // Fade towards the edges so the track feels endless.
      final edge = (1 - ((x - cx).abs() / (size.width / 2))).clamp(0.0, 1.0);
      dash.color = Palette.lineStrong.withValues(alpha: edge);
      canvas.drawLine(
        Offset(x, groundY + 12),
        Offset(x + 18, groundY + 12),
        dash,
      );
    }

    // Speed streaks behind the pup.
    final streak = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final tailX = cx - pupSize * 0.42;
    for (var i = 0; i < 3; i++) {
      final t = (phase * 2 + i / 3) % 1;
      final y = groundY - pupSize * (0.30 + i * 0.16);
      final len = 26 + i * 10.0;
      final x = tailX - t * 70;
      streak.color = Palette.violet.withValues(alpha: (1 - t) * 0.45);
      canvas.drawLine(Offset(x, y), Offset(x - len, y), streak);
    }

    // Dust kicked up by the back feet.
    final dust = Paint();
    for (var i = 0; i < 3; i++) {
      final t = (phase * 2 + i / 3) % 1;
      final x = cx - pupSize * 0.30 - t * 60;
      final y = groundY - 4 - t * 16;
      dust.color = Palette.lineStrong.withValues(alpha: (1 - t) * 0.8);
      canvas.drawCircle(Offset(x, y), 4 + t * 8, dust);
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.phase != phase || old.bounce != bounce;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (controller.value - i * 0.18) % 1;
          final lift = math.sin(t * math.pi).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 10,
            height: 10,
            transform: Matrix4.translationValues(0, -lift * 6, 0),
            decoration: BoxDecoration(
              color: Color.lerp(Palette.lilac, Palette.violet, lift),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

void showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useSafeArea: false,
    builder: (context) => LoadingOverlay(message: message),
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}
