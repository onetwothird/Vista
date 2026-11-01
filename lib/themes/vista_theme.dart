import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seelai_app/themes/constants.dart';

/// One dark-mode switch for the whole app, remembered between launches.
///
/// Screens that still take an `isDarkMode` flag read [ThemeController.isDark];
/// the home shells listen to it and pass the value down.
class ThemeController extends ValueNotifier<bool> {
  ThemeController._() : super(false);
  static final ThemeController instance = ThemeController._();

  static const _key = 'seelai.darkMode';

  bool get isDark => value;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_key);
      value =
          saved ??
          SchedulerBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
    } catch (_) {
      // Preferences unavailable: keep the default.
    }
  }

  Future<void> toggle() => set(!value);

  Future<void> set(bool dark) async {
    value = dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, dark);
    } catch (_) {}
  }
}

final themeController = ThemeController.instance;

abstract final class VistaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final page = Palette.page(dark);
    final card = Palette.card(dark);
    final text = Palette.text(dark);
    final muted = Palette.muted(dark);
    final border = Palette.border(dark);
    final brand = Palette.brand(dark);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: dark ? Palette.ink : Colors.white,
      primaryContainer: dark ? Palette.violetTintNight : Palette.violetTint,
      onPrimaryContainer: dark ? Palette.nightText : Palette.violetDeep,
      secondary: Palette.signal,
      onSecondary: Palette.onSignal,
      tertiary: dark ? Palette.infoNight : Palette.info,
      onTertiary: dark ? Palette.ink : Colors.white,
      error: Palette.danger(dark),
      onError: dark ? Palette.ink : Colors.white,
      errorContainer: dark ? const Color(0xFF3A1A18) : Palette.alertTint,
      onErrorContainer: dark ? Palette.alertNight : Palette.alert,
      surface: card,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerLowest: page,
      surfaceContainerLow: page,
      surfaceContainer: card,
      surfaceContainerHigh: Palette.raised(dark),
      surfaceContainerHighest: Palette.raised(dark),
      outline: dark ? Palette.nightMuted : Palette.lineStrong,
      outlineVariant: border,
      shadow: Palette.ink,
      scrim: Colors.black54,
      inverseSurface: dark ? Palette.nightText : Palette.ink,
      onInverseSurface: dark ? Palette.ink : Palette.nightText,
      inversePrimary: dark ? Palette.violet : Palette.lilac,
      surfaceTint: Colors.transparent,
    );

    TextStyle t(double size, FontWeight w, {double h = 1.4, Color? c}) =>
        TextStyle(
          fontFamily: vistaFont,
          fontSize: size,
          fontWeight: w,
          height: h,
          color: c ?? text,
        );

    final textTheme = TextTheme(
      displayLarge: t(48, FontWeight.w700, h: 1.1),
      displayMedium: t(36, FontWeight.w700, h: 1.15),
      displaySmall: t(30, FontWeight.w700, h: 1.2),
      headlineLarge: t(30, FontWeight.w700, h: 1.2),
      headlineMedium: t(24, FontWeight.w700, h: 1.25),
      headlineSmall: t(21, FontWeight.w700, h: 1.3),
      titleLarge: t(21, FontWeight.w700, h: 1.3),
      titleMedium: t(18, FontWeight.w700, h: 1.35),
      titleSmall: t(16, FontWeight.w700, h: 1.4),
      bodyLarge: t(18, FontWeight.w400, h: 1.5),
      bodyMedium: t(16, FontWeight.w400, h: 1.5),
      bodySmall: t(14, FontWeight.w400, h: 1.45, c: muted),
      labelLarge: t(16, FontWeight.w700, h: 1.2),
      labelMedium: t(14, FontWeight.w700, h: 1.2),
      labelSmall: t(13, FontWeight.w700, h: 1.2),
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const buttonSize = Size(64, 56);
    final buttonText = textTheme.labelLarge!;

    OutlineInputBorder outline(Color c, [double w = 1.5]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: vistaFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: page,
      canvasColor: page,
      cardColor: card,
      dividerColor: border,
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      focusColor: Palette.signal.withValues(alpha: 0.35),
      iconTheme: IconThemeData(color: text, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: page,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Navy by day, honey by night: the strongest pairing either way.
          backgroundColor: dark ? Palette.honey : Palette.violet,
          foregroundColor: dark ? Palette.violetDeep : Colors.white,
          disabledBackgroundColor: Palette.raised(dark),
          disabledForegroundColor: muted,
          elevation: 0,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark ? Palette.honey : Palette.violet,
          foregroundColor: dark ? Palette.violetDeep : Colors.white,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: dark ? Palette.nightMuted : Palette.inkSoft),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          minimumSize: const Size(48, 48),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? Palette.honey : Palette.violet,
        foregroundColor: dark ? Palette.violetDeep : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        highlightElevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: dark ? Palette.nightMuted : Palette.inkSubtle,
        ),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: brand),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: outline(border),
        enabledBorder: outline(border),
        focusedBorder: outline(brand, 2),
        errorBorder: outline(Palette.danger(dark)),
        focusedErrorBorder: outline(Palette.danger(dark), 2),
        disabledBorder: outline(border.withValues(alpha: 0.5)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? brand : Palette.raised(dark),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brand : scheme.outline,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: Palette.raised(dark),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXLarge),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? Palette.nightText : Palette.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: dark ? Palette.ink : Palette.nightText,
        ),
        actionTextColor: Palette.signal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: text,
        minTileHeight: 56,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: text,
        unselectedLabelColor: muted,
        indicatorColor: brand,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        dividerColor: border,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? Palette.nightText : Palette.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: dark ? Palette.ink : Palette.nightText,
          fontSize: 14,
        ),
      ),
    );
  }
}
