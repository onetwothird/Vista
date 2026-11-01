import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/shared/widgets/auth_mascot_header.dart';
import 'package:seelai_app/shared/widgets/mascot_moment_screen.dart';
import 'package:seelai_app/shared/widgets/vista_toast.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/mswd/auth/signup/mswd_signup_screen.dart';
import 'package:seelai_app/roles/mswd/home/mswd_home_screen.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MSWDLoginScreen extends StatefulWidget {
  const MSWDLoginScreen({super.key});

  @override
  State<MSWDLoginScreen> createState() => _MSWDLoginScreenState();
}

class _MSWDLoginScreenState extends State<MSWDLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  final _mascot = GlobalKey<VistaMascotState>();
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutQuart),
        );

    _entryController.value = 1.0;
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Palette.text(dark);
    final mutedColor = Palette.muted(dark);
    final brand = Palette.brand(dark);

    return Scaffold(
      backgroundColor: Palette.page(dark),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthMascotHeader(
                  mascotKey: _mascot,
                  pose: MascotPose.signIn,
                  lines: const [
                    'Hi! Got your key?',
                    "I'll keep your account safe.",
                    'Woof! Sign in and we can go.',
                  ],
                ),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 32,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to monitor requests, alerts and registered users '
                              'in your municipality.',
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.45,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'you@example.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              autofill: const [AutofillHints.email],
                              action: TextInputAction.next,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Your password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              autofill: const [AutofillHints.password],
                              action: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_isLoading) _handleLogin();
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  foregroundColor: brand,
                                  minimumSize: const Size(48, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Palette.border(dark)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: mutedColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Palette.border(dark)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Palette.border(dark),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Palette.card(dark),
                                  foregroundColor: textColor,
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/icons/google.webp',
                                      height: 24,
                                      width: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'New to Vista?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: mutedColor,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MSWDSignupScreen(),
                                            ),
                                          ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: brand,
                                      minimumSize: const Size(48, 48),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                    child: const Text(
                                      'Create an account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) LoadingOverlay(message: '', isVisible: _isLoading),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Iterable<String>? autofill,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Palette.text(dark),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          autofillHints: autofill,
          textInputAction: action,
          onSubmitted: onSubmitted,
          autocorrect: false,
          enableSuggestions: !isPassword,
          style: TextStyle(fontSize: 18, color: Palette.text(dark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: dark ? Palette.nightMuted : Palette.inkSubtle,
            ),
            filled: true,
            fillColor: Palette.card(dark),
            prefixIcon: Icon(icon, color: Palette.muted(dark)),
            suffixIcon: isPassword
                ? IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Palette.muted(dark),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            enabledBorder: border(Palette.border(dark), 1.5),
            focusedBorder: border(Palette.brand(dark), 2.5),
            border: border(Palette.border(dark), 1.5),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    // 1. Capture the parent context for the SnackBar
    final parentContext = context;
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: parentContext,
      // 2. Rename to dialogContext to avoid shadowing the outer context
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                Navigator.pop(dialogContext);
                return;
              }

              try {
                await authService.value.sendPasswordResetEmail(
                  email: emailController.text.trim(),
                );

                // 3. GUARD: Check if the dialog is still open before popping
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                // 4. GUARD: Check if the main screen is still active before showing the SnackBar
                if (!parentContext.mounted) return;
                VistaToast.success(parentContext, 'Password reset email sent!');
              } catch (e) {
                // 5. GUARD: Check if the dialog is still open before popping on error
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // ==================== GOOGLE LOGIN LOGIC ====================
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential = await authService.value
          .signInWithGoogle();

      if (userCredential == null) {
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic>? userData = await databaseService.getUserData(
        userCredential.user!.uid,
      );

      if (userData != null) {
        if (userData['role'] == 'admin' || userData['role'] == 'mswd') {
          await activityLogsService.logActivity(
            userId: userCredential.user!.uid,
            action: 'login',
            details: 'MSWD logged in via Google',
          );
          if (mounted) {
            MascotMomentScreen.showSignedIn(
              context,
              name: userData['name']?.toString(),
              userData: userData,
              next: (context) => MSWDHomeScreen(userData: userData),
            );
          }
        } else {
          await authService.value.signOut();
          if (mounted) {
            VistaToast.error(context, 'Access Denied: Not an MSWD account');
          }
        }
      } else {
        // User not in DB, route to Signup
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MSWDSignupScreen(googleUser: userCredential.user),
            ),
          );

          VistaToast.info(
            context,
            'Almost there! Please complete your staff profile.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        VistaToast.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== STANDARD LOGIN LOGIC ====================
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      VistaToast.error(context, 'Please fill all fields');
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await authService.value.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      Map<String, dynamic>? userData = await databaseService.getUserData(
        userCredential.user!.uid,
      );

      if (userData != null &&
          (userData['role'] == 'admin' || userData['role'] == 'mswd')) {
        await activityLogsService.logActivity(
          userId: userCredential.user!.uid,
          action: 'login',
          details: 'MSWD logged in',
        );
        if (mounted) {
          MascotMomentScreen.showSignedIn(
            context,
            name: userData['name']?.toString(),
            userData: userData,
            next: (context) => MSWDHomeScreen(userData: userData),
          );
        }
      } else {
        await authService.value.signOut();
        if (mounted) {
          VistaToast.error(context, 'Access Denied: Not an MSWD account');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        VistaToast.error(context, e.message ?? 'Login failed');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
