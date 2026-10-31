// File: lib/roles/partially_sighted/home/widgets/bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_nav_bar.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final Function(int) onItemTapped;
  final Color textColor;
  final Color subtextColor;

  const CustomBottomNavigation({
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
        VistaNavItem(0, Icons.home_outlined, 'Home'),
        VistaNavItem(1, Icons.contacts_outlined, 'Contacts'),
      ],
      action: const VistaNavItem(2, Icons.document_scanner_outlined, 'Scan'),
      actionHint: 'Opens the scanner to read text, faces or objects',
      trailing: const [
        VistaNavItem(3, Icons.history_rounded, 'History'),
        VistaNavItem(4, Icons.person_outline_rounded, 'Profile'),
      ],
    );
  }
}
