import 'package:flutter/material.dart';

/// Vista colour tokens, taken from the Vista pup: honey fur, midnight-navy
/// harness and teal goggle lenses. Gold on navy is the signature pairing:
/// it is the strongest, calmest contrast for low-vision readers.
///
/// Navy carries text and primary actions. Honey is the single accent
/// (the Scan button, the active page, a selected choice), never a large fill.
/// Teal marks anything live: location, calls, connection.
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
  static const lilac = Color(0xFFF2B13F); // honey, brand on dark surfaces
  static const violetTint = Color(0xFFE6ECF4); // navy wash
  static const violetTintNight = Color(0xFF243552);

  static const honey = Color(0xFFF2B13F); // fur
  static const honeyDeep = Color(0xFFD9951F); // fur shadow
  static const honeyTint = Color(0xFFFBF1DC); // small honey highlights only
  static const teal = Color(0xFF0F7F78); // goggles, 4.9:1 on white
  static const tealBright = Color(0xFF2EC4B6);
  static const tealTint = Color(0xFFDDF6F3);
  static const tongue = Color(0xFFE8606B);

  // Hero backdrop behind the pup: a pale wash of the harness navy, so the
  // illustrations' dark outlines and labels read without a card behind them.
  static const mist = Color(0xFFE8EEF5);
  static const mistDeep = Color(0xFFD9E2EE);

  static const signal = Color(0xFFF2B13F); // tactile-paving yellow
  static const signalDeep = Color(0xFFD9951F);
  static const onSignal = Color(0xFF13223A);

  // Day surfaces and ink
  static const paper = Color(0xFFF5F7FA);
  static const paperSunk = Color(0xFFEBEFF4);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFDFE5EC);
  static const lineStrong = Color(0xFFC3CCD7);
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

  /// Set from accessibility settings: secondary text and outlines get
  /// darker (or lighter at night) so everything reads clearly.
  static bool highContrast = false;

  // Resolvers for widgets that still take an `isDarkMode` flag.
  static Color page(bool dark) => dark ? nightPage : paper;
  static Color card(bool dark) => dark ? nightSurface : surface;
  static Color raised(bool dark) => dark ? nightRaised : paperSunk;
  static Color border(bool dark) =>
      highContrast ? (dark ? nightMuted : inkMuted) : (dark ? nightLine : line);
  static Color text(bool dark) => highContrast
      ? (dark ? Colors.white : Colors.black)
      : (dark ? nightText : ink);
  static Color muted(bool dark) => highContrast
      ? (dark ? nightText : inkSoft)
      : (dark ? nightMuted : inkMuted);
  static Color brand(bool dark) => dark ? lilac : violet;
  static Color danger(bool dark) => dark ? alertNight : alert;
}
