import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';

/// Vista running on the spot while something loads: a bouncing stride with
/// a shadow that shrinks as the pup leaves the ground. With reduce motion on
/// the pup stands still and the label does the work.
class VistaLoader extends StatefulWidget {
  final double size;
  final String? label;
  final bool? isDarkMode;

  const VistaLoader({super.key, this.size = 96, this.label, this.isDarkMode});

  static const asset = 'assets/vista-icons/vista-preloader.png';

  @override
  State<VistaLoader> createState() => _VistaLoaderState();
}

class _VistaLoaderState extends State<VistaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _run.stop();
    } else if (!_run.isAnimating) {
      _run.repeat();
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        widget.isDarkMode ?? Theme.of(context).brightness == Brightness.dark;
    final size = widget.size;
    return Semantics(
      label: widget.label ?? 'Loading',
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size * 1.2,
            height: size * 1.12,
            child: AnimatedBuilder(
              animation: _run,
              builder: (context, child) {
                // Two bounces per cycle feel like a trot.
                final phase = _run.value * 2 * math.pi;
                final lift = math.sin(phase).abs();
                final tilt = math.sin(phase) * 0.05;
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: size * (0.72 - 0.2 * lift),
                      height: size * 0.09,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size),
                        color: (dark ? Colors.black : Palette.violet)
                            .withValues(
                              alpha: (dark ? 0.4 : 0.14) * (1 - 0.5 * lift),
                            ),
                      ),
                    ),
                    Positioned(
                      bottom: size * 0.04 + lift * size * 0.1,
                      child: Transform.rotate(angle: tilt, child: child),
                    ),
                  ],
                );
              },
              child: Image.asset(
                VistaLoader.asset,
                width: size,
                height: size,
                cacheWidth: (size * 3).round(),
                excludeFromSemantics: true,
              ),
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.label!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Palette.muted(dark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
