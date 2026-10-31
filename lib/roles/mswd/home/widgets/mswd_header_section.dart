// File: lib/roles/mswd/home/widgets/mswd_header_section.dart

import 'package:flutter/material.dart';
import 'package:seelai_app/shared/widgets/vista_header.dart';

class HeaderSection extends StatelessWidget {
  final String adminName;
  final String? profileImageUrl;
  final bool isDarkMode;
  final int pendingRequestsCount;
  final VoidCallback onToggleDarkMode;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final Color textColor;
  final Color subtextColor;

  const HeaderSection({
    super.key,
    required this.adminName,
    this.profileImageUrl,
    required this.isDarkMode,
    required this.pendingRequestsCount,
    required this.onToggleDarkMode,
    this.onProfileTap,
    this.onNotificationTap,
    required this.textColor,
    required this.subtextColor,
  });

  String get _note {
    final p = pendingRequestsCount;
    if (p == 0) return 'No requests are waiting for approval.';
    return p == 1
        ? '1 request is waiting for approval.'
        : '$p requests are waiting for approval.';
  }

  @override
  Widget build(BuildContext context) {
    return VistaHomeHeader(
      fullName: adminName,
      fallbackName: 'Admin',
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
