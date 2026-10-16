import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'settings.dart';

/// True when running as the Windows desktop app.
bool get isWindowsDesktop => !kIsWeb && Platform.isWindows;

/// Sizes the window from the saved settings before it is shown,
/// then keeps track of its size so it can be restored next time.
Future<void> initWindow(AppSettings settings) async {
  if (!isWindowsDesktop) return;
  try {
    await windowManager.ensureInitialized();
    final options = WindowOptions(
      size: settings.startupSize,
      minimumSize: const Size(560, 420),
      center: true,
      title: 'Unit Converter',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      if (settings.startupMaximized) await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.addListener(_WindowWatcher(settings));
  } catch (_) {
    // If anything goes wrong, make sure the window is still visible.
    try {
      await windowManager.show();
    } catch (_) {}
  }
}

/// Current outer window size (for "use current size as default").
Future<Size?> currentWindowSize() async {
  if (!isWindowsDesktop) return null;
  try {
    return await windowManager.getSize();
  } catch (_) {
    return null;
  }
}

/// Resizes the window right now (used by the size presets).
Future<void> applyWindowSize(Size size) async {
  if (!isWindowsDesktop) return;
  try {
    if (await windowManager.isMaximized()) await windowManager.unmaximize();
    await windowManager.setSize(size);
    await windowManager.center();
  } catch (_) {}
}

class _WindowWatcher extends WindowListener {
  _WindowWatcher(this.settings);

  final AppSettings settings;
  Timer? _debounce;

  void _save() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final maximized = await windowManager.isMaximized();
        final size = maximized ? null : await windowManager.getSize();
        settings.rememberWindow(size: size, maximized: maximized);
      } catch (_) {}
    });
  }

  @override
  void onWindowResize() => _save();

  @override
  void onWindowResized() => _save();

  @override
  void onWindowMaximize() => _save();

  @override
  void onWindowUnmaximize() => _save();
}
