import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_sky.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    // 1. Wait for your splash animation to play out
    await Future.delayed(const Duration(milliseconds: 2500));

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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: Palette.violetDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: VistaSkyPainter(t: 0.2, page: 0, horizon: height),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Palette.honey, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.tealBright.withValues(alpha: 0.35),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Image.asset(
                        'assets/vista_app_logo/vista_app_logo.jpg',
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Vista',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your guide pup for everyday sight',
                    style: TextStyle(color: Palette.nightMuted, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
