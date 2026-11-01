// File: lib/roles/caretaker/home/widgets/caretaker_header_section.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_header.dart';

class HeaderSection extends StatelessWidget {
  final String caretakerName;
  final String? profileImageUrl;
  final Map<String, dynamic>? userData;
  final bool isDarkMode;
  final int pendingRequestsCount;
  final int activeRequestsCount;
  final VoidCallback onToggleDarkMode;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final Color textColor;
  final Color subtextColor;

  const HeaderSection({
    super.key,
    required this.caretakerName,
    this.profileImageUrl,
    this.userData,
    required this.isDarkMode,
    required this.pendingRequestsCount,
    this.activeRequestsCount = 0,
    required this.onToggleDarkMode,
    this.onProfileTap,
    this.onNotificationTap,
    required this.textColor,
    required this.subtextColor,
  });

  String get _note {
    final p = pendingRequestsCount;
    if (p > 0) {
      return p == 1
          ? '1 assistance request is waiting for your response.'
          : '$p assistance requests are waiting for your response.';
    }
    if (activeRequestsCount > 0) {
      return activeRequestsCount == 1
          ? 'You have 1 request in progress.'
          : 'You have $activeRequestsCount requests in progress.';
    }
    return 'No requests are waiting. Your patients appear under Patients.';
  }

  @override
  Widget build(BuildContext context) {
    return VistaHomeHeader(
      userData: userData,
      fullName: caretakerName,
      fallbackName: 'Caretaker',
      profileImageUrl: profileImageUrl,
      isDarkMode: isDarkMode,
      onToggleDarkMode: onToggleDarkMode,
      onNotificationTap: onNotificationTap,
      onProfileTap: onProfileTap,
      notificationCount: pendingRequestsCount,
      note: _note,
      noteTone: pendingRequestsCount > 0 ? NoteTone.attention : NoteTone.calm,
    );
  }
}
