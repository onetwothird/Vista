// File: lib/roles/caretaker/home/caretaker_home_screen.dart

import 'dart:async';
import 'package:seelai_app/shared/widgets/mascot_moment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/caretaker_home_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patient_location/realtime_tracking_screen.dart';
import 'package:seelai_app/themes/constants.dart';
import 'package:seelai_app/themes/vista_theme.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/caretaker_header_section.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/caretaker_bottom_navigation.dart';
import 'package:seelai_app/roles/caretaker/home/sections/patients_screen/patients_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/requests_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/profile_screen/caretaker_profile_content.dart';
import 'package:seelai_app/roles/caretaker/home/sections/requests_screen/request_model.dart';
import 'package:seelai_app/roles/caretaker/services/notification_service.dart';
import 'package:seelai_app/roles/caretaker/services/location_service.dart';
import 'package:seelai_app/firebase/caretaker/location_tracking_service.dart';
import 'package:seelai_app/firebase/caretaker/request_service.dart';
import 'package:seelai_app/roles/caretaker/home/widgets/caretaker_notifications_bottom_sheet.dart';
import 'package:seelai_app/shared/widgets/incoming_call_listener.dart';
import 'package:seelai_app/roles/caretaker/home/sections/home_screen/communication/caretaker_missed_call_alert_section.dart';

class CaretakerHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CaretakerHomeScreen({super.key, required this.userData});

  @override
  State<CaretakerHomeScreen> createState() => _CaretakerHomeScreenState();
}

class _CaretakerHomeScreenState extends State<CaretakerHomeScreen> {
  late final NotificationService _notificationService;
  late final LocationService _locationService;
  late final RequestService _requestService;

  bool get _isDarkMode => themeController.isDark;

  int _selectedIndex = 0;
  int _pendingRequestsCount = 0;

  /// Tabs are built on first visit and then kept alive.
  final Set<int> _visitedTabs = {0};

  /// Only the nav bar listens to this, so hiding it on scroll is cheap.
  final ValueNotifier<bool> _navVisible = ValueNotifier(true);

  StreamSubscription<List<RequestModel>>? _requestsSubscription;
  StreamSubscription<Position>? _positionSubscription;
  int? _lastPendingCount;

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ??
      widget.userData['userId'] ??
      widget.userData['uid'] ??
      '';

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _locationService = LocationService();
    _requestService = RequestService();
    themeController.addListener(_onThemeChanged);
    _startLocationTracking();
    _setupGlobalRequestStream();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _setupGlobalRequestStream() {
    final userId = _userId;
    if (userId.isEmpty) {
      debugPrint('Error: No User ID found for Request Stream.');
      return;
    }

    _requestsSubscription = _requestService.streamRequests(userId).listen((
      requests,
    ) {
      if (!mounted) return;
      final pendingCount = requests
          .where((req) => req.status == RequestStatus.pending)
          .length;

      if (pendingCount != _pendingRequestsCount) {
        setState(() => _pendingRequestsCount = pendingCount);
      }

      if (_lastPendingCount != null && pendingCount > _lastPendingCount!) {
        _notificationService.showNotification(
          'New request',
          'A patient needs your assistance',
        );
      }
      _lastPendingCount = pendingCount;
    });
  }

  Future<void> _startLocationTracking() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final userId = _userId;
      if (userId.isEmpty) return;

      void send(Position p) => locationTrackingService.updateCaretakerLocation(
        caretakerId: userId,
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        speed: p.speed,
        heading: p.heading,
        altitude: p.altitude,
      );

      try {
        send(
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error sending initial location: $e');
      }

      if (!mounted) return;
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(send);
    } catch (e) {
      debugPrint('Location tracking error: $e');
    }
  }

  void _toggleDarkMode() => themeController.toggle();

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
    _navVisible.value = true;
  }

  void _updateNotification(String message) {}

  @override
  void dispose() {
    themeController.removeListener(_onThemeChanged);
    _requestsSubscription?.cancel();
    _positionSubscription?.cancel();
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
          'You will stop receiving assistance requests on this phone until you sign in again.',
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
      await _positionSubscription?.cancel();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        MascotMomentScreen.showSignedOut(context);
      }
    }
  }

  void _openNotifications() {
    final id = _userId;
    if (id.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: NotificationsBottomSheet(
          caretakerId: id,
          isDarkMode: _isDarkMode,
          requestService: _requestService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDarkMode;
    final theme = dark ? _AppTheme.dark : _AppTheme.light;

    return IncomingCallListener(
      userRole: 'caretaker',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _confirmExit();
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: theme.backgroundColor,
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
                  CaretakerMissedCallAlertSection(
                    caretakerId: _userId,
                    isDarkMode: dark,
                    theme: theme,
                  ),
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
              onItemTapped: _onNavItemTapped,
              textColor: theme.textColor,
              subtextColor: theme.subtextColor,
              pendingRequestsCount: _pendingRequestsCount,
            ),
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
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(
                  caretakerName: widget.userData['name'] ?? '',
                  profileImageUrl:
                      widget.userData['profileImageUrl'] as String?,
                  isDarkMode: dark,
                  pendingRequestsCount: _pendingRequestsCount,
                  onToggleDarkMode: _toggleDarkMode,
                  onProfileTap: () => _onNavItemTapped(3),
                  onNotificationTap: _openNotifications,
                  textColor: theme.textColor,
                  subtextColor: theme.subtextColor,
                ),
                HomeContent(
                  isDarkMode: dark,
                  theme: theme,
                  userData: widget.userData,
                  onNotificationUpdate: _updateNotification,
                  requestService: _requestService,
                  locationService: _locationService,
                ),
              ],
            ),
          ),
        ),
        lazy(
          1,
          () => PatientsContent(
            isDarkMode: dark,
            theme: theme,
            userData: widget.userData,
            locationService: _locationService,
          ),
        ),
        lazy(
          2,
          () => RequestsContent(
            isDarkMode: dark,
            theme: theme,
            userData: widget.userData,
            requestService: _requestService,
            onRequestCountChange: (count) {
              if (_pendingRequestsCount != count) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _pendingRequestsCount = count);
                });
              }
            },
          ),
        ),
        lazy(
          3,
          () => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: ProfileContent(
              userData: widget.userData,
              isDarkMode: dark,
              theme: theme,
            ),
          ),
        ),
        lazy(
          4,
          () => RealtimeTrackingScreen(
            isDarkMode: dark,
            theme: theme,
            userData: widget.userData,
            locationService: _locationService,
            onScroll: (down) => _navVisible.value = !down,
            onRestoreMenu: () => _navVisible.value = true,
          ),
        ),
      ],
    );
  }
}

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
