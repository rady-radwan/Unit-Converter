import 'package:flutter/material.dart';

import 'data/categories.dart';
import 'format.dart';
import 'settings.dart';
import 'ui/category_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  runApp(UnitConverterApp(settings: settings));
}

/// Makes [AppSettings] available to every widget below it.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

const _seed = Color(0xFF0F6CBD);

ThemeData _theme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: b);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
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
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: settings.themeMode,
          home: const HomePage(),
        ),
      ),
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
            const _SettingsMenu(),
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
        Tooltip(
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
        ),
        const SizedBox(width: 8),
        SegmentedButton<PrecisionMode>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            for (final m in PrecisionMode.values)
              ButtonSegment(value: m, label: Text(m.label)),
          ],
          selected: {s.mode},
          onSelectionChanged: (sel) => s.setMode(sel.first),
        ),
      ],
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu();

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
      onSelected: (v) {
        switch (v) {
          case 'trim':
            s.setTrimZeros(!s.trimZeros);
          case 'group':
            s.setGrouping(!s.grouping);
          case 'system':
            s.setThemeMode(ThemeMode.system);
          case 'light':
            s.setThemeMode(ThemeMode.light);
          case 'dark':
            s.setThemeMode(ThemeMode.dark);
          case 'about':
            showAboutDialog(
              context: context,
              applicationName: 'Unit Converter',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.swap_horizontal_circle, size: 40),
              children: const [
                Text('SI and Imperial / US unit conversions with the formula '
                    'shown for every result.'),
              ],
            );
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(value: 'trim', checked: s.trimZeros, child: const Text('Hide trailing zeros')),
        CheckedPopupMenuItem(value: 'group', checked: s.grouping, child: const Text('Thousands separator (1,000)')),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(value: 'system', checked: s.themeMode == ThemeMode.system, child: const Text('Theme: System')),
        CheckedPopupMenuItem(value: 'light', checked: s.themeMode == ThemeMode.light, child: const Text('Theme: Light')),
        CheckedPopupMenuItem(value: 'dark', checked: s.themeMode == ThemeMode.dark, child: const Text('Theme: Dark')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'about', child: Text('About')),
      ],
    );
  }
}
