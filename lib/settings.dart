import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';

/// App-wide settings (precision, number style, theme), saved between runs.
class AppSettings extends ChangeNotifier {
  int _precision = 4;
  PrecisionMode _mode = PrecisionMode.decimals;
  bool _trimZeros = true;
  bool _grouping = true;
  ThemeMode _themeMode = ThemeMode.system;
  SharedPreferences? _prefs;

  static const maxPrecision = 12;

  int get precision => _precision;
  PrecisionMode get mode => _mode;
  bool get trimZeros => _trimZeros;
  bool get grouping => _grouping;
  ThemeMode get themeMode => _themeMode;

  NumberStyle get style => NumberStyle(
        precision: _precision,
        mode: _mode,
        trimZeros: _trimZeros,
        grouping: _grouping,
      );

  int get minPrecision => _mode == PrecisionMode.significant ? 1 : 0;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      _precision = p.getInt('precision') ?? _precision;
      _mode = PrecisionMode.values[(p.getInt('mode') ?? 0).clamp(0, PrecisionMode.values.length - 1)];
      _trimZeros = p.getBool('trimZeros') ?? _trimZeros;
      _grouping = p.getBool('grouping') ?? _grouping;
      _themeMode = ThemeMode.values[(p.getInt('theme') ?? 0).clamp(0, ThemeMode.values.length - 1)];
      _precision = _precision.clamp(minPrecision, maxPrecision);
    } catch (_) {
      // Settings are a convenience; the app works fine with defaults.
    }
  }

  void setPrecision(int value) {
    _precision = value.clamp(minPrecision, maxPrecision);
    _prefs?.setInt('precision', _precision);
    notifyListeners();
  }

  void setMode(PrecisionMode value) {
    _mode = value;
    _prefs?.setInt('mode', value.index);
    if (_precision < minPrecision) _precision = minPrecision;
    notifyListeners();
  }

  void setTrimZeros(bool value) {
    _trimZeros = value;
    _prefs?.setBool('trimZeros', value);
    notifyListeners();
  }

  void setGrouping(bool value) {
    _grouping = value;
    _prefs?.setBool('grouping', value);
    notifyListeners();
  }

  void setThemeMode(ThemeMode value) {
    _themeMode = value;
    _prefs?.setInt('theme', value.index);
    notifyListeners();
  }
}
