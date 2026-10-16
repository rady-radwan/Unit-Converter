import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/categories.dart';
import 'format.dart';
import 'settings.dart';
import 'ui/category_page.dart';
import 'ui/settings_dialog.dart';
import 'window_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  await initWindow(settings);
  runApp(UnitConverterApp(settings: settings));
}

/// Makes [AppSettings] available to every widget below it.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

/// Fonts bundled with the app (work on Windows and Android).
const bundledFonts = [
  'Inter',
  'Roboto',
  'Open Sans',
  'Montserrat',
  'Lato',
  'Work Sans',
  'Josefin Sans',
];

/// Fonts that come with Windows.
const windowsFonts = [
  'Segoe UI',
  'Bahnschrift',
  'Calibri',
  'Arial',
  'Verdana',
  'Tahoma',
  'Trebuchet MS',
  'Georgia',
  'Cambria',
  'Times New Roman',
  'Consolas',
];

/// Design width the layout is drawn for; the window scales around it.
const designWidth = 1150.0;

const _seed = Color(0xFF0F6CBD);

ThemeData _theme(Brightness b, String? font) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: font,
    scaffoldBackgroundColor: b == Brightness.light ? const Color(0xFFF5F7FA) : null,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: scheme.surface,
    ),
  );
}

class UnitConverterApp extends StatelessWidget {
  const UnitConverterApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Unit Converter',
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light, settings.fontFamily),
          darkTheme: _theme(Brightness.dark, settings.fontFamily),
          themeMode: settings.themeMode,
          builder: (context, child) => _ScaledApp(settings: settings, child: child!),
          home: const HomePage(),
        ),
      ),
    );
  }
}

/// Scales the whole interface (boxes, text, menus) with the window size
/// and the zoom setting, and adds Ctrl + / Ctrl − / Ctrl 0 shortcuts.
class _ScaledApp extends StatelessWidget {
  const _ScaledApp({required this.settings, required this.child});

  final AppSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    var scale = settings.zoom;
    if (settings.autoScale && isWindowsDesktop) {
      scale *= (mq.size.width / designWidth).clamp(0.6, 2.2);
    }
    scale = scale.clamp(0.4, 4.0);

    Widget content = child;
    if ((scale - 1).abs() > 0.001) {
      final logical = Size(mq.size.width / scale, mq.size.height / scale);
      content = MediaQuery(
        data: mq.copyWith(
          size: logical,
          padding: mq.padding / scale,
          viewPadding: mq.viewPadding / scale,
          viewInsets: mq.viewInsets / scale,
        ),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.fill,
            alignment: Alignment.topLeft,
            child: SizedBox(width: logical.width, height: logical.height, child: child),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.equal, control: true): settings.zoomIn,
        const SingleActivator(LogicalKeyboardKey.add, control: true): settings.zoomIn,
        const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): settings.zoomIn,
        const SingleActivator(LogicalKeyboardKey.minus, control: true): settings.zoomOut,
        const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): settings.zoomOut,
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): settings.zoomReset,
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true): settings.zoomReset,
      },
      child: content,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 760;

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horizontal_circle, color: scheme.primary, size: 28),
              const SizedBox(width: 10),
              const Text('Unit Converter', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            if (wide) const PrecisionControls(),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => showSettingsDialog(context),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final c in categories)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 18),
                      const SizedBox(width: 8),
                      Text(c.name),
                    ],
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!wide)
              Material(
                color: scheme.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: PrecisionControls(),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [for (final c in categories) CategoryPage(category: c)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Precision [4 ▾]  [Decimals | Sig. figures]"
class PrecisionControls extends StatelessWidget {
  const PrecisionControls({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.tune, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        const Text('Precision'),
        const SizedBox(width: 8),
        PrecisionDropdown(settings: s),
        const SizedBox(width: 8),
        PrecisionModeButton(settings: s),
      ],
    );
  }
}

class PrecisionDropdown extends StatelessWidget {
  const PrecisionDropdown({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return Tooltip(
      message: s.mode == PrecisionMode.decimals
          ? 'Number of decimal places'
          : 'Number of significant figures',
      child: DropdownButton<int>(
        value: s.precision,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(10),
        items: [
          for (var i = s.minPrecision; i <= AppSettings.maxPrecision; i++)
            DropdownMenuItem(value: i, child: Text('$i')),
        ],
        onChanged: (v) => s.setPrecision(v ?? s.precision),
      ),
    );
  }
}

class PrecisionModeButton extends StatelessWidget {
  const PrecisionModeButton({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PrecisionMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final m in PrecisionMode.values) ButtonSegment(value: m, label: Text(m.label)),
      ],
      selected: {settings.mode},
      onSelectionChanged: (sel) => settings.setMode(sel.first),
    );
  }
}
