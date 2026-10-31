// File: lib/roles/mswd/home/widgets/bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_nav_bar.dart';

class MSWDBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Function(int) onItemTapped;
  final Color textColor;
  final Color subtextColor;

  const MSWDBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onItemTapped,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return VistaNavBar(
      selectedIndex: selectedIndex,
      isDarkMode: isDarkMode,
      onItemTapped: onItemTapped,
      leading: const [
        VistaNavItem(0, Icons.space_dashboard_outlined, 'Dashboard'),
        VistaNavItem(1, Icons.people_outline_rounded, 'Users'),
      ],
      action: const VistaNavItem(3, Icons.my_location_rounded, 'Track'),
      actionHint: 'Shows the live location of registered users',
      trailing: const [
        VistaNavItem(2, Icons.assignment_outlined, 'Requests'),
        VistaNavItem(4, Icons.menu_rounded, 'More'),
      ],
    );
  }
}
