import 'package:flutter/material.dart';

/// Vista colour tokens, taken from the Vista pup: honey fur, midnight-navy
/// harness and teal goggle lenses. Gold on navy is the signature pairing:
/// it is the strongest, calmest contrast for low-vision readers.
///
/// Tuned for partially sighted readers: text colours clear WCAG AAA (7:1) on
/// their surfaces, and pages are a soft warm white instead of pure white to
/// cut glare. Honey is for warm, low-strength backgrounds and highlights;
/// navy carries actions and brand text because it stays readable.
///
/// The `violet*` / `lilac` names are kept so existing screens keep compiling;
/// they now hold the pup's navy and honey.
abstract final class Palette {
  // Brand (from the pup)
  static const violet = Color(0xFF1B3157); // harness navy, 9:1 on white
  static const violetDeep = Color(0xFF13223A);
  static const lilac = Color(0xFFFFB938); // honey, brand on dark surfaces
  static const violetTint = Color(0xFFFFF1CF); // honey wash
  static const violetTintNight = Color(0xFF3A2F17);

  static const honey = Color(0xFFFFB938); // fur
  static const honeyDeep = Color(0xFFE89A12); // fur shadow
  static const honeyTint = Color(0xFFFFF6E0); // page wash behind the pup
  static const teal = Color(0xFF0F7F78); // goggles, 4.9:1 on white
  static const tealBright = Color(0xFF2EC4B6);
  static const tealTint = Color(0xFFDDF6F3);
  static const tongue = Color(0xFFE8606B);

  static const signal = Color(0xFFFFB938); // tactile-paving yellow
  static const signalDeep = Color(0xFFE89A12);
  static const onSignal = Color(0xFF13223A);

  // Day surfaces and ink
  static const paper = Color(0xFFF7F6F3);
  static const paperSunk = Color(0xFFEEECE7);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE3E0D8);
  static const lineStrong = Color(0xFFC9C4B8);
  static const ink = Color(0xFF13223A); // 15:1
  static const inkSoft = Color(0xFF2B3A52); // 10.5:1
  static const inkMuted = Color(0xFF4E5B6E); // 6.5:1
  static const inkSubtle = Color(0xFF6B7585); // 4.6:1, hints only

  // Night surfaces and ink
  static const nightPage = Color(0xFF0E1726);
  static const nightSurface = Color(0xFF16223A);
  static const nightRaised = Color(0xFF1E2D47);
  static const nightLine = Color(0xFF2C3D5A);
  static const nightText = Color(0xFFF3F5F8);
  static const nightMuted = Color(0xFFB3BDCB);

  // Meaning
  static const alert = Color(0xFFC2261F);
  static const alertNight = Color(0xFFFF8A80);
  static const alertTint = Color(0xFFFDE8E6);
  static const success = Color(0xFF1F7A4D);
  static const successNight = Color(0xFF6FD3A0);
  static const successTint = Color(0xFFE3F3EA);
  static const warning = Color(0xFFA86400);
  static const warningTint = Color(0xFFFFF3D6);
  static const info = Color(0xFF2F5FA8);
  static const infoNight = Color(0xFF8FB0EA);
  static const infoTint = Color(0xFFE5EDF8);

  // Resolvers for widgets that still take an `isDarkMode` flag.
  static Color page(bool dark) => dark ? nightPage : paper;
  static Color card(bool dark) => dark ? nightSurface : surface;
  static Color raised(bool dark) => dark ? nightRaised : paperSunk;
  static Color border(bool dark) => dark ? nightLine : line;
  static Color text(bool dark) => dark ? nightText : ink;
  static Color muted(bool dark) => dark ? nightMuted : inkMuted;
  static Color brand(bool dark) => dark ? lilac : violet;
  static Color danger(bool dark) => dark ? alertNight : alert;
}
