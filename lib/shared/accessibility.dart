import 'package:flutter/material.dart';
import 'package:seelai_app/themes/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reading and seeing preferences, saved on the device and applied across the
/// whole app (see `MainApp`). Listen to [a11y] to rebuild when one changes.
class A11ySettings extends ChangeNotifier {
  A11ySettings._();
  static final A11ySettings instance = A11ySettings._();

  /// Text size steps offered in settings, with a name for each.
  static final textSteps = <double, String>{
    0.9: 'Small',
    1.0: 'Default',
    1.15: 'Large',
    1.3: 'Larger',
    1.5: 'Largest',
  };

  /// Reading-aloud speeds (flutter_tts rate) with a name for each.
  static final speechSteps = <double, String>{
    0.35: 'Slow',
    0.5: 'Normal',
    0.62: 'Fast',
  };

  double _textScale = 1.0;
  bool _boldText = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  double _speechRate = 0.5;

  double get textScale => _textScale;
  bool get boldText => _boldText;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  double get speechRate => _speechRate;

  static const _p = 'vista.a11y.';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _textScale = prefs.getDouble('${_p}textScale') ?? 1.0;
      _boldText = prefs.getBool('${_p}bold') ?? false;
      _highContrast = prefs.getBool('${_p}contrast') ?? false;
      _reduceMotion = prefs.getBool('${_p}motion') ?? false;
      _speechRate = prefs.getDouble('${_p}speech') ?? 0.5;
    } catch (_) {
      // Preferences unavailable: keep the defaults.
    }
    Palette.highContrast = _highContrast;
  }

  Future<void> _save(void Function(SharedPreferences p) write) async {
    notifyListeners();
    try {
      write(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  set textScale(double v) {
    _textScale = v;
    _save((p) => p.setDouble('${_p}textScale', v));
  }

  set boldText(bool v) {
    _boldText = v;
    _save((p) => p.setBool('${_p}bold', v));
  }

  set highContrast(bool v) {
    _highContrast = v;
    Palette.highContrast = v;
    _save((p) => p.setBool('${_p}contrast', v));
  }

  set reduceMotion(bool v) {
    _reduceMotion = v;
    _save((p) => p.setBool('${_p}motion', v));
  }

  set speechRate(double v) {
    _speechRate = v;
    _save((p) => p.setDouble('${_p}speech', v));
  }

  /// Applies these preferences on top of the device's own settings.
  MediaQueryData apply(MediaQueryData m) {
    final device = m.textScaler.scale(16) / 16;
    return m.copyWith(
      // The app setting multiplies the phone's, capped so layouts hold.
      textScaler: TextScaler.linear((device * _textScale).clamp(0.85, 2.0)),
      boldText: m.boldText || _boldText,
      highContrast: m.highContrast || _highContrast,
      disableAnimations: m.disableAnimations || _reduceMotion,
    );
  }
}

final A11ySettings a11y = A11ySettings.instance;
