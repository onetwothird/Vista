// File: lib/roles/partially_sighted/home/home_screen.dart

import 'dart:async';
import 'package:seelai_app/shared/widgets/mascot_moment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/recent_activities/view_recent_activites.dart';
import 'package:seelai_app/roles/partially_sighted/home/widgets/header_section.dart';
import 'package:seelai_app/roles/partially_sighted/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/home_content.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/contacts_screen/contacts_content.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/profile_content/profile_content.dart';
import 'package:seelai_app/firebase/partially_sighted/camera_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/permission_service.dart';
import 'package:seelai_app/roles/partially_sighted/services/accessibility_service.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/partially_sighted/screens/scanner/mode_selection_screen.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/registration/subject_registration_screen.dart';
import 'package:seelai_app/roles/partially_sighted/home/widgets/notifications_bottom_sheet.dart';
import 'package:seelai_app/shared/widgets/incoming_call_listener.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/missed_call_alert_section.dart';
import 'package:seelai_app/themes/palette.dart';
import 'package:seelai_app/themes/vista_theme.dart';

class PartiallySightedHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PartiallySightedHomeScreen({super.key, required this.userData});

  @override
  State<PartiallySightedHomeScreen> createState() =>
      _VisuallyImpairedHomeScreenState();
}

class _VisuallyImpairedHomeScreenState
    extends State<PartiallySightedHomeScreen> {
  late final CameraService _cameraService;
  late final PermissionService _permissionService;
  late final AccessibilityService _accessibilityService;
  late final AssistanceRequestService _assistanceRequestService;

  bool get _isDarkMode => themeController.isDark;

  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  int _currentStreak = 0;

  /// Tabs are built the first time they are opened and then kept alive, so
  /// switching back is instant and does not re-open Firestore streams.
  final Set<int> _visitedTabs = {0};

  /// Only the nav bar and the add button listen to this, so hiding them on
  /// scroll does not rebuild the page.
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);

  StreamSubscription? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _permissionService = PermissionService();
    _accessibilityService = AccessibilityService();
    _assistanceRequestService = assistanceRequestService;
    themeController.addListener(_onThemeChanged);
    _requestPermissionsAndInitialize();
    _setupRequestListener();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _setupRequestListener() {
    final userId = widget.userData['uid'] as String?;
    if (userId == null || userId.isEmpty) return;

    _requestsSubscription = _assistanceRequestService
        .streamPatientRequests(userId)
        .listen((requests) {
          if (!mounted) return;
          final now = DateTime.now();
          final newNotifications = requests.where((req) {
            if (req.status == RequestStatus.accepted ||
                req.status == RequestStatus.inProgress) {
              return true;
            }
            if (req.status == RequestStatus.declined) {
              final time = req.responseTime ?? req.timestamp;
              return now.difference(time).inHours < 24;
            }
            return false;
          }).toList();

          if (newNotifications.length != _unreadNotificationCount) {
            setState(() => _unreadNotificationCount = newNotifications.length);
          }

          final newlyAccepted = newNotifications.any(
            (req) =>
                req.status == RequestStatus.accepted &&
                req.responseTime != null &&
                now.difference(req.responseTime!).inMinutes < 1,
          );
          if (newlyAccepted) {
            _accessibilityService.announce(
              'Caretaker accepted your assistance request',
            );
          }
        });
  }

  Future<void> _requestPermissionsAndInitialize() async {
    final userId = widget.userData['uid'] as String?;
    if (userId != null) {
      final streak = await databaseService.updateAndGetStreak(
        userId,
        'partially_sighted',
      );
      if (mounted) setState(() => _currentStreak = streak);
    }

    final result = await _permissionService.requestAllPermissions();
    if (mounted && result.hasAllPermissions) await _cameraService.initialize();
  }

  void _toggleDarkMode() {
    themeController.toggle();
    _accessibilityService.announce(
      themeController.isDark ? 'Dark mode on' : 'Light mode on',
    );
  }

  void _openNotifications() {
    _accessibilityService.announce('Opening notifications');
    final userId = widget.userData['uid'] as String?;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ViNotificationsBottomSheet(
          userId: userId,
          isDarkMode: _isDarkMode,
          requestService: _assistanceRequestService,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _unreadNotificationCount = 0);
    });
  }

  void _selectTab(int index) {
    if (index == 2) {
      _openCameraScanner();
      return;
    }
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
    _navVisible.value = true;
    const labels = ['Home', 'Contacts', 'Scan', 'History', 'Profile'];
    _accessibilityService.announce(labels[index]);
  }

  Future<void> _openCameraScanner() async {
    _accessibilityService.announce('Opening scanner');
    if (!_cameraService.isInitialized) await _cameraService.initialize();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeSelectionScreen(
          cameraService: _cameraService,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  void _updateNotification(String message) {}

  @override
  void dispose() {
    themeController.removeListener(_onThemeChanged);
    _cameraService.dispose();
    _requestsSubscription?.cancel();
    _navVisible.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    if (_selectedIndex != 0) {
      _selectTab(0);
      return false;
    }

    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of Vista?'),
        content: const Text(
          'You will need to sign in again to use the scanner and contact your caretakers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (signOut == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        MascotMomentScreen.showSignedOut(context);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDarkMode;
    final theme = dark ? _AppTheme.dark : _AppTheme.light;

    return IncomingCallListener(
      userRole: 'partially_sighted',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _confirmExit();
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: theme.backgroundColor,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _selectedIndex == 0
              ? ValueListenableBuilder<bool>(
                  valueListenable: _navVisible,
                  builder: (context, visible, child) => AnimatedSlide(
                    duration: const Duration(milliseconds: 200),
                    offset: visible ? Offset.zero : const Offset(0, 2),
                    child: child,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 84),
                    child: FloatingActionButton.extended(
                      backgroundColor: Palette.brand(dark),
                      foregroundColor: dark ? Palette.ink : Colors.white,
                      onPressed: () => _showAddOptionsBottomSheet(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add face or object'),
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            bottom: false,
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (n.direction == ScrollDirection.forward) {
                  _navVisible.value = true;
                } else if (n.direction == ScrollDirection.reverse) {
                  _navVisible.value = false;
                }
                return false;
              },
              child: Stack(
                children: [
                  _buildTabs(theme, dark),
                  MissedCallAlertSection(isDarkMode: dark, theme: theme),
                ],
              ),
            ),
          ),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: _navVisible,
            builder: (context, visible, child) => AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              offset: visible ? Offset.zero : const Offset(0, 1),
              child: child,
            ),
            child: CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              isDarkMode: dark,
              onItemTapped: _selectTab,
              textColor: theme.textColor,
              subtextColor: theme.subtextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(_AppTheme theme, bool dark) {
    final userId = widget.userData['uid'] as String? ?? '';
    Widget lazy(int index, Widget Function() build) =>
        _visitedTabs.contains(index) ? build() : const SizedBox.shrink();

    return IndexedStack(
      index: _selectedIndex,
      children: [
        lazy(
          0,
          () => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(
                  userName: widget.userData['name'] ?? '',
                  profileImageUrl:
                      widget.userData['profileImageUrl'] as String?,
                  isDarkMode: dark,
                  onToggleDarkMode: _toggleDarkMode,
                  onNotificationTap: _openNotifications,
                  onProfileTap: () => _selectTab(4),
                  textColor: theme.textColor,
                  subtextColor: theme.subtextColor,
                  unreadNotificationCount: _unreadNotificationCount,
                  currentStreak: _currentStreak,
                ),
                HomeContent(
                  cameraService: _cameraService,
                  permissionService: _permissionService,
                  isDarkMode: dark,
                  theme: theme,
                  onNotificationUpdate: _updateNotification,
                  userData: widget.userData,
                ),
              ],
            ),
          ),
        ),
        lazy(
          1,
          () => ContactsContent(
            isDarkMode: dark,
            theme: theme,
            userData: widget.userData,
          ),
        ),
        const SizedBox.shrink(),
        lazy(
          3,
          () => ViewRecentActivities(
            isDarkMode: dark,
            theme: theme,
            userId: userId,
            onToggleDarkMode: _toggleDarkMode,
          ),
        ),
        lazy(
          4,
          () => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: ProfileContent(
              userData: widget.userData,
              isDarkMode: dark,
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    final dark = _isDarkMode;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (bc) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teach Vista to recognise',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Vista will name them when they appear in the scanner.',
                style: TextStyle(fontSize: 16, color: Palette.muted(dark)),
              ),
              const SizedBox(height: 20),
              _buildAddOptionCard(
                icon: Icons.face_outlined,
                title: 'A person',
                subtitle: 'Scan the face of a caretaker or family member',
                onTap: () => _openRegistration(bc, SubjectType.face),
              ),
              const SizedBox(height: 12),
              _buildAddOptionCard(
                icon: Icons.category_outlined,
                title: 'An object',
                subtitle: 'Scan something you use every day',
                onTap: () => _openRegistration(bc, SubjectType.object),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRegistration(BuildContext sheetContext, SubjectType type) {
    Navigator.pop(sheetContext);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectRegistrationScreen(
          isDarkMode: _isDarkMode,
          subjectType: type,
        ),
      ),
    );
  }

  Widget _buildAddOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final dark = _isDarkMode;
    return Material(
      color: Palette.page(dark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Palette.border(dark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: dark ? Palette.violetTintNight : Palette.violetTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: Palette.brand(dark)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Palette.text(dark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: Palette.muted(dark),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Palette.muted(dark)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colours handed to child sections, which read them dynamically.
class _AppTheme {
  final LinearGradient backgroundGradient;
  final Color backgroundColor;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;

  const _AppTheme({
    required this.backgroundGradient,
    required this.backgroundColor,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
  });

  static const light = _AppTheme(
    backgroundGradient: LinearGradient(colors: [Palette.paper, Palette.paper]),
    backgroundColor: Palette.paper,
    textColor: Palette.ink,
    subtextColor: Palette.inkMuted,
    cardColor: Palette.surface,
  );

  static const dark = _AppTheme(
    backgroundGradient: LinearGradient(
      colors: [Palette.nightPage, Palette.nightPage],
    ),
    backgroundColor: Palette.nightPage,
    textColor: Palette.nightText,
    subtextColor: Palette.nightMuted,
    cardColor: Palette.nightSurface,
  );
}
