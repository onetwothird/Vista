import 'package:flutter/material.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/screens/video_call_screen.dart';
import 'package:seelai_app/roles/partially_sighted/home/sections/home_screen/communication/screens/voice_call_screen.dart';
import 'package:seelai_app/shared/widgets/vista_header.dart';
import 'package:seelai_app/themes/constants.dart';

/// One card for reaching your caretaker: who you will reach, then two big
/// side-by-side call buttons. Teal marks anything that connects you to
/// someone.
class QuickContactSection extends StatelessWidget {
  final bool isDarkMode;
  final dynamic theme;
  final Map<String, dynamic> userData;

  const QuickContactSection({
    super.key,
    required this.isDarkMode,
    required this.theme,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    final teal = dark ? Palette.tealBright : Palette.teal;
    final tealWash = dark ? const Color(0xFF173B3A) : Palette.tealTint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VistaSectionTitle(
          title: 'Call your caretaker',
          subtitle: 'They pick up on their phone',
          isDarkMode: dark,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Palette.card(dark),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.border(dark)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _CallButton(
                  label: 'Voice call',
                  icon: Icons.call_rounded,
                  background: dark ? Palette.lilac : Palette.violet,
                  foreground: dark ? Palette.violetDeep : Colors.white,
                  onTap: () => VoiceCallScreen.startCall(context, userData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CallButton(
                  label: 'Video call',
                  icon: Icons.videocam_rounded,
                  background: tealWash,
                  foreground: teal,
                  onTap: () => VideoCallScreen.startCall(context, userData),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tall call button: icon on top, label below, easy to hit.
class _CallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _CallButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label your caretaker',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 30, color: foreground),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
