import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/themes/palette.dart';

/// The Vista pup poses that ship in `assets/vista-icons/`.
abstract final class MascotPose {
  static const welcome = 'assets/vista-icons/vista-welcome.png';
  static const signIn = 'assets/vista-icons/vista-signin.png';
  static const signUp = 'assets/vista-icons/vista-signup.png';
  static const celebrating = 'assets/vista-icons/vista-celebrating.png';
  static const sad = 'assets/vista-icons/vista-sad.png';
  static const running = 'assets/vista-icons/vista-preloader.png';
  static const pointListenGo = 'assets/vista-icons/point-listen-go-vista.png';
  static const neverOnYourOwn = 'assets/vista-icons/never-your-own-vista.png';
}

/// An animated, tappable Vista pup.
///
/// It bobs while idle, hops and talks when tapped, and can be told to react
/// from outside through a `GlobalKey<VistaMascotState>`:
/// `key.currentState?.sad('That password did not work')`.
class VistaMascot extends StatefulWidget {
  const VistaMascot({
    super.key,
    required this.pose,
    this.size = 200,
    this.lines = const [],
    this.bubbleColor = Palette.violet,
    this.bubbleTextColor = Colors.white,
    this.semanticLabel = 'Vista the pup. Tap to say hi.',
    this.greeting,
    this.bubbleShift = 0,
  });

  final String pose;
  final double size;

  /// What the pup says on each tap, in order, looping.
  final List<String> lines;
  final Color bubbleColor;
  final Color bubbleTextColor;
  final String semanticLabel;

  /// Said once, a moment after the pup appears.
  final String? greeting;

  /// Moves the speech bubble sideways (negative is left), for a pup that
  /// sits near the edge of the screen.
  final double bubbleShift;

  @override
  State<VistaMascot> createState() => VistaMascotState();
}

class VistaMascotState extends State<VistaMascot>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  String? _poseOverride;
  String? _bubble;
  int _taps = 0;
  Timer? _resetTimer;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    for (final pose in [widget.pose, MascotPose.sad, MascotPose.celebrating]) {
      precacheImage(AssetImage(pose), context);
    }
    if (_reduceMotion) {
      _idle.stop();
      _enter.value = 1;
    } else {
      if (!_idle.isAnimating) _idle.repeat();
      if (_enter.value == 0 && !_enter.isAnimating) _enter.forward();
    }
    final greeting = widget.greeting;
    if (greeting != null && !_greeted) {
      _greeted = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) hop(greeting);
      });
    }
  }

  bool _greeted = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _idle.dispose();
    _hop.dispose();
    _shake.dispose();
    _enter.dispose();
    super.dispose();
  }

  /// Hop, optionally saying [line].
  void hop([String? line]) {
    if (!_reduceMotion) _hop.forward(from: 0);
    if (line != null) _say(line);
  }

  /// Show a speech bubble without moving.
  void say(String line) => _say(line);

  /// Switch to the sad pose, shake, and say [line].
  void sad(String line) {
    HapticFeedback.mediumImpact();
    if (!_reduceMotion) _shake.forward(from: 0);
    _react(MascotPose.sad, line);
  }

  /// Switch to the celebrating pose, hop, and say [line].
  void celebrate(String line) {
    HapticFeedback.lightImpact();
    if (!_reduceMotion) _hop.forward(from: 0);
    _react(MascotPose.celebrating, line);
  }

  void _react(String pose, String line) {
    setState(() => _poseOverride = pose);
    _say(line);
  }

  void _say(String line) {
    setState(() => _bubble = line);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _bubble = null;
          _poseOverride = null;
        });
      }
    });
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    final line = widget.lines.isEmpty
        ? null
        : widget.lines[_taps % widget.lines.length];
    _taps++;
    setState(() => _poseOverride = null);
    hop(line);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final pose = _poseOverride ?? widget.pose;
    final isSad = pose == MascotPose.sad;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_idle, _hop, _shake, _enter]),
                builder: (context, child) {
                  final t = _idle.value;
                  final h = math.sin(_hop.value * math.pi);
                  final enter = Curves.easeOutBack.transform(_enter.value);
                  final bob = math.sin(t * 2 * math.pi);
                  final shake =
                      math.sin(_shake.value * math.pi * 6) *
                      (1 - _shake.value) *
                      12;

                  return Opacity(
                    opacity: _enter.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(
                        shake,
                        (isSad ? 4 : bob * 5) - h * size * 0.14,
                      ),
                      child: Transform.rotate(
                        angle:
                            (isSad ? 0 : bob * 0.025) +
                            math.sin(_hop.value * 2 * math.pi) * 0.09,
                        alignment: Alignment.bottomCenter,
                        child: Transform.scale(
                          scale: (0.6 + 0.4 * enter) * (1 + h * 0.04),
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Image.asset(
                    pose,
                    key: ValueKey(pose),
                    width: size,
                    height: size,
                    cacheWidth: (size * dpr).round(),
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Positioned(
                top: -size * 0.16,
                left: -40 + widget.bubbleShift,
                right: -40 - widget.bubbleShift,
                child: IgnorePointer(
                  child: Semantics(
                    liveRegion: true,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      reverseDuration: const Duration(milliseconds: 90),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: _bubble == null
                          ? const SizedBox.shrink()
                          : Center(
                              key: ValueKey('$_taps$_bubble$pose'),
                              child: SpeechBubble(
                                text: _bubble!,
                                color: isSad
                                    ? Palette.inkSoft
                                    : widget.bubbleColor,
                                textColor: isSad
                                    ? Colors.white
                                    : widget.bubbleTextColor,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded speech bubble with a tail pointing down.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    required this.color,
    this.textColor = Colors.white,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(color),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0;
    final body = Rect.fromLTWH(0, 0, size.width, size.height - tail);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(18)))
      ..moveTo(size.width / 2 - 10, body.bottom - 1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 10, body.bottom - 1)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
