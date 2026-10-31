import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/shared/widgets/vista_avatar.dart';
import 'package:seelai_app/themes/palette.dart';

enum NoteTone { calm, attention }

/// A quiet status line from Vista: the mascot, one sentence, no animation.
/// Replaces the rotating typewriter speech bubbles. The message is fixed for
/// the life of the screen so screen readers announce it once.
class VistaNote extends StatelessWidget {
  final String message;
  final bool isDarkMode;
  final NoteTone tone;
  final String mascotAsset;
  final EdgeInsetsGeometry margin;

  const VistaNote({
    super.key,
    required this.message,
    required this.isDarkMode,
    this.tone = NoteTone.calm,
    this.mascotAsset = 'assets/vista-icons/vista0.webp',
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    final attention = tone == NoteTone.attention;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      container: true,
      liveRegion: false,
      label: message,
      excludeSemantics: true,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: BoxDecoration(
          color: attention
              ? (dark ? const Color(0xFF332A12) : Palette.warningTint)
              : Palette.card(dark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: attention ? Palette.signalDeep : Palette.border(dark),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              mascotAsset,
              width: 44,
              height: 44,
              cacheWidth: (44 * dpr).round(),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(width: 44),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Palette.text(dark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title block for a top-level tab: a large name, a short line of context,
/// and an optional action on the right.
class VistaTabTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDarkMode;
  final Widget? action;

  const VistaTabTitle({
    super.key,
    required this.title,
    this.subtitle,
    required this.isDarkMode,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.15,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w700,
                    color: Palette.text(isDarkMode),
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Palette.muted(isDarkMode),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

/// Round 48px icon button used in headers.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDarkMode;
  final int badge;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDarkMode,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    return Semantics(
      button: true,
      label: badge > 0 ? '$label, $badge new' : label,
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Palette.card(dark),
              shape: CircleBorder(
                side: BorderSide(color: Palette.border(dark)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: Icon(icon, size: 24, color: Palette.text(dark)),
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Palette.alert,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Palette.page(dark), width: 2),
                  ),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Home header shared by all roles: date and actions, then the greeting,
/// then one status note.
class VistaHomeHeader extends StatelessWidget {
  final String fullName;
  final String fallbackName;
  final String? profileImageUrl;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final int notificationCount;
  final String note;
  final NoteTone noteTone;

  const VistaHomeHeader({
    super.key,
    required this.fullName,
    required this.fallbackName,
    this.profileImageUrl,
    required this.isDarkMode,
    required this.onToggleDarkMode,
    this.onNotificationTap,
    this.onProfileTap,
    this.notificationCount = 0,
    required this.note,
    this.noteTone = NoteTone.calm,
  });

  static String firstName(String name, String fallback) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? fallback : parts.first;
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    final date = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final name = firstName(fullName, fallbackName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  date,
                  style: TextStyle(fontSize: 16, color: Palette.muted(dark)),
                ),
              ),
              HeaderIconButton(
                icon: dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: dark ? 'Switch to light mode' : 'Switch to dark mode',
                onTap: onToggleDarkMode,
                isDarkMode: dark,
              ),
              const SizedBox(width: 8),
              HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: onNotificationTap,
                isDarkMode: dark,
                badge: notificationCount,
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Your profile',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onProfileTap,
                  customBorder: const CircleBorder(),
                  child: VistaAvatar(
                    imageUrl: profileImageUrl,
                    name: fullName.isEmpty ? fallbackName : fullName,
                    isDarkMode: dark,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Semantics(
            header: true,
            child: Text(
              '${greeting()}, $name',
              style: TextStyle(
                fontSize: 30,
                height: 1.15,
                letterSpacing: -0.4,
                fontWeight: FontWeight.w700,
                color: Palette.text(dark),
              ),
            ),
          ),
        ),
        VistaNote(message: note, isDarkMode: dark, tone: noteTone),
      ],
    );
  }
}
