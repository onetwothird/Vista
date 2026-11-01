import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:seelai_app/shared/nickname.dart';
import 'package:seelai_app/themes/palette.dart';

enum MascotMood { celebrating, sad }

/// Full-screen moment with the Vista pup, shown right after signing in
/// (celebrating) or signing out (sad). It moves on by itself after a few
/// seconds; tapping the pup plays with it and restarts that timer.
class MascotMomentScreen extends StatefulWidget {
  const MascotMomentScreen({
    super.key,
    required this.mood,
    required this.next,
    this.name,
    this.userData,
    this.clearStack = false,
  });

  final MascotMood mood;
  final WidgetBuilder next;
  final String? name;

  /// The signed-in user's record. When it has no nickname yet, the pup asks
  /// for one before moving on, and saves it into this same map.
  final Map<String, dynamic>? userData;
  final bool clearStack;

  /// Replaces the login screen with the celebration, then [next].
  static void showSignedIn(
    BuildContext context, {
    String? name,
    Map<String, dynamic>? userData,
    required WidgetBuilder next,
  }) {
    Navigator.of(context).pushReplacement(
      _fadeRoute(
        MascotMomentScreen(
          mood: MascotMood.celebrating,
          name: name,
          userData: userData,
          next: next,
        ),
      ),
    );
  }

  /// Clears the app stack, shows the goodbye, then the onboarding screen.
  static void showSignedOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      _fadeRoute(
        MascotMomentScreen(
          mood: MascotMood.sad,
          next: (_) => const OnboardingScreen(),
          clearStack: true,
        ),
      ),
      (route) => false,
    );
  }

  static Route<void> _fadeRoute(Widget page) => PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );

  @override
  State<MascotMomentScreen> createState() => _MascotMomentScreenState();
}

class _MascotMomentScreenState extends State<MascotMomentScreen>
    with TickerProviderStateMixin {
  static const _celebrateAsset = 'assets/vista-icons/vista-celebrating.png';
  static const _sadAsset = 'assets/vista-icons/vista-sad.png';

  static const _celebrateLines = [
    'Woof! Great to see you.',
    "Let's get going!",
    'Again! Again!',
    'Best day ever.',
  ];
  static const _sadLines = [
    'See you soon?',
    "I'll keep watch.",
    'Okay... one more pat.',
  ];

  /// Taps needed to cheer the sad pup up.
  static const _cheerUpTaps = 3;

  late final AnimationController _entry;
  late final AnimationController _idle;
  late final AnimationController _jump;
  late final AnimationController _confetti;
  late final AnimationController _countdown;

  final _random = math.Random();
  List<_Particle> _particles = const [];
  int _taps = 0;
  String? _bubble;
  bool _left = false;
  bool _reduceMotion = false;

  bool get _celebrating => widget.mood == MascotMood.celebrating;

  /// True while the pup is asking for a nickname; the screen waits.
  late bool _askingNickname =
      _celebrating &&
      widget.userData != null &&
      Nickname.of(widget.userData) == null;
  bool get _cheeredUp => !_celebrating && _taps >= _cheerUpTaps;
  bool get _happy => _celebrating || _cheeredUp;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _celebrating ? 1100 : 900),
    );
    _idle = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _celebrating ? 1100 : 3200),
    );
    _jump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _countdown =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: _celebrating ? 4200 : 5200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _continue();
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    final firstRun = !_entry.isAnimating && _entry.value == 0;
    _reduceMotion = reduce;
    precacheImage(const AssetImage(_celebrateAsset), context);
    precacheImage(const AssetImage(_sadAsset), context);

    if (firstRun) {
      if (reduce) {
        _entry.value = 1;
      } else {
        _entry.forward();
        _idle.repeat();
        if (_celebrating) {
          Future.delayed(const Duration(milliseconds: 380), () {
            if (mounted) _burst(70);
          });
        }
      }
      if (!_askingNickname) _countdown.forward();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _idle.dispose();
    _jump.dispose();
    _confetti.dispose();
    _countdown.dispose();
    super.dispose();
  }

  void _burst(int count) {
    if (_reduceMotion) return;
    const colors = [
      Palette.violet,
      Palette.lilac,
      Palette.signal,
      Color(0xFF3EC9C1), // goggle teal
      Color(0xFFE8505B), // party-hat red
    ];
    _particles = List.generate(count, (_) {
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * 2.3;
      final speed = 420 + _random.nextDouble() * 520;
      return _Particle(
        velocity: Offset(math.cos(angle), math.sin(angle)) * speed,
        color: colors[_random.nextInt(colors.length)],
        size: 6 + _random.nextDouble() * 6,
        spin: (_random.nextDouble() - 0.5) * 14,
        round: _random.nextDouble() < 0.3,
      );
    });
    _confetti.forward(from: 0);
  }

  void _onMascotTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _taps++;
      if (_celebrating) {
        _bubble = _celebrateLines[(_taps - 1) % _celebrateLines.length];
      } else if (_taps == _cheerUpTaps) {
        _bubble = 'Thanks! See you soon!';
      } else if (_taps < _cheerUpTaps) {
        _bubble = _sadLines[(_taps - 1) % _sadLines.length];
      } else {
        _bubble = 'Bye for now!';
      }
    });
    if (!_reduceMotion) _jump.forward(from: 0);
    if (_celebrating || _taps == _cheerUpTaps) _burst(_celebrating ? 40 : 60);
    if (_taps == _cheerUpTaps) {
      HapticFeedback.mediumImpact();
      if (!_reduceMotion) {
        _idle
          ..duration = const Duration(milliseconds: 1100)
          ..repeat();
      }
    }
    // Give the person time to play before moving on.
    if (!_askingNickname) _countdown.forward(from: 0);
  }

  Future<void> _saveNickname(String value) async {
    final data = widget.userData;
    if (data == null) return;
    setState(() {
      data['nickname'] = value.trim();
      _askingNickname = false;
      _bubble = 'Nice to meet you, ${value.trim()}!';
    });
    if (!_reduceMotion) _jump.forward(from: 0);
    _burst(50);
    _countdown.forward(from: 0);
    try {
      await Nickname.save(data, value);
    } catch (_) {
      // Still used for this session; it can be set again from home.
    }
  }

  void _skipNickname() {
    setState(() => _askingNickname = false);
    _countdown.forward(from: 0);
  }

  void _continue() {
    if (_left || !mounted) return;
    _left = true;
    final route = MaterialPageRoute<void>(builder: widget.next);
    if (widget.clearStack) {
      Navigator.of(context).pushAndRemoveUntil(route, (r) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  String get _title {
    if (_celebrating) {
      final nick = Nickname.of(widget.userData);
      final first =
          nick ?? (widget.name ?? '').trim().split(RegExp(r'\s+')).first;
      return first.isEmpty ? "You're signed in!" : 'Welcome back, $first!';
    }
    return "You're signed out";
  }

  String get _message => _celebrating
      ? 'Your home screen is almost ready. Tap Vista while you wait.'
      : _cheeredUp
      ? 'Vista will be right here when you come back.'
      : 'Vista will miss you. Tap the pup to cheer it up.';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mascotSize = math.min(size.width * 0.72, 320.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    SizedBox(height: 72, child: _buildBubble()),
                    const SizedBox(height: 8),
                    _buildMascot(mascotSize),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _askingNickname
                          ? NicknameForm(
                              key: const ValueKey('nickname'),
                              initial: Nickname.suggestion(widget.userData),
                              submitLabel: 'Save and continue',
                              onSubmit: _saveNickname,
                              onSkip: _skipNickname,
                            )
                          : Column(
                              key: const ValueKey('done'),
                              children: [
                                Semantics(
                                  header: true,
                                  liveRegion: true,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: Text(
                                      _title,
                                      key: ValueKey(_title),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                        color: Palette.ink,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    _message,
                                    key: ValueKey(_message),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.45,
                                      color: Palette.inkMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _buildContinueButton(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      seconds:
                          _confetti.value *
                          _confetti.duration!.inMilliseconds /
                          1000,
                      progress: _confetti.value,
                      origin: Offset(size.width / 2, size.height * 0.36),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        alignment: Alignment.bottomCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _bubble == null
          ? const SizedBox.shrink()
          : Align(
              key: ValueKey('$_taps$_bubble'),
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                painter: _BubblePainter(
                  color: _happy ? Palette.violet : Palette.inkSoft,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                  child: Text(
                    _bubble!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMascot(double mascotSize) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cache = (mascotSize * dpr).round();

    return Semantics(
      button: true,
      label: _happy
          ? 'Vista the pup is celebrating. Tap to play.'
          : 'Vista the pup looks sad. Tap to cheer it up.',
      child: GestureDetector(
        onTap: _onMascotTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entry, _idle, _jump]),
          builder: (context, _) {
            final e = _entry.value;
            final t = _idle.value;
            final j = _jump.value;

            double dy;
            double scale;
            double angle;
            double opacity;

            if (_celebrating) {
              final enter = Curves.elasticOut.transform(e);
              scale = 0.4 + 0.6 * enter;
              dy = (1 - Curves.easeOutCubic.transform(e)) * 120;
              opacity = (e * 3).clamp(0.0, 1.0);
            } else {
              final enter = Curves.easeOutCubic.transform(e);
              scale = 0.94 + 0.06 * enter;
              dy = (1 - enter) * -40;
              opacity = enter;
            }

            if (_happy) {
              // Bouncy idle hop with a squash at the bottom.
              final hop = math.sin(t * math.pi).abs();
              dy -= hop * 16;
              scale *= 1 + (1 - hop) * 0.02;
              angle = math.sin(t * 2 * math.pi) * 0.03;
            } else {
              // Slow, heavy sway and breath.
              angle = math.sin(t * 2 * math.pi) * 0.035;
              scale *= 1 + math.sin(t * 2 * math.pi) * 0.012;
            }

            // Tap jump.
            final jumpLift = math.sin(j * math.pi);
            dy -= jumpLift * (_happy ? 70 : 28);
            angle += math.sin(j * 2 * math.pi) * (_happy ? 0.12 : 0.06);

            final lift = (-dy).clamp(0.0, 90.0) / 90;

            return Opacity(
              opacity: opacity,
              child: SizedBox(
                width: mascotSize,
                height: mascotSize + 24,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Ground shadow shrinks as the pup leaves the floor.
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: mascotSize * (0.5 - lift * 0.18),
                        height: 18 * (1 - lift * 0.35),
                        decoration: BoxDecoration(
                          color: Palette.ink.withValues(
                            alpha: 0.10 * (1 - lift * 0.6),
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.rotate(
                          angle: angle,
                          alignment: Alignment.bottomCenter,
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.bottomCenter,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Image.asset(
                                _happy ? _celebrateAsset : _sadAsset,
                                key: ValueKey(_happy),
                                width: mascotSize,
                                height: mascotSize,
                                cacheWidth: cache,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final label = _celebrating ? 'Go to home' : 'Back to start';
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Material(
          color: Palette.violet,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _continue,
            child: Stack(
              children: [
                // Fills up until the screen moves on by itself.
                AnimatedBuilder(
                  animation: _countdown,
                  builder: (context, _) => FractionallySizedBox(
                    widthFactor: _countdown.value,
                    heightFactor: 1,
                    child: const ColoredBox(color: Palette.violetDeep),
                  ),
                ),
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.round,
  });

  final Offset velocity;
  final Color color;
  final double size;
  final double spin;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.seconds,
    required this.progress,
    required this.origin,
  });

  final List<_Particle> particles;
  final double seconds;
  final double progress;
  final Offset origin;

  static const _gravity = 980.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || progress <= 0 || progress >= 1) return;
    final fade = progress < 0.7 ? 1.0 : (1 - progress) / 0.3;
    final paint = Paint();
    // Air drag so pieces flutter down instead of falling like stones.
    final drag = (1 - math.exp(-1.6 * seconds)) / 1.6;

    for (final p in particles) {
      final pos =
          origin +
          p.velocity * drag +
          Offset(0, 0.5 * _gravity * seconds * seconds * 0.55);
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * seconds);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        // Flip on one axis to fake a tumbling paper strip.
        final flip = math.cos(p.spin * seconds * 1.7);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55 * flip.abs().clamp(0.2, 1.0),
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.seconds != seconds || old.particles != particles;
}

/// Rounded speech bubble with a tail pointing down at the pup.
class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0;
    final body = Rect.fromLTWH(0, 0, size.width, size.height - tail);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(20)))
      ..moveTo(size.width / 2 - 11, body.bottom - 1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 11, body.bottom - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
