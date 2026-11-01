// File: lib/roles/partially_sighted/auth/signup/signup_screen.dart

import 'dart:io';
import 'package:seelai_app/shared/widgets/vista_toast.dart';
import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/auth_mascot_header.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seelai_app/storage/cloudinary_service.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/firebase/auth_service.dart';
import 'package:seelai_app/firebase/database_service.dart';
import 'package:seelai_app/firebase/activity_logs_service.dart';
import 'package:seelai_app/mobile/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartiallySightedSignupScreen extends StatefulWidget {
  final User? googleUser; // Captures the Google Account

  const PartiallySightedSignupScreen({super.key, this.googleUser});

  @override
  State<PartiallySightedSignupScreen> createState() =>
      _PartiallySightedSignupScreenState();
}

class _PartiallySightedSignupScreenState
    extends State<PartiallySightedSignupScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  final _mascot = GlobalKey<VistaMascotState>();
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedGender;
  String? _selectedDisabilityType;
  DateTime? _selectedBirthdate;

  final List<String> _genderOptions = ['Male', 'Female', 'Rather Not Say'];

  // Updated with WHO Classifications and functional descriptions
  final List<String> _disabilityTypes = [
    'Near Normal (Struggles with small print)',
    'Moderate (Needs magnifiers to read)',
    'Severe / Legally Blind (Faces are blurry close up)',
    'Profound (Relies heavily on audio/cane)',
    'Near Total (Can only see light or hand motion)',
  ];

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

    // PRE-FILL DATA FROM GOOGLE (Name is editable, Email is locked)
    if (widget.googleUser != null) {
      _emailController.text = widget.googleUser!.email ?? '';
      _nameController.text = widget.googleUser!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _idNumberController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _diagnosisController.dispose();
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
      'partially_sighted',
    );
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedBirthdate = picked);
  }

  // --- Informational Dialog for Disability Categories ---
  void _showCategoryInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, // Prevents Material 3 tinting
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            "Which category am I?",
            style: TextStyle(fontWeight: FontWeight.bold, color: Palette.ink),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryItem(
                  title: "Near Normal (20/30 to 20/60)",
                  description:
                      "You have slight difficulty with fine details, like reading small print or street signs, even with normal glasses.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Moderate (20/70 to 20/160)",
                  description:
                      "You likely need strong magnifiers to read. Navigating is generally fine, but recognizing faces from across a room is difficult.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Severe (20/200 to 20/400)",
                  description:
                      "This is the threshold for legal blindness. You cannot read standard print. You can see shapes and large objects, but faces are very blurry even up close.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Profound (20/500 to 20/1000)",
                  description:
                      "You rely heavily on screen readers and mobility aids (like a white cane). You might only be able to see very large, high-contrast letters extremely close to your face.",
                ),
                SizedBox(height: 16),
                _CategoryItem(
                  title: "Near Total (≤ 5° field)",
                  description:
                      "You cannot see shapes. You can only tell if a room is light or dark, or if someone is waving their hand right in front of your eyes.",
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Got it",
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGoogle = widget.googleUser != null;

    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthMascotHeader(
                  mascotKey: _mascot,
                  pose: MascotPose.signUp,
                  lines: const [
                    "Let's set you up!",
                    'I just need a few details.',
                    'Your info stays private.',
                    'Almost there, keep going!',
                  ],
                ),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              isGoogle
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
                            'Your caretaker and the MSWD use these details '
                            'to help you quickly in an emergency.',
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.45,
                              color: Palette.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildPhotoPicker(),
                          _buildSectionHeader('About you'),
                          _buildTextField(
                            _idNumberController,
                            'ID number',
                            Icons.badge_outlined,
                          ),
                          _gap,
                          _buildTextField(
                            _nameController,
                            'Full name',
                            Icons.person_outline,
                          ),
                          _gap,
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
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: _buildDropdownField(
                                  _selectedGender,
                                  _genderOptions,
                                  'Gender',
                                  Icons.wc_outlined,
                                  (val) =>
                                      setState(() => _selectedGender = val),
                                ),
                              ),
                            ],
                          ),
                          _gap,
                          _buildDateField(
                            _selectedBirthdate,
                            'Birthdate',
                            Icons.calendar_today_outlined,
                            _selectBirthdate,
                          ),
                          _gap,
                          _buildTextField(
                            _addressController,
                            'Home address',
                            Icons.home_outlined,
                          ),
                          _gap,
                          _buildTextField(
                            _contactNumberController,
                            'Phone number',
                            Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildSectionHeader(
                            'Your vision',
                            trailing: TextButton.icon(
                              onPressed: _showCategoryInfoDialog,
                              icon: const Icon(Icons.help_outline, size: 22),
                              label: const Text(
                                'Help me choose',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Palette.violet,
                                minimumSize: const Size(48, 48),
                              ),
                            ),
                          ),
                          _buildDropdownField(
                            _selectedDisabilityType,
                            _disabilityTypes,
                            'Vision category',
                            Icons.visibility_outlined,
                            (val) =>
                                setState(() => _selectedDisabilityType = val),
                          ),
                          _gap,
                          _buildTextField(
                            _diagnosisController,
                            'Diagnosis',
                            Icons.medical_information_outlined,
                          ),
                          _buildSectionHeader('Sign-in details'),
                          _buildTextField(
                            _emailController,
                            'Email',
                            Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: isGoogle,
                          ),
                          if (!isGoogle) ...[
                            _gap,
                            _buildTextField(
                              _passwordController,
                              'Password',
                              Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'At least 6 characters.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Palette.inkMuted,
                                ),
                              ),
                            ),
                            _gap,
                            _buildTextField(
                              _confirmPasswordController,
                              'Confirm password',
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
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isGoogle
                                    ? 'Save and continue'
                                    : 'Create account',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LoadingOverlay(
              message: 'Creating your account...',
              isVisible: true,
            ),
        ],
      ),
    );
  }

  static const _gap = SizedBox(height: 18);

  Widget _buildPhotoPicker() {
    final ImageProvider? image = _profileImage != null
        ? FileImage(_profileImage!)
        : widget.googleUser?.photoURL != null
        ? NetworkImage(widget.googleUser!.photoURL!)
        : null;

    return Semantics(
      button: true,
      label: image == null ? 'Add a profile photo' : 'Change profile photo',
      child: InkWell(
        onTap: _isLoading ? null : _showImageSourceDialog,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.line, width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Palette.violetTint,
                backgroundImage: image,
                child: image == null
                    ? const Icon(
                        Icons.add_a_photo_outlined,
                        color: Palette.violet,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image == null ? 'Add a profile photo' : 'Looking good!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      image == null
                          ? 'Helps your caretaker recognise you. Optional.'
                          : 'Tap to change it.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: Palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Palette.inkMuted),
            ],
          ),
        ),
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

  Widget _buildDropdownField(
    String? val,
    List<String> items,
    String label,
    IconData icon,
    Function(String?) changed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: val,
          hint: const Text(
            'Choose',
            style: TextStyle(color: Palette.inkSubtle, fontSize: 17),
          ),
          borderRadius: BorderRadius.circular(18),
          dropdownColor: Colors.white,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(i, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _isLoading ? null : changed,
          style: const TextStyle(color: Palette.ink, fontSize: 17),
          decoration: _decoration(icon),
        ),
      ],
    );
  }

  Widget _buildDateField(
    DateTime? date,
    String label,
    IconData icon,
    VoidCallback tap,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Semantics(
          button: true,
          child: InkWell(
            onTap: _isLoading ? null : tap,
            borderRadius: BorderRadius.circular(18),
            child: InputDecorator(
              decoration: _decoration(
                icon,
                suffix: const Icon(
                  Icons.expand_more_rounded,
                  color: Palette.inkMuted,
                ),
              ),
              child: Text(
                date != null
                    ? '${months[date.month - 1]} ${date.day}, ${date.year}'
                    : 'Choose a date',
                style: TextStyle(
                  color: date != null ? Palette.ink : Palette.inkSubtle,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignup() async {
    if (_idNumberController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _selectedGender == null ||
        _ageController.text.trim().isEmpty ||
        _selectedBirthdate == null ||
        _selectedDisabilityType == null ||
        _diagnosisController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _mascot.currentState?.sad('A few boxes are still empty.');
      VistaToast.error(
        context,
        'Fill in every field to continue. Only the photo is optional.',
      );
      return;
    }

    if (widget.googleUser == null) {
      if (_passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _mascot.currentState?.sad('You need a password.');
        VistaToast.error(context, 'Enter a password and confirm it.');
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
      _mascot.currentState?.sad('Is that your age?');
      VistaToast.error(context, 'Enter your age as a number, like 34.');
      return;
    }

    setState(() => _isLoading = true);

    User? finalUser;
    bool isNewEmailUser = false;

    try {
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

      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(finalUser.uid);
      } else if (widget.googleUser?.photoURL != null) {
        profileImageUrl = widget.googleUser!.photoURL;
      }

      try {
        await databaseService.createUserDocument(
          userId: finalUser.uid,
          idNumber: _idNumberController.text.trim(),
          name: _nameController.text.trim(),
          sex: _selectedGender!,
          age: age,
          birthdate: _selectedBirthdate!,
          disabilityType: _selectedDisabilityType!,
          diagnosis: _diagnosisController.text.trim(),
          address: _addressController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          email: _emailController.text.trim(),
          role: 'partially_sighted',
        );
      } catch (dbError) {
        if (isNewEmailUser) {
          await finalUser.delete();
        }
        throw Exception(
          "Failed to save profile data. Please try again. ($dbError)",
        );
      }

      if (profileImageUrl != null) {
        await databaseService.updateUserProfile(
          userId: finalUser.uid,
          role: 'partially_sighted',
          profileImageUrl: profileImageUrl,
        );
      }

      await activityLogsService.logActivity(
        userId: finalUser.uid,
        action: 'account_created',
        details: 'User signed up as partially_sighted',
      );

      if (mounted) {
        VistaToast.success(
          context,
          'Account created. Sign in to start using Vista.',
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _mascot.currentState?.sad('Something went wrong.');
        VistaToast.error(
          context,
          e.code == 'email-already-in-use'
              ? 'That email already has an account. Sign in instead.'
              : e.code == 'network-request-failed'
              ? "Can't reach Vista. Check your internet connection."
              : e.message ?? 'Sign-up failed. Try again.',
        );
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

// Helper widget for clean, justified, and readable list items
class _CategoryItem extends StatelessWidget {
  final String title;
  final String description;

  const _CategoryItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Palette.inkSoft,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            height: 1.5,
            fontSize: 14,
            color: Palette.inkMuted,
          ),
        ),
      ],
    );
  }
}
