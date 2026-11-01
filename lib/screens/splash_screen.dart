import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seelai_app/themes/palette.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:seelai_app/firebase/database_service.dart';

// Import your screens (ensure these paths match your project structure)
import 'package:seelai_app/roles/partially_sighted/home/home_screen.dart';
import 'package:seelai_app/roles/partially_sighted/caretaker/caretaker_selection_screen.dart';
import 'package:seelai_app/roles/caretaker/home/caretaker_home_screen.dart';
import 'package:seelai_app/roles/mswd/home/mswd_home_screen.dart';

class AnimatedSplashScreenWidget extends StatefulWidget {
  const AnimatedSplashScreenWidget({super.key});

  @override
  State<AnimatedSplashScreenWidget> createState() =>
      _AnimatedSplashScreenWidgetState();
}

class _AnimatedSplashScreenWidgetState extends State<AnimatedSplashScreenWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const _introLength = Duration(milliseconds: 2400);
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introLength,
  );
  final List<Timer> _barkTimers = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _intro.value = 1;
        return;
      }
      _intro.forward();
      // A little thump on each bark.
      for (final at in [_Splash.bark1, _Splash.bark2]) {
        _barkTimers.add(
          Timer(_introLength * at, () => HapticFeedback.mediumImpact()),
        );
      }
    });

    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    // 1. Wait for the splash animation to play out
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;

    // 2. Check Firebase for an existing session
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // 3. Fetch the user's data from your database
        Map<String, dynamic>? userData = await databaseService.getUserData(
          currentUser.uid,
        );

        if (userData != null) {
          userData['uid'] = currentUser.uid;
          String userRole = userData['role'] ?? '';

          // 4. Route based on their role
          Widget destinationScreen;

          if (userRole == 'partially_sighted') {
            bool hasCaretaker = false;
            if (userData['assignedCaretakers'] != null) {
              Map<dynamic, dynamic> assignedCaretakers =
                  userData['assignedCaretakers'] as Map;
              hasCaretaker = assignedCaretakers.isNotEmpty;
            }
            // Send to Home if they have a caretaker, otherwise send to selection screen
            destinationScreen = hasCaretaker
                ? PartiallySightedHomeScreen(userData: userData)
                : CaretakerSelectionScreen(userData: userData);
          } else if (userRole == 'caretaker') {
            destinationScreen = CaretakerHomeScreen(userData: userData);
          } else if (userRole == 'admin' || userRole == 'mswd') {
            destinationScreen = MSWDHomeScreen(userData: userData);
          } else {
            // Fallback if role is unknown
            destinationScreen = const OnboardingScreen();
          }

          _navigateWithFade(destinationScreen);
          return; // Exit function so we don't hit the onboarding fallback
        }
      } catch (e) {
        debugPrint("Auto-login failed: $e");
      }
    }

    // 5. If no user is logged in, or if fetching data failed, go to Onboarding
    _navigateWithFade(const OnboardingScreen());
  }

  void _navigateWithFade(Widget destination) {
    _fadeController.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final t in _barkTimers) {
      t.cancel();
    }
    _intro.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.violetDeep,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Semantics(
            label: 'Vista. Your guide pup for everyday sight.',
            excludeSemantics: true,
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) => _Splash(t: _intro.value),
            ),
          ),
        ),
      ),
    );
  }
}

/// The splash scene at time [t] (0 to 1): the pup dashes in, lands, and
/// barks twice ("Aw!" then "Aw aw!") with sound waves, then the name appears.
class _Splash extends StatelessWidget {
  const _Splash({required this.t});

  final double t;

  static const bark1 = 0.36;
  static const bark2 = 0.56;
  static const _logo = 200.0;

  /// 0 to 1 progress of [t] between [a] and [b].
  double _seg(double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  /// A quick 0 -> 1 -> 0 pulse starting at [at].
  double _pulse(double at, [double len = 0.1]) =>
      math.sin(_seg(at, at + len) * math.pi);

  @override
  Widget build(BuildContext context) {
    // The logo pops in, then bounces with each bark.
    final enter = _seg(0.0, 0.22, Curves.easeOutBack);
    final bark = math.max(_pulse(bark1), _pulse(bark2) * 1.3);

    final title = _seg(0.62, 0.82, Curves.easeOutCubic);
    final tagline = _seg(0.72, 0.92, Curves.easeOutCubic);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 320,
          height: 230,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BarkWaves(
                    first: _seg(bark1, bark1 + 0.22),
                    second: _seg(bark2, bark2 + 0.26),
                  ),
                ),
              ),
              Opacity(
                opacity: _seg(0.0, 0.1),
                child: Transform.rotate(
                  angle: -0.05 * bark,
                  child: Transform.scale(
                    scale: (0.6 + 0.4 * enter) * (1 + 0.08 * bark),
                    child: Image.asset(
                      'assets/vista-icons/splash-screen-vista.png',
                      width: _logo,
                      height: _logo,
                      cacheWidth: 520,
                    ),
                  ),
                ),
              ),
              _BarkBubble(
                text: 'Aw!',
                show:
                    _seg(bark1, bark1 + 0.06, Curves.easeOutBack) *
                    (1 - _seg(bark2 - 0.05, bark2)),
                top: 0,
                right: 12,
              ),
              _BarkBubble(
                text: 'Aw aw!',
                show:
                    _seg(bark2, bark2 + 0.06, Curves.easeOutBack) *
                    (1 - _seg(0.9, 1.0)),
                top: -14,
                right: 0,
                big: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Opacity(
          opacity: title,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - title)),
            child: const Text(
              'Vista',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: tagline,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - tagline)),
            child: const Text(
              'Your guide pup for everyday sight',
              style: TextStyle(color: Palette.nightMuted, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// A bark in a little speech bubble that pops out near the pup's mouth.
class _BarkBubble extends StatelessWidget {
  const _BarkBubble({
    required this.text,
    required this.show,
    required this.top,
    required this.right,
    this.big = false,
  });

  final String text;
  final double show;
  final double top;
  final double right;
  final bool big;

  @override
  Widget build(BuildContext context) {
    if (show <= 0) return const SizedBox.shrink();
    return Positioned(
      top: top,
      right: right,
      child: Opacity(
        opacity: show.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.4 + 0.6 * show,
          alignment: Alignment.bottomLeft,
          child: Transform.rotate(
            angle: big ? 0.06 : -0.05,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: big ? 16 : 14,
                vertical: big ? 9 : 7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Palette.violetDeep,
                  fontSize: big ? 24 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sound-wave arcs coming out of the pup's mouth for each bark.
class _BarkWaves extends CustomPainter {
  _BarkWaves({required this.first, required this.second});

  final double first;
  final double second;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    _burst(canvas, c, first, 3);
    _burst(canvas, c, second, 4);
  }

  void _burst(Canvas canvas, Offset c, double p, int count) {
    if (p <= 0 || p >= 1) return;
    for (var i = 0; i < count; i++) {
      final local = (p * 1.4 - i * 0.14).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4 * (1 - local) + 1
        ..color = Palette.honey.withValues(alpha: (1 - local) * 0.9);
      final rect = Rect.fromCircle(center: c, radius: 106 + local * 54);
      canvas.drawArc(rect, -0.5, 1.0, false, paint);
      canvas.drawArc(rect, math.pi - 0.5, 1.0, false, paint);
    }
  }

  @override
  bool shouldRepaint(_BarkWaves old) =>
      old.first != first || old.second != second;
}
