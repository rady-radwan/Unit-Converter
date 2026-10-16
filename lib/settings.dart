import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';

/// What size the Windows app opens at.
enum WindowStartMode { rememberLast, myDefault }

/// App-wide settings, saved between runs.
class AppSettings extends ChangeNotifier {
  // Numbers
  int _precision = 4;
  PrecisionMode _mode = PrecisionMode.decimals;
  bool _trimZeros = true;
  bool _grouping = true;
  int _inchFraction = 0;

  // Appearance
  ThemeMode _themeMode = ThemeMode.system;
  String? _fontFamily; // null = system default
  bool _autoScale = true;
  double _zoom = 1.0;

  // Window (Windows only)
  WindowStartMode _windowMode = WindowStartMode.rememberLast;
  Size _defaultSize = const Size(1280, 820);
  bool _startMaximized = false;
  Size? _lastSize;
  bool _lastMaximized = false;

  SharedPreferences? _prefs;

  static const maxPrecision = 12;
  static const minZoom = 0.6;
  static const maxZoom = 2.0;

  int get precision => _precision;
  PrecisionMode get mode => _mode;
  bool get trimZeros => _trimZeros;
  bool get grouping => _grouping;
  int get inchFraction => _inchFraction;
  ThemeMode get themeMode => _themeMode;
  String? get fontFamily => _fontFamily;
  bool get autoScale => _autoScale;
  double get zoom => _zoom;
  WindowStartMode get windowMode => _windowMode;
  Size get defaultSize => _defaultSize;
  bool get startMaximized => _startMaximized;
  Size? get lastSize => _lastSize;
  bool get lastMaximized => _lastMaximized;

  /// Size and maximized state to use when the app starts.
  Size get startupSize => _windowMode == WindowStartMode.myDefault
      ? _defaultSize
      : (_lastSize ?? _defaultSize);
  bool get startupMaximized =>
      _windowMode == WindowStartMode.myDefault ? _startMaximized : _lastMaximized;

  NumberStyle get style => NumberStyle(
        precision: _precision,
        mode: _mode,
        trimZeros: _trimZeros,
        grouping: _grouping,
        inchFraction: _inchFraction,
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
      _inchFraction = p.getInt('inchFraction') ?? _inchFraction;
      _themeMode = ThemeMode.values[(p.getInt('theme') ?? 0).clamp(0, ThemeMode.values.length - 1)];
      _fontFamily = p.getString('fontFamily');
      _autoScale = p.getBool('autoScale') ?? _autoScale;
      _zoom = (p.getDouble('zoom') ?? _zoom).clamp(minZoom, maxZoom);
      _windowMode = WindowStartMode.values[(p.getInt('windowMode') ?? 0).clamp(0, WindowStartMode.values.length - 1)];
      final dw = p.getDouble('defaultW'), dh = p.getDouble('defaultH');
      if (dw != null && dh != null) _defaultSize = Size(dw, dh);
      _startMaximized = p.getBool('startMaximized') ?? _startMaximized;
      final lw = p.getDouble('lastW'), lh = p.getDouble('lastH');
      if (lw != null && lh != null) _lastSize = Size(lw, lh);
      _lastMaximized = p.getBool('lastMaximized') ?? false;
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

  void setInchFraction(int value) {
    _inchFraction = value;
    _prefs?.setInt('inchFraction', value);
    notifyListeners();
  }

  void setThemeMode(ThemeMode value) {
    _themeMode = value;
    _prefs?.setInt('theme', value.index);
    notifyListeners();
  }

  void setFontFamily(String? value) {
    _fontFamily = value;
    if (value == null) {
      _prefs?.remove('fontFamily');
    } else {
      _prefs?.setString('fontFamily', value);
    }
    notifyListeners();
  }

  void setAutoScale(bool value) {
    _autoScale = value;
    _prefs?.setBool('autoScale', value);
    notifyListeners();
  }

  void setZoom(double value) {
    _zoom = (value * 20).roundToDouble() / 20; // 5 % steps
    _zoom = _zoom.clamp(minZoom, maxZoom);
    _prefs?.setDouble('zoom', _zoom);
    notifyListeners();
  }

  void zoomIn() => setZoom(_zoom + 0.1);
  void zoomOut() => setZoom(_zoom - 0.1);
  void zoomReset() => setZoom(1.0);

  void setWindowMode(WindowStartMode value) {
    _windowMode = value;
    _prefs?.setInt('windowMode', value.index);
    notifyListeners();
  }

  void setDefaultSize(Size value) {
    _defaultSize = Size(value.width.roundToDouble(), value.height.roundToDouble());
    _prefs?.setDouble('defaultW', _defaultSize.width);
    _prefs?.setDouble('defaultH', _defaultSize.height);
    notifyListeners();
  }

  void setStartMaximized(bool value) {
    _startMaximized = value;
    _prefs?.setBool('startMaximized', value);
    notifyListeners();
  }

  /// Called by the window watcher; saved silently (no rebuild needed).
  void rememberWindow({Size? size, required bool maximized}) {
    if (size != null && !maximized) {
      _lastSize = size;
      _prefs?.setDouble('lastW', size.width);
      _prefs?.setDouble('lastH', size.height);
    }
    _lastMaximized = maximized;
    _prefs?.setBool('lastMaximized', maximized);
  }
}
