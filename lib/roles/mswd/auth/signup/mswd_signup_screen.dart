// File: lib/roles/mswd/auth/signup/signup_screen.dart

import 'dart:io';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/shared/widgets/auth_mascot_header.dart';
import 'package:seelai_app/shared/widgets/vista_toast.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/storage/cloudinary_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MSWDSignupScreen extends StatefulWidget {
  final User? googleUser; // Captures Google Account

  const MSWDSignupScreen({super.key, this.googleUser});

  @override
  State<MSWDSignupScreen> createState() => _MSWDSignupScreenState();
}

class _MSWDSignupScreenState extends State<MSWDSignupScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final _mascot = GlobalKey<VistaMascotState>();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _departmentController =
      TextEditingController(); // Moved up logically
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    // --- PRE-FILL GOOGLE DATA (Name editable, Email locked) ---
    if (widget.googleUser != null) {
      _emailController.text = widget.googleUser!.email ?? '';
      _nameController.text = widget.googleUser!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _staffIdController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        VistaToast.error(context, 'Error: $e');
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: primary),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;
    return await cloudinaryService.uploadProfileImage(
      _profileImage!,
      userId,
      'admin',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.paper,
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthMascotHeader(
                    mascotKey: _mascot,
                    pose: MascotPose.signUp,
                    lines: const [
                      "Let's set you up!",
                      'Just a few details.',
                      'Your info stays private.',
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                widget.googleUser != null
                                    ? 'Finish your profile'
                                    : 'Create your account',
                                style: const TextStyle(
                                  fontSize: 32,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: Palette.ink,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Staff accounts let your office monitor requests and registered users.',
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.45,
                                color: Palette.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : _showImageSourceDialog,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Palette.paperSunk,
                                        border: Border.all(
                                          color: Palette.ink,
                                          width: 2.0,
                                        ),
                                        image: _profileImage != null
                                            ? DecorationImage(
                                                image: FileImage(
                                                  _profileImage!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : (widget.googleUser?.photoURL !=
                                                  null)
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  widget.googleUser!.photoURL!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child:
                                          _profileImage == null &&
                                              widget.googleUser?.photoURL ==
                                                  null
                                          ? const Icon(
                                              Icons.person_rounded,
                                              size: 60,
                                              color: Palette.line,
                                            )
                                          : null,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            _buildSectionHeader('About you'),
                            _buildTextField(
                              _nameController,
                              'Full Name',
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _staffIdController,
                              'Staff ID Number',
                              Icons.badge_outlined,
                            ),
                            const SizedBox(height: 16),

                            // MOVED DEPARTMENT HERE
                            _buildTextField(
                              _departmentController,
                              'Department',
                              Icons.business_outlined,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              _phoneController,
                              'Phone Number',
                              Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            // RESPONSIVE AGE & GENDER ROW
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    _ageController,
                                    'Age',
                                    Icons.cake_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: _buildGenderDropdown(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            _buildSectionHeader('Sign-in details'),
                            _buildTextField(
                              _emailController,
                              'Email',
                              Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              readOnly:
                                  widget.googleUser !=
                                  null, // Lock email if Google user
                            ),

                            // Only show password fields if NOT signing up with Google
                            if (widget.googleUser == null) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                _passwordController,
                                'Password',
                                Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _confirmPasswordController,
                                'Confirm Password',
                                Icons.lock_reset_outlined,
                                isPassword: true,
                                isConfirm: true,
                              ),
                            ],

                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Palette.honey,
                                  foregroundColor: Palette.violetDeep,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  widget.googleUser != null
                                      ? "Save & Continue"
                                      : "Create Staff Account",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) LoadingOverlay(message: '', isVisible: _isLoading),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Palette.ink,
      ),
    ),
  );

  InputDecoration _decoration(
    IconData icon, {
    Widget? suffix,
    bool readOnly = false,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      filled: true,
      fillColor: readOnly ? Palette.paperSunk : Colors.white,
      prefixIcon: Icon(icon, color: Palette.inkMuted),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: border(Palette.line, 1.5),
      focusedBorder: border(Palette.violet, 2.5),
      border: border(Palette.line, 1.5),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Gender'),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedGender,
          hint: const Text(
            'Choose',
            style: TextStyle(color: Palette.inkSubtle, fontSize: 17),
          ),
          borderRadius: BorderRadius.circular(18),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Palette.ink, fontSize: 17),
          decoration: _decoration(Icons.wc_outlined),
          items: ['Male', 'Female', 'Rather not say']
              .map(
                (sex) => DropdownMenuItem(
                  value: sex,
                  child: Text(sex, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isConfirm = false,
    bool readOnly = false,
  }) {
    final obscured = isConfirm ? _obscureConfirmPassword : _obscurePassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: ctrl,
          readOnly: readOnly,
          keyboardType: keyboardType,
          obscureText: isPassword && obscured,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontSize: 18,
            color: readOnly ? Palette.inkMuted : Palette.ink,
          ),
          decoration: _decoration(
            icon,
            readOnly: readOnly,
            suffix: isPassword
                ? IconButton(
                    tooltip: obscured ? 'Show password' : 'Hide password',
                    icon: Icon(
                      obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Palette.inkMuted,
                    ),
                    onPressed: () => setState(() {
                      if (isConfirm) {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    }),
                  )
                : readOnly
                ? const Icon(Icons.lock_rounded, color: Palette.inkSubtle)
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignup() async {
    // 1. STRICT VALIDATION
    if (_nameController.text.trim().isEmpty ||
        _staffIdController.text.trim().isEmpty ||
        _departmentController.text
            .trim()
            .isEmpty || // Moved department up logically
        _phoneController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _selectedGender == null ||
        _emailController.text.trim().isEmpty) {
      _mascot.currentState?.sad('A few boxes are still empty.');
      VistaToast.error(
        context,
        'Fill in every field to continue. Only the photo is optional.',
      );
      return;
    }

    // 2. Validate passwords ONLY if they are NOT a Google User
    if (widget.googleUser == null) {
      if (_passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        VistaToast.error(context, 'Please enter a password');
        return;
      }
      if (_passwordController.text.length < 6) {
        _mascot.currentState?.sad('A bit longer, please.');
        VistaToast.error(
          context,
          'Use at least 6 characters for your password.',
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _mascot.currentState?.sad("Those don't match.");
        VistaToast.error(
          context,
          'The two passwords are different. Type them again.',
        );
        return;
      }
    }

    int? age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      VistaToast.error(context, 'Please enter a valid age');
      return;
    }

    setState(() => _isLoading = true);

    User? finalUser;
    bool isNewEmailUser = false;

    try {
      // 3. Determine Auth Flow
      if (widget.googleUser != null) {
        finalUser = widget.googleUser;
      } else {
        UserCredential userCredential = await authService.value.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        finalUser = userCredential.user;
        isNewEmailUser = true;
        await authService.value.updateUsername(
          userName: _nameController.text.trim(),
        );
      }

      if (finalUser == null) throw Exception("Failed to get user information.");

      // 4. Upload Profile Image OR use Google's existing image
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(finalUser.uid);
      } else if (widget.googleUser?.photoURL != null) {
        profileImageUrl = widget.googleUser!.photoURL;
      }

      // 5. Create DB Entry (Wrapped for rollback)
      try {
        await databaseService.createUserDocument(
          userId: finalUser.uid,
          name: _nameController.text.trim(),
          staffId: _staffIdController.text.trim(),
          age: age,
          email: _emailController.text.trim(),
          department: _departmentController.text.trim(),
          contactNumber: _phoneController.text.trim(),
          sex: _selectedGender,
          role: 'admin',
        );
      } catch (dbError) {
        if (isNewEmailUser) {
          await finalUser.delete();
        }
        throw Exception(
          "Failed to save profile data. Please try again. ($dbError)",
        );
      }

      // 6. Update Database Image URL
      if (profileImageUrl != null) {
        await databaseService.updateUserProfile(
          userId: finalUser.uid,
          role: 'admin',
          profileImageUrl: profileImageUrl,
        );
      }

      // 7. Log Activity
      await activityLogsService.logActivity(
        userId: finalUser.uid,
        action: 'account_created',
        details: 'MSWD Staff registered',
      );

      if (mounted) {
        VistaToast.info(context, 'Staff account created!');
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        VistaToast.error(context, e.message ?? 'Signup failed');
      }
    } catch (e) {
      if (mounted) {
        VistaToast.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
