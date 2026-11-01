import 'package:flutter/material.dart';
import 'package:seelai_app/roles/partially_sighted/auth/login/user_login_screen.dart';
import 'package:seelai_app/roles/partially_sighted/auth/signup/user_signup_screen.dart';
import 'package:seelai_app/roles/caretaker/auth/login/caretaker_login_screen.dart';
import 'package:seelai_app/roles/caretaker/auth/signup/caretaker_signup_screen.dart';
import 'package:seelai_app/roles/mswd/auth/login/mswd_login_screen.dart';
import 'package:seelai_app/roles/mswd/auth/signup/mswd_signup_screen.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:seelai_app/shared/widgets/auth_mascot_header.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/themes/palette.dart';

typedef _Role = ({
  String id,
  String title,
  String subtitle,
  IconData icon,
  String line,
});

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _mascot = GlobalKey<VistaMascotState>();
  String? _selectedRole;

  static const List<_Role> _roles = [
    (
      id: 'partially_sighted',
      title: 'I have low vision',
      subtitle: 'Vista reads, spots and guides for me.',
      icon: Icons.visibility_rounded,
      line: 'I will be your eyes!',
    ),
    (
      id: 'caretaker',
      title: 'I care for someone',
      subtitle: 'Stay close with calls, alerts and live location.',
      icon: Icons.favorite_rounded,
      line: "Let's look after them.",
    ),
    (
      id: 'admin',
      title: 'I work at MSWD',
      subtitle: 'Manage cases, requests and announcements.',
      icon: Icons.badge_rounded,
      line: 'Welcome to the team!',
    ),
  ];

  void _select(_Role r) {
    setState(() => _selectedRole = r.id);
    _mascot.currentState?.hop(r.line);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Palette.paper,
      body: Column(
        children: [
          AuthMascotHeader(
            mascotKey: _mascot,
            pose: MascotPose.welcome,
            height: 250,
            lines: const ['Who am I helping?', 'Pick one below!'],
            onBack: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              children: [
                const Text(
                  'Who is using Vista?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.6,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vista sets itself up around you.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Palette.inkMuted,
                  ),
                ),
                const SizedBox(height: 22),
                for (final r in _roles) ...[
                  _buildRoleCard(r),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 4, 24, 16 + bottomInset),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _selectedRole == null
                    ? null
                    : () => _showAuthBottomSheet(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.violet,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Palette.paperSunk,
                  disabledForegroundColor: Palette.inkSubtle,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(_Role r) {
    final selected = _selectedRole == r.id;
    return Semantics(
      button: true,
      selected: selected,
      label: '${r.title}. ${r.subtitle}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _select(r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? Palette.violetTint : Palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Palette.violet : Palette.line,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? Palette.violet : Palette.mist,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  r.icon,
                  color: selected ? Colors.white : Palette.violet,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.subtitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.35,
                        color: Palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Palette.violet,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuthBottomSheet(BuildContext context) {
    final role = _roles.firstWhere((r) => r.id == _selectedRole);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) => Container(
        decoration: const BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.paddingOf(sheet).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Palette.lineStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            const VistaMascot(pose: MascotPose.signIn, size: 120),
            const SizedBox(height: 8),
            const Text(
              "Let's get you in",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${role.title}. Sign in, or create a new account.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15.5, color: Palette.inkMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  _navigateToLogin(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.violet,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Sign in',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  _navigateToSignup(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Palette.lineStrong, width: 1.5),
                  foregroundColor: Palette.violet,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create an account',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    final Widget? target = switch (_selectedRole) {
      'partially_sighted' => const LoginScreenPartiallySighted(),
      'caretaker' => const CaretakerLoginScreen(),
      'admin' => const MSWDLoginScreen(),
      _ => null,
    };
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    }
  }

  void _navigateToSignup(BuildContext context) {
    final Widget? target = switch (_selectedRole) {
      'partially_sighted' => const PartiallySightedSignupScreen(),
      'caretaker' => const CaretakerSignupScreen(),
      'admin' => const MSWDSignupScreen(),
      _ => null,
    };
    if (target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    }
  }
}
