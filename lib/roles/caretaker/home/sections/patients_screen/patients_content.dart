// File: lib/roles/caretaker/home/sections/patients_screen/patients_content.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_model.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patient_details_screen.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'call_patients.dart';
import 'message_patients.dart';

import 'package:seelai_app/shared/widgets/vista_header.dart';
import 'package:seelai_app/shared/widgets/vista_empty_state.dart';

class PatientsContent extends StatefulWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;
  final LocationService locationService;
  final ScrollController? scrollController;

  const PatientsContent({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
    required this.locationService,
    this.scrollController,
  });

  @override
  State<PatientsContent> createState() => _PatientsContentState();
}

class _PatientsContentState extends State<PatientsContent>
    with SingleTickerProviderStateMixin {
  final Color _primaryColor = Palette.violet;

  StreamSubscription? _patientsSubscription;
  List<PatientModel> _patients = [];
  bool _isLoading = true;
  String? _error;
  String? _caretakerId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isSimulatingLoad = false;

  // === ANIMATION CONTROLLERS (Header & Mascot Only) ===
  late AnimationController _entryController;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _initializeCaretakerId();

    // === Initialize Animations ===
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Header fades & slides in
    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );

    // Mascot and Bubble pop in

    // Start header animations immediately
    _entryController.value = 1.0;

    // Trigger the skeleton animation for 600ms on load
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isSimulatingLoad = false;
        });
      }
    });
  }

  String _getFirstName() {
    final name = widget.userData['name'] as String? ?? 'Caretaker';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'Caretaker';
  }

  List<String> _getMascotMessages() {
    final onlineCount = _patients.where((p) => p.isOnline).length;
    final totalCount = _patients.length;

    return [
      'Hello, ${_getFirstName()}! You are currently caring for $totalCount patient${totalCount != 1 ? 's' : ''}${totalCount > 0 ? ', with $onlineCount online right now.' : '.'}',
      'Did you know? You can tap on a patient\'s card to view their full details and location.',
      'Need to reach out? Use the quick action buttons to call or message your patients directly.',
    ];
  }

  Future<void> _initializeCaretakerId() async {
    String? caretakerId =
        widget.userData['userId'] as String? ??
        widget.userData['uid'] as String?;

    if (caretakerId == null || caretakerId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      caretakerId = user?.uid;
    }

    if (caretakerId == null || caretakerId.isEmpty) {
      setState(() {
        _error = 'Caretaker ID not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _caretakerId = caretakerId);
    _setupPatientsStream();
  }

  void _setupPatientsStream() {
    if (_caretakerId == null) return;

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });

    _patientsSubscription = caretakerPatientService
        .streamCaretakerPatients(_caretakerId!)
        .listen(
          (patientsData) {
            if (mounted) {
              setState(() {
                _patients = patientsData.map((patientData) {
                  int parsedAge = 0;
                  if (patientData['age'] != null) {
                    parsedAge = patientData['age'] is int
                        ? patientData['age']
                        : int.tryParse(patientData['age'].toString()) ?? 0;
                  }

                  return PatientModel(
                    id: patientData['userId']?.toString() ?? '',
                    name: patientData['name']?.toString() ?? 'Unknown',
                    age: parsedAge,
                    disabilityType:
                        patientData['disabilityType']?.toString() ??
                        'Not specified',
                    contactNumber:
                        (patientData['contactNumber'] ?? patientData['phone'])
                            ?.toString() ??
                        'N/A',
                    address: patientData['address']?.toString() ?? 'No address',
                    isOnline: false,
                    lastActive: DateTime.now(),
                    profileImageUrl: patientData['profileImageUrl']?.toString(),
                  );
                }).toList();

                _isLoading = false;
                _error = null;
              });
            }
          },
          onError: (error) {
            debugPrint('Error loading patients: $error');
            if (mounted) {
              setState(() {
                _error = 'Failed to load patients: $error';
                _isLoading = false;
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _patientsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPatients() async {
    if (_caretakerId == null) {
      await _initializeCaretakerId();
      return;
    }

    // Data arrives through live streams; nothing to wait for.
  }

  List<PatientModel> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;

    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patient.disabilityType.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  // ==========================================
  // WIDGETS: Skeleton Loaders
  // ==========================================
  Widget _buildSkeletonSearchBar() {
    final baseColor = widget.isDarkMode ? Palette.nightSurface : Palette.line;
    final highlightColor = widget.isDarkMode
        ? Palette.nightRaised
        : Palette.paperSunk;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSkeletonPatientsList() {
    final baseColor = widget.isDarkMode ? Palette.nightSurface : Palette.line;
    final highlightColor = widget.isDarkMode
        ? Palette.nightRaised
        : Palette.paperSunk;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showSkeleton =
        _isSimulatingLoad || (_isLoading && _patients.isEmpty);

    return RefreshIndicator(
      onRefresh: _refreshPatients,
      color: _primaryColor,
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Top Section (Header & Mascot) - Always Animates In
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _headerOpacity,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.05,
                        right: width * 0.05,
                        top: spacingLarge,
                      ),
                      child: _buildHeader(),
                    ),
                  ),
                ),
                const SizedBox(height: spacingMedium),
                _buildMascotBanner(),
              ],
            ),
          ),

          // 2. Middle Section (Search & List) - Skeleton shows instantly
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: spacingMedium),

                  // Search Bar conditionally shows skeleton
                  if (showSkeleton)
                    _buildSkeletonSearchBar()
                  else if (_patients.isNotEmpty)
                    _buildSearchBar(),

                  const SizedBox(height: spacingLarge),

                  // Content conditionally shows skeleton
                  if (_error != null && _patients.isEmpty && !showSkeleton)
                    _buildErrorState()
                  else if (showSkeleton)
                    _buildSkeletonPatientsList()
                  else if (_patients.isEmpty)
                    _buildEmptyState()
                  else
                    _buildPatientsList(),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Patients',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: widget.theme.textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage and monitor your paired users',
          style: TextStyle(fontSize: 14, color: widget.theme.subtextColor),
        ),
      ],
    );
  }

  Widget _buildMascotBanner() {
    return VistaNote(
      message: _getMascotMessages().first,
      isDarkMode: widget.isDarkMode,
      mascotAsset: 'assets/vista-icons/vista-signin.png',
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: widget.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        style: body.copyWith(color: widget.theme.textColor),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search patients...',
          hintStyle: body.copyWith(color: widget.theme.subtextColor),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.theme.subtextColor,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: widget.theme.subtextColor,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(spacingXLarge),
              decoration: BoxDecoration(
                color: error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: error.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: spacingLarge),
            Text(
              'Failed to load patients',
              style: bodyBold.copyWith(
                color: widget.theme.textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: spacingSmall),
            Text(
              _error ?? 'An error occurred',
              style: body.copyWith(
                color: widget.theme.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeCaretakerId();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(
                  horizontal: spacingXLarge,
                  vertical: spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return VistaEmptyState(
      title: 'No patients yet',
      message:
          'When partially sighted users select you as their caretaker, they will appear here automatically',
      isDarkMode: widget.isDarkMode,
    );
  }

  Widget _buildPatientsList() {
    final filteredPatients = _filteredPatients;

    if (filteredPatients.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: VistaEmptyState(
          title: 'No patients found',
          message: 'Try a different name.',
          isDarkMode: widget.isDarkMode,
        ),
      );
    }

    return Column(
      children: filteredPatients.map((patient) {
        return Padding(
          padding: const EdgeInsets.only(bottom: spacingMedium),
          child: _buildPatientCard(patient),
        );
      }).toList(),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(radiusXLarge),
        boxShadow: widget.isDarkMode
            ? [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: widget.isDarkMode
              ? _primaryColor.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsScreen(
                  patient: patient,
                  isDarkMode: widget.isDarkMode,
                  locationService: widget.locationService,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(radiusXLarge),
          child: Padding(
            padding: const EdgeInsets.all(spacingLarge),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        _buildProfileAvatar(patient),
                        if (patient.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Palette.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.theme.cardColor,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: spacingMedium),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: bodyBold.copyWith(
                              fontSize: 18,
                              color: widget.theme.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          SizedBox(
                            width: double.infinity,
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.85, 1.0],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.dstIn,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 32.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: _primaryColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.cake_rounded,
                                              size: 12,
                                              color: _primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${patient.age} y/o',
                                              style: caption.copyWith(
                                                fontSize: 12,
                                                color: _primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: accent.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.visibility_off_rounded,
                                              size: 12,
                                              color: accent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              patient.disabilityType,
                                              style: caption.copyWith(
                                                fontSize: 12,
                                                color: accent,
                                                fontWeight: FontWeight.w600,
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

                          if (patient.address != null &&
                              patient.address != 'No address') ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: widget.theme.subtextColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    patient.address!,
                                    style: caption.copyWith(
                                      fontSize: 13,
                                      color: widget.theme.subtextColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: widget.theme.subtextColor.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: spacingMedium),
                Divider(
                  height: 1,
                  color: widget.theme.subtextColor.withValues(alpha: 0.15),
                ),
                const SizedBox(height: spacingMedium),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        color: Palette.success,
                        onTap: () =>
                            callPatient(context, patientName: patient.name),
                      ),
                    ),
                    const SizedBox(width: spacingSmall),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        color: _primaryColor,
                        isOutlined: true,
                        onTap: () =>
                            messagePatient(context, patientName: patient.name),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isOutlined ? Border.all(color: color, width: 1.5) : null,
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isOutlined ? color : white),
              const SizedBox(width: 8),
              Text(
                label,
                style: bodyBold.copyWith(
                  fontSize: 14,
                  color: isOutlined ? color : white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(PatientModel patient) {
    final hasProfileImage =
        patient.profileImageUrl != null && patient.profileImageUrl!.isNotEmpty;

    return Hero(
      tag: 'patient_avatar_${patient.id}',
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            color: widget.isDarkMode ? Palette.inkSoft : Palette.line,
          ),
          child: ClipOval(
            child: hasProfileImage
                ? Image.network(
                    patient.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarPlaceholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildAvatarPlaceholder(isLoading: true);
                    },
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.violet, Palette.violet],
        ),
      ),
      child: Center(
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.person_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class TypewriterText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const TypewriterText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) => Text(text, style: style);
}
