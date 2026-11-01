// File: lib/roles/partially_sighted/home/widgets/header_section.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_header.dart';

class HeaderSection extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final Map<String, dynamic>? userData;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onNotificationTap;
  final VoidCallback? onProfileTap;
  final Color textColor;
  final Color subtextColor;
  final int unreadNotificationCount;
  final int currentStreak;

  const HeaderSection({
    super.key,
    required this.userName,
    this.profileImageUrl,
    this.userData,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    required this.onNotificationTap,
    this.onProfileTap,
    required this.textColor,
    required this.subtextColor,
    this.unreadNotificationCount = 0,
    this.currentStreak = 0,
  });

  String get _note {
    final n = unreadNotificationCount;
    if (n > 0) {
      return n == 1
          ? 'A caretaker replied to your request. Open notifications to see it.'
          : 'You have $n updates on your requests. Open notifications to see them.';
    }
    if (currentStreak > 1) {
      return 'You have used Vista $currentStreak days in a row. Tap Scan whenever you are ready.';
    }
    return 'You are all caught up. Tap Scan to read text or recognise what is in front of you.';
  }

  @override
  Widget build(BuildContext context) {
    return VistaHomeHeader(
      userData: userData,
      fullName: userName,
      fallbackName: 'there',
      profileImageUrl: profileImageUrl,
      isDarkMode: isDarkMode,
      onToggleDarkMode: onToggleDarkMode,
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
      notificationCount: unreadNotificationCount,
      note: _note,
      noteTone: unreadNotificationCount > 0
          ? NoteTone.attention
          : NoteTone.calm,
    );
  }
}
