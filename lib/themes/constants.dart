import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';

export 'package:seelai_app/themes/palette.dart';

// Legacy token names, re-pointed at the Vista palette so every screen that
// imports this file picks up the design system. Prefer `Palette` and
// `Theme.of(context)` in new code.

const primary = Palette.violet;
const primaryLight = Palette.lilac;
const primaryDark = Palette.violetDeep;
const modernPurpleLight = Palette.violetTint;
const secondary = Palette.violet;
const accent = Palette.violet;
const accentLight = Palette.violetTint;

const backgroundPrimary = Palette.paper;
const backgroundSecondary = Palette.paper;
const backgroundTertiary = Palette.paper;

const white = Colors.white;
const black = Palette.ink;
const grey = Palette.inkMuted;
const greyLight = Palette.inkSubtle;
const greyLighter = Palette.line;
const lightBlue = Palette.line;

const success = Palette.success;
const successLight = Palette.successTint;
const error = Palette.alert;
const errorLight = Palette.alertTint;
const warning = Palette.warning;
const info = Palette.info;

// Gradients are retired. These stay as flat fills so older call sites still
// compile and render as solid colour.
const primaryGradient = LinearGradient(
  colors: [Palette.violet, Palette.violet],
);
const accentGradient = LinearGradient(colors: [Palette.violet, Palette.violet]);
const softGradient = LinearGradient(colors: [Palette.paper, Palette.paper]);

// Type: Atkinson Hyperlegible (Braille Institute), two weights only.
// Scale follows the classic 14 / 16 / 18 / 21 / 24 / 36 progression.
const vistaFont = 'Atkinson';

const h1 = TextStyle(
  fontFamily: vistaFont,
  fontSize: 36,
  fontWeight: FontWeight.w700,
  color: black,
  letterSpacing: -0.6,
  height: 1.15,
);

const h2 = TextStyle(
  fontFamily: vistaFont,
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: black,
  letterSpacing: -0.3,
  height: 1.25,
);

const h3 = TextStyle(
  fontFamily: vistaFont,
  fontSize: 21,
  fontWeight: FontWeight.w700,
  color: black,
  letterSpacing: -0.2,
  height: 1.3,
);

const body = TextStyle(
  fontFamily: vistaFont,
  fontSize: 16,
  color: grey,
  height: 1.5,
  fontWeight: FontWeight.w400,
);

const bodyBold = TextStyle(
  fontFamily: vistaFont,
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: black,
  height: 1.5,
);

const TextStyle bodyText = TextStyle(
  fontFamily: vistaFont,
  fontSize: 16,
  fontWeight: FontWeight.w400,
);

const TextStyle caption = TextStyle(
  fontFamily: vistaFont,
  fontSize: 14,
  color: grey,
  fontWeight: FontWeight.w400,
  height: 1.4,
);

const small = TextStyle(
  fontFamily: vistaFont,
  fontSize: 14,
  color: grey,
  fontWeight: FontWeight.w400,
  height: 1.4,
);

// Depth comes from borders, not shadows. The few shadows left are tight and
// cheap to rasterise; only floating layers (nav bar, sheets) should use them.
const softShadow = <BoxShadow>[];
const cardShadow = <BoxShadow>[];

const mediumShadow = [
  BoxShadow(color: Color(0x141B1530), blurRadius: 8, offset: Offset(0, 2)),
];

const strongShadow = [
  BoxShadow(color: Color(0x1F1B1530), blurRadius: 16, offset: Offset(0, 4)),
];

const glowShadow = mediumShadow;

const Map<String, Color> darkTheme = {
  'background': Palette.nightPage,
  'primary': Palette.lilac,
  'text': Palette.nightText,
  'card': Palette.nightSurface,
};

const Map<String, Color> lightTheme = {
  'background': Palette.paper,
  'primary': Palette.violet,
  'text': Palette.ink,
  'card': Palette.surface,
};

// Radius encodes hierarchy: controls < cards < sheets.
const radiusSmall = 10.0;
const radiusMedium = 16.0;
const radiusLarge = 20.0;
const radiusXLarge = 24.0;
const radiusPill = 100.0;

const spacingXSmall = 4.0;
const spacingSmall = 8.0;
const spacingMedium = 16.0;
const spacingLarge = 24.0;
const spacingXLarge = 32.0;
const spacingXXLarge = 48.0;
