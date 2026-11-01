import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:seelai_app/shared/nickname.dart';
import 'package:seelai_app/shared/widgets/vista_avatar.dart';
import 'package:seelai_app/shared/widgets/vista_mascot.dart';
import 'package:seelai_app/themes/palette.dart';

enum NoteTone { calm, attention }

/// Vista talking: a large pup with what it is saying in a chat bubble beside
/// it. Tap the pup and it hops and repeats itself. With [showMascot] off it
/// is a plain card (the home header, where the big pup already talks).
/// The message is fixed for the life of the screen so screen readers
/// announce it once.
class VistaNote extends StatefulWidget {
  final String message;
  final bool isDarkMode;
  final NoteTone tone;
  final String mascotAsset;
  final bool showMascot;
  final EdgeInsetsGeometry margin;

  /// Extra things the pup says when tapped, one per tap, before it goes back
  /// to [message].
  final List<String> tapLines;

  const VistaNote({
    super.key,
    required this.message,
    required this.isDarkMode,
    this.tone = NoteTone.calm,
    this.mascotAsset = 'assets/vista-icons/vista-welcome.png',
    this.showMascot = true,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
    this.tapLines = const [
      "I'm right here if you need me.",
      'Tap me any time!',
    ],
  });

  @override
  State<VistaNote> createState() => _VistaNoteState();
}

class _VistaNoteState extends State<VistaNote> {
  final _pup = GlobalKey<VistaMascotState>();
  String? _line;
  int _taps = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onPupTap() {
    _pup.currentState?.hop();
    final lines = [widget.message, ...widget.tapLines];
    _taps++;
    final next = lines[_taps % lines.length];
    _timer?.cancel();
    setState(() => _line = next == widget.message ? null : next);
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _line = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    final attention = widget.tone == NoteTone.attention;

    if (!widget.showMascot) {
      final fill = attention
          ? (dark ? const Color(0xFF332A12) : Palette.warningTint)
          : Palette.card(dark);
      return Semantics(
        container: true,
        label: widget.message,
        excludeSemantics: true,
        child: Container(
          margin: widget.margin,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: attention
                ? Border.all(color: Palette.signalDeep, width: 1.5)
                : null,
          ),
          child: Text(
            widget.message,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              color: Palette.text(dark),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: widget.margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            button: true,
            label: 'Vista the pup. Tap to talk.',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _onPupTap,
              behavior: HitTestBehavior.opaque,
              child: IgnorePointer(
                child: VistaMascot(
                  key: _pup,
                  pose: widget.mascotAsset,
                  size: 104,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VistaChatBubble(
                message: _line ?? widget.message,
                isDarkMode: dark,
                tone: _line == null ? widget.tone : NoteTone.calm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded chat bubble whose tail points left, toward the pup.
class _ChatBubblePainter extends CustomPainter {
  _ChatBubblePainter({
    required this.fill,
    required this.edge,
    required this.shadow,
  });

  final Color fill;
  final Color edge;
  final Color shadow;

  static const tail = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tail, 0, size.width - tail, size.height),
          const Radius.circular(22),
        ),
      );
    // A short curved tail near the bottom, pointing at the pup's face.
    final ty = math.max(size.height - 34, size.height * 0.5);
    final tailPath = Path()
      ..moveTo(tail + 14, ty - 8)
      ..cubicTo(tail + 2, ty - 6, tail - 2, ty + 2, 0, ty + 12)
      ..cubicTo(tail + 6, ty + 12, tail + 14, ty + 8, tail + 20, ty + 4)
      ..close();
    final path = Path.combine(PathOperation.union, body, tailPath);

    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(_ChatBubblePainter old) =>
      old.fill != fill || old.edge != edge || old.shadow != shadow;
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
              color: dark ? Palette.nightRaised : Colors.white,
              shape: const CircleBorder(),
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
                    border: Border.all(
                      color: dark ? Palette.nightSurface : Palette.mist,
                      width: 2,
                    ),
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

/// Home header shared by all roles: a pale navy band (the same wash as
/// onboarding) holding the date and actions, the greeting, then one status
/// note from the pup.
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

  /// The big pup beside the greeting. Waves by default; tap it to hear it.
  final String mascotPose;

  /// What the pup says on each tap. Defaults to a short greeting.
  final List<String>? mascotLines;

  /// The signed-in user's record. When given, the greeting uses their
  /// nickname and tapping it lets them change it.
  final Map<String, dynamic>? userData;

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
    this.mascotPose = MascotPose.welcome,
    this.mascotLines,
    this.userData,
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
    final name = Nickname.of(userData) ?? firstName(fullName, fallbackName);

    // Drawn edge to edge: the band runs up behind the status bar.
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? Palette.nightSurface : Palette.mist,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: CustomPaint(
        painter: _PawTrailPainter(dark: dark),
        child: Padding(
          padding: EdgeInsets.only(top: topInset, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Palette.muted(dark),
                        ),
                      ),
                    ),
                    HeaderIconButton(
                      icon: dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: dark
                          ? 'Switch to light mode'
                          : 'Switch to dark mode',
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: _Greeting(
                  userData: userData,
                  fallback: firstName(fullName, fallbackName),
                  dark: dark,
                ),
              ),
              _HomeTalk(
                pose: mascotPose,
                name: name,
                dark: dark,
                notificationCount: notificationCount,
                note: note,
                tone: noteTone,
                lines:
                    mascotLines ??
                    [
                      'Hi, $name!',
                      "I'm right here if you need me.",
                      'Have a lovely day!',
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The greeting with the nickname, for example "Good afternoon, Thirdy".
/// Tap it to change the nickname.
class _Greeting extends StatefulWidget {
  const _Greeting({
    required this.userData,
    required this.fallback,
    required this.dark,
  });

  final Map<String, dynamic>? userData;
  final String fallback;
  final bool dark;

  @override
  State<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<_Greeting> {
  @override
  Widget build(BuildContext context) {
    final shown = Nickname.of(widget.userData) ?? widget.fallback;
    final text = Text(
      '${VistaHomeHeader.greeting()},\n$shown',
      style: TextStyle(
        fontSize: 32,
        height: 1.15,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
        color: Palette.text(widget.dark),
      ),
    );
    final data = widget.userData;
    if (data == null) return Semantics(header: true, child: text);
    return Semantics(
      header: true,
      button: true,
      hint: 'Double tap to change your nickname',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final saved = await Nickname.edit(context, data);
          if (saved != null && mounted) setState(() {});
        },
        child: text,
      ),
    );
  }
}

/// A faint trail of paw prints across the home band. Static and low
/// contrast, so it reads as texture, never as content.
class _PawTrailPainter extends CustomPainter {
  _PawTrailPainter({required this.dark});

  final bool dark;

  // (x, y) as fractions of the band, rotation in radians, scale.
  static const _paws = [
    (0.06, 0.34, -0.5, 0.9),
    (0.17, 0.22, -0.2, 0.75),
    (0.29, 0.40, -0.6, 0.85),
    (0.40, 0.27, -0.3, 0.7),
    (0.52, 0.12, -0.4, 0.8),
    (0.95, 0.30, 0.3, 0.9),
    (0.86, 0.12, 0.5, 0.7),
    (0.05, 0.86, -0.2, 0.7),
    (0.48, 0.52, 0.2, 0.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? Colors.white : Palette.violet).withValues(
        alpha: dark ? 0.05 : 0.07,
      );
    for (final (fx, fy, angle, scale) in _paws) {
      canvas.save();
      canvas.translate(fx * size.width, fy * size.height);
      canvas.rotate(angle);
      canvas.scale(scale);
      // Main pad.
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 6), width: 20, height: 16),
        paint,
      );
      // Four toes.
      for (var i = 0; i < 4; i++) {
        final a = -math.pi / 2 + (i - 1.5) * 0.62;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(math.cos(a) * 15, math.sin(a) * 13 + 2),
            width: 8,
            height: 10,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PawTrailPainter old) => old.dark != dark;
}

/// Heading for a section on a home tab: one bold line, an optional line of
/// context, and an optional action on the right. Sections sit on the page,
/// not inside a card, so every home tab reads with the same rhythm.
class VistaSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDarkMode;
  final Widget? action;

  const VistaSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    required this.isDarkMode,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
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
                      fontSize: 21,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Palette.text(isDarkMode),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 15,
                      color: Palette.muted(isDarkMode),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// What Vista is saying, in a chat bubble whose tail points left at the pup.
/// When the message changes the bubble pops, so it reads as Vista speaking
/// again rather than text silently swapping.
class VistaChatBubble extends StatelessWidget {
  final String message;
  final bool isDarkMode;
  final NoteTone tone;

  const VistaChatBubble({
    super.key,
    required this.message,
    required this.isDarkMode,
    this.tone = NoteTone.calm,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode;
    final attention = tone == NoteTone.attention;
    final fill = attention
        ? (dark ? const Color(0xFF332A12) : Palette.warningTint)
        : Palette.card(dark);
    final edge = attention
        ? Palette.signalDeep
        : (dark ? Palette.border(dark) : Palette.line);
    final shadow = dark
        ? Colors.black.withValues(alpha: 0.35)
        : Palette.violet.withValues(alpha: 0.10);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.bottomLeft,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(message),
          tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(
            scale: 0.9 + 0.1 * v,
            alignment: Alignment.bottomLeft,
            child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
          ),
          child: CustomPaint(
            painter: _ChatBubblePainter(fill: fill, edge: edge, shadow: shadow),
            child: Padding(
              // Left inset leaves room for the tail.
              padding: const EdgeInsets.fromLTRB(
                _ChatBubblePainter.tail + 16,
                14,
                18,
                15,
              ),
              child: SizedBox(
                width: double.infinity,
                child: _Typewriter(
                  text: message,
                  instant: reduceMotion,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Palette.text(dark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Types [text] out a letter at a time. The untyped rest is laid out but
/// invisible, so the bubble keeps its final size and nothing reflows.
class _Typewriter extends StatelessWidget {
  const _Typewriter({
    required this.text,
    required this.style,
    this.instant = false,
  });

  final String text;
  final TextStyle style;
  final bool instant;

  static Duration lengthOf(String text) =>
      Duration(milliseconds: (text.length * 32).clamp(350, 2200));

  @override
  Widget build(BuildContext context) {
    if (instant) return Text(text, style: style);
    return TweenAnimationBuilder<int>(
      key: ValueKey(text),
      tween: IntTween(begin: 0, end: text.length),
      duration: lengthOf(text),
      builder: (context, n, _) => Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: text.substring(0, n)),
            TextSpan(
              text: text.substring(n),
              style: const TextStyle(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}

/// The big home pup and what it is saying. It greets you when the page
/// opens, then shows the status note. When something changes (your
/// nickname, light or dark mode, a new notification) or you tap it, it says
/// so in the bubble for a few seconds before going back to the note.
class _HomeTalk extends StatefulWidget {
  const _HomeTalk({
    required this.pose,
    required this.name,
    required this.dark,
    required this.notificationCount,
    required this.note,
    required this.tone,
    required this.lines,
  });

  final String pose;
  final String name;
  final bool dark;
  final int notificationCount;
  final String note;
  final NoteTone tone;
  final List<String> lines;

  @override
  State<_HomeTalk> createState() => _HomeTalkState();
}

class _HomeTalkState extends State<_HomeTalk>
    with SingleTickerProviderStateMixin {
  final _pup = GlobalKey<VistaMascotState>();
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  String? _line;
  Timer? _timer;
  int _taps = 0;

  @override
  void initState() {
    super.initState();
    _say('${VistaHomeHeader.greeting()}, ${widget.name}!', hop: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _burst.dispose();
    super.dispose();
  }

  void _say(String line, {bool hop = true}) {
    _timer?.cancel();
    setState(() => _line = line);
    if (hop) _pup.currentState?.hop();
    // Hold the line long enough to finish typing and be read.
    _timer = Timer(_Typewriter.lengthOf(line) + const Duration(seconds: 3), () {
      if (mounted) setState(() => _line = null);
    });
  }

  @override
  void didUpdateWidget(_HomeTalk old) {
    super.didUpdateWidget(old);
    final String? line;
    if (widget.name != old.name) {
      line = 'Nice to meet you, ${widget.name}!';
    } else if (widget.dark != old.dark) {
      line = widget.dark ? 'Lights off. Easy on the eyes!' : 'Lights on!';
    } else if (widget.notificationCount > old.notificationCount) {
      line = widget.notificationCount == 1
          ? 'You have a new update!'
          : 'You have ${widget.notificationCount} new updates!';
    } else {
      line = null;
    }
    if (line != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _say(line!);
      });
    }
  }

  void _onPupTap() {
    HapticFeedback.lightImpact();
    if (!MediaQuery.of(context).disableAnimations) _burst.forward(from: 0);
    if (widget.lines.isEmpty) return;
    _say(widget.lines[_taps++ % widget.lines.length]);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _onPupTap,
            child: SizedBox(
              width: 132,
              height: 140,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  // A soft ground shadow, so the pup stands on the page
                  // instead of sitting in a badge.
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 104,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: RadialGradient(
                          colors: [
                            (dark ? Colors.black : Palette.violet).withValues(
                              alpha: dark ? 0.45 : 0.16,
                            ),
                            (dark ? Colors.black : Palette.violet).withValues(
                              alpha: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    // The pup's own taps are handled here, so it gets no
                    // lines of its own and never shows a floating bubble.
                    child: IgnorePointer(
                      child: VistaMascot(
                        key: _pup,
                        pose: widget.pose,
                        size: 132,
                        semanticLabel: 'Vista the pup, waving.',
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _burst,
                        builder: (context, _) =>
                            _TapBurst(t: _burst.value, dark: dark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: VistaChatBubble(
                message: _line ?? widget.note,
                isDarkMode: dark,
                tone: _line == null ? widget.tone : NoteTone.calm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Little hearts and paw prints that pop out of the pup when it is tapped.
class _TapBurst extends StatelessWidget {
  const _TapBurst({required this.t, required this.dark});

  final double t;
  final bool dark;

  static const _angles = [-2.6, -2.15, -1.75, -1.4, -1.0, -0.55];

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final fly = Curves.easeOutCubic.transform(t);
    final fade = 1 - Curves.easeIn.transform(t);
    return LayoutBuilder(
      builder: (context, box) {
        final origin = Offset(box.maxWidth / 2, box.maxHeight * 0.38);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _angles.length; i++)
              Positioned(
                left: origin.dx + math.cos(_angles[i]) * (34 + 44 * fly) - 11,
                top:
                    origin.dy +
                    math.sin(_angles[i]) * (34 + 44 * fly) -
                    12 * fly -
                    11,
                child: Opacity(
                  opacity: fade,
                  child: Transform.scale(
                    scale: 0.5 + 0.7 * math.sin(fly * math.pi * 0.75),
                    child: Icon(
                      i.isEven ? Icons.favorite_rounded : Icons.pets_rounded,
                      size: 22,
                      color: i.isEven
                          ? Palette.tongue
                          : (dark ? Palette.honey : Palette.honeyDeep),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
