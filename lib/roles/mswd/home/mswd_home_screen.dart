// File: lib/roles/mswd/home/mswd_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shimmer/shimmer.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/urgent_alerts_section.dart';
import 'package:seelai_app/roles/mswd/home/sections/location_track/location_tracking_screen.dart';
import 'package:seelai_app/roles/mswd/home/widgets/mswd_header_section.dart';
import 'package:seelai_app/roles/mswd/home/widgets/bottom_navigation.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/announcement.dart';
import 'package:seelai_app/roles/mswd/home/sections/users/users_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/requests/mswd_requests_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/profile_content/more_content.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/dashboard_stats.dart';
import 'package:seelai_app/roles/mswd/home/sections/dashboard/quick_actions.dart';
import 'package:seelai_app/roles/mswd/home/widgets/mswd_notifications_bottom_sheet.dart';
import 'package:seelai_app/firebase/firebase_services.dart';
import 'package:seelai_app/screens/onboarding_screen.dart';
import 'package:seelai_app/roles/mswd/home/sections/registration/subject_registration_screen.dart';
import 'package:seelai_app/themes/palette.dart';
import 'package:seelai_app/themes/vista_theme.dart';

class MSWDHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MSWDHomeScreen({super.key, required this.userData});

  @override
  State<MSWDHomeScreen> createState() => _MSWDHomeScreenState();
}

class _MSWDHomeScreenState extends State<MSWDHomeScreen> {
  bool get _isDarkMode => themeController.isDark;

  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);

  int _pendingRequestsCount = 0;
  StreamSubscription<DatabaseEvent>? _requestsSubscription;
  late Future<Map<String, int>> _dashboardStatsFuture;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    themeController.addListener(_onThemeChanged);
    _startPendingRequestsListener();

    _dashboardStatsFuture = adminService.getUserStatistics();
    _dashboardStatsFuture
        .then((_) {
          if (mounted) setState(() => _isLoadingStats = false);
        })
        .catchError((error) {
          debugPrint('Error loading stats: $error');
          if (mounted) setState(() => _isLoadingStats = false);
        });
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _startPendingRequestsListener() {
    _requestsSubscription = databaseService.database
        .ref('assistance_requests')
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .listen(
          (event) {
            if (!mounted) return;
            var count = 0;
            if (event.snapshot.exists) {
              count = (event.snapshot.value as Map<dynamic, dynamic>).length;
            }
            if (count != _pendingRequestsCount) {
              setState(() => _pendingRequestsCount = count);
            }
          },
          onError: (error) {
            debugPrint('Error listening to pending requests: $error');
          },
        );
  }

  void _toggleDarkMode() => themeController.toggle();

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
    _navVisible.value = true;
  }

  @override
  void dispose() {
    themeController.removeListener(_onThemeChanged);
    _requestsSubscription?.cancel();
    _navVisible.dispose();
    super.dispose();
  }

  Future<void> _confirmExit() async {
    if (_selectedIndex != 0) {
      _onNavItemTapped(0);
      return;
    }
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of Vista?'),
        content: const Text(
          'You will need to sign in again to manage users and requests.',
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
    if (signOut == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _openNotifications(_AppTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: MSWDNotificationsBottomSheet(
          adminId: widget.userData['userId'] ?? '',
          isDarkMode: _isDarkMode,
          theme: theme,
          assistanceRequestService: assistanceRequestService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDarkMode;
    final theme = dark ? _AppTheme.dark : _AppTheme.light;

    return PopScope(
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
                    label: const Text('Register face or object'),
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
            child: _buildTabs(theme, dark),
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
          child: MSWDBottomNavigation(
            selectedIndex: _selectedIndex,
            isDarkMode: dark,
            onItemTapped: _onNavItemTapped,
            textColor: theme.textColor,
            subtextColor: theme.subtextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(_AppTheme theme, bool dark) {
    Widget lazy(int index, Widget Function() build) =>
        _visitedTabs.contains(index) ? build() : const SizedBox.shrink();

    return IndexedStack(
      index: _selectedIndex,
      children: [
        lazy(
          0,
          () => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                HeaderSection(
                  adminName: widget.userData['name'] ?? '',
                  profileImageUrl:
                      widget.userData['profileImageUrl'] as String?,
                  isDarkMode: dark,
                  pendingRequestsCount: _pendingRequestsCount,
                  onToggleDarkMode: _toggleDarkMode,
                  onProfileTap: () => _onNavItemTapped(4),
                  onNotificationTap: () => _openNotifications(theme),
                  textColor: theme.textColor,
                  subtextColor: theme.subtextColor,
                ),
                _buildDashboardContent(theme, dark),
              ],
            ),
          ),
        ),
        lazy(
          1,
          () => UsersContent(
            isDarkMode: dark,
            theme: theme,
            userData: widget.userData,
            onNavigateToLocation: () => _onNavItemTapped(3),
          ),
        ),
        lazy(
          2,
          () => RequestsContent(
            isDarkMode: dark,
            theme: theme,
            userData: widget.userData,
          ),
        ),
        lazy(
          3,
          () => MswdLocationTrackingScreen(
            isDarkMode: dark,
            theme: theme,
            userData: widget.userData,
            onScroll: (down) => _navVisible.value = !down,
            onRestoreMenu: () => _navVisible.value = true,
          ),
        ),
        lazy(
          4,
          () => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: MoreContent(
              userData: widget.userData,
              isDarkMode: dark,
              theme: theme,
              onToggleDarkMode: _toggleDarkMode,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(_AppTheme theme, bool dark) {
    const padding = EdgeInsets.fromLTRB(20, 24, 20, 160);
    if (_isLoadingStats) {
      return Padding(padding: padding, child: _buildSkeletonDashboard(dark));
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardStats(
            isDarkMode: dark,
            theme: theme,
            statsFuture: _dashboardStatsFuture,
          ),
          const SizedBox(height: 24),
          QuickActions(
            isDarkMode: dark,
            theme: theme,
            onNavigateToTab: _onNavItemTapped,
          ),
          const SizedBox(height: 32),
          UrgentAlertsSection(
            isDarkMode: dark,
            theme: theme,
            onNavigateToTab: _onNavItemTapped,
          ),
          const SizedBox(height: 16),
          AnnouncementSection(isDarkMode: dark, theme: theme),
        ],
      ),
    );
  }

  Widget _buildSkeletonDashboard(bool dark) {
    Widget block(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return Shimmer.fromColors(
      baseColor: dark ? Palette.nightSurface : Palette.line,
      highlightColor: dark ? Palette.nightRaised : Palette.paperSunk,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: block(120)),
              const SizedBox(width: 12),
              Expanded(child: block(120)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: block(120)),
              const SizedBox(width: 12),
              Expanded(child: block(120)),
            ],
          ),
          const SizedBox(height: 24),
          block(200),
          const SizedBox(height: 24),
          block(96),
          const SizedBox(height: 12),
          block(96),
        ],
      ),
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
                'Register for a user',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'The scanner will name this face or object for the partially sighted user.',
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
                subtitle: 'Scan an item the user handles every day',
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

class _AppTheme {
  final LinearGradient backgroundGradient;
  final Color textColor;
  final Color subtextColor;
  final Color cardColor;
  final Color backgroundColor;

  const _AppTheme({
    required this.backgroundGradient,
    required this.textColor,
    required this.subtextColor,
    required this.cardColor,
    required this.backgroundColor,
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
