// File: lib/roles/caretaker/home/widgets/caretaker_bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_nav_bar.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Function(int) onItemTapped;
  final Color textColor;
  final Color subtextColor;
  final int pendingRequestsCount;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onItemTapped,
    required this.textColor,
    required this.subtextColor,
    required this.pendingRequestsCount,
  });

  @override
  Widget build(BuildContext context) {
    return VistaNavBar(
      selectedIndex: selectedIndex,
      isDarkMode: isDarkMode,
      onItemTapped: onItemTapped,
      leading: const [
        VistaNavItem(0, Icons.home_outlined, 'Home'),
        VistaNavItem(1, Icons.people_outline_rounded, 'Patients'),
      ],
      action: const VistaNavItem(4, Icons.my_location_rounded, 'Track'),
      actionHint: 'Shows where your patients are right now',
      trailing: [
        VistaNavItem(
          2,
          Icons.inbox_outlined,
          'Requests',
          badge: pendingRequestsCount,
        ),
        const VistaNavItem(3, Icons.person_outline_rounded, 'Profile'),
      ],
    );
  }
}
