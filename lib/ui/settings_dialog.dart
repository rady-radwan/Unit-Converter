import 'package:flutter/material.dart';

import '../main.dart';
import '../settings.dart';
import '../window_service.dart';

Future<void> showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

const _sizePresets = [
  Size(1024, 700),
  Size(1280, 820),
  Size(1440, 900),
  Size(1600, 1000),
  Size(1920, 1080),
];

String _sizeText(Size s) => '${s.width.round()} × ${s.height.round()}';

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
              child: Row(children: [
                Icon(Icons.settings_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('Settings', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ]),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─────────── Numbers ───────────
                    const _Header('Numbers', Icons.pin_outlined),
                    _Row(
                      label: 'Precision',
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        PrecisionDropdown(settings: s),
                        const SizedBox(width: 10),
                        PrecisionModeButton(settings: s),
                      ]),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hide trailing zeros'),
                      subtitle: const Text('2.5 instead of 2.5000'),
                      value: s.trimZeros,
                      onChanged: s.setTrimZeros,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Thousands separator'),
                      subtitle: const Text('1,000,000 instead of 1000000'),
                      value: s.grouping,
                      onChanged: s.setGrouping,
                    ),
                    _Row(
                      label: 'Feet–inches: show inches as',
                      child: DropdownButton<int>(
                        value: s.inchFraction,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(10),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Decimal  (2.17 in)')),
                          DropdownMenuItem(value: 2, child: Text('Nearest 1/2"')),
                          DropdownMenuItem(value: 4, child: Text('Nearest 1/4"')),
                          DropdownMenuItem(value: 8, child: Text('Nearest 1/8"')),
                          DropdownMenuItem(value: 16, child: Text('Nearest 1/16"')),
                          DropdownMenuItem(value: 32, child: Text('Nearest 1/32"')),
                          DropdownMenuItem(value: 64, child: Text('Nearest 1/64"')),
                        ],
                        onChanged: (v) => s.setInchFraction(v ?? 0),
                      ),
                    ),

                    // ─────────── Appearance ───────────
                    const _Header('Appearance', Icons.palette_outlined),
                    _Row(
                      label: 'Theme',
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('System')),
                          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ],
                        selected: {s.themeMode},
                        onSelectionChanged: (v) => s.setThemeMode(v.first),
                      ),
                    ),
                    _Row(label: 'Font', child: _FontPicker(settings: s)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Scale with window size'),
                      subtitle: const Text('Boxes and text grow and shrink as you resize the window'),
                      value: s.autoScale,
                      onChanged: s.setAutoScale,
                    ),
                    _Row(
                      label: 'Zoom  ${(s.zoom * 100).round()} %',
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                          width: 220,
                          child: Slider(
                            min: AppSettings.minZoom,
                            max: AppSettings.maxZoom,
                            divisions: ((AppSettings.maxZoom - AppSettings.minZoom) * 20).round(),
                            value: s.zoom,
                            label: '${(s.zoom * 100).round()} %',
                            onChanged: s.setZoom,
                          ),
                        ),
                        TextButton(onPressed: s.zoomReset, child: const Text('Reset')),
                      ]),
                    ),
                    Text('Tip: Ctrl + and Ctrl − zoom in and out, Ctrl 0 resets.',
                        style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),

                    // ─────────── Window ───────────
                    if (isWindowsDesktop) ...[
                      const _Header('Window size when the app opens', Icons.crop_free),
                      RadioListTile<WindowStartMode>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Same size as when I closed it'),
                        value: WindowStartMode.rememberLast,
                        groupValue: s.windowMode,
                        onChanged: (v) => s.setWindowMode(v!),
                      ),
                      RadioListTile<WindowStartMode>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Always my default size'),
                        subtitle: Text(s.startMaximized ? 'Maximized' : _sizeText(s.defaultSize)),
                        value: WindowStartMode.myDefault,
                        groupValue: s.windowMode,
                        onChanged: (v) => s.setWindowMode(v!),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.aspect_ratio, size: 18),
                              label: const Text('Use current window size'),
                              onPressed: () async {
                                final size = await currentWindowSize();
                                if (size == null) return;
                                s.setDefaultSize(size);
                                s.setStartMaximized(false);
                                s.setWindowMode(WindowStartMode.myDefault);
                              },
                            ),
                            PopupMenuButton<Size>(
                              tooltip: 'Pick a size',
                              onSelected: (size) {
                                s.setDefaultSize(size);
                                s.setStartMaximized(false);
                                s.setWindowMode(WindowStartMode.myDefault);
                                applyWindowSize(size);
                              },
                              itemBuilder: (_) => [
                                for (final p in _sizePresets)
                                  PopupMenuItem(value: p, child: Text(_sizeText(p))),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Text('Choose a size'),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, color: scheme.primary),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Open maximized'),
                        subtitle: const Text('Used with "Always my default size"'),
                        value: s.startMaximized,
                        onChanged: (v) {
                          s.setStartMaximized(v);
                          if (v) s.setWindowMode(WindowStartMode.myDefault);
                        },
                      ),
                    ],

                    // ─────────── About ───────────
                    const _Header('About', Icons.info_outline),
                    Text('Unit Converter 1.1.0 · SI and Imperial / US conversions with the formula '
                        'shown for every result.',
                        style: t.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                )),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [Text(label, style: Theme.of(context).textTheme.bodyLarge), child],
      ),
    );
  }
}

class _FontPicker extends StatelessWidget {
  const _FontPicker({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const systemValue = '__system__';
    final current = settings.fontFamily ?? systemValue;
    final known = {...bundledFonts, if (isWindowsDesktop) ...windowsFonts};
    final value = known.contains(current) ? current : systemValue;

    DropdownMenuItem<String> header(String text) => DropdownMenuItem(
          value: '__h_$text',
          enabled: false,
          child: Text(text.toUpperCase(),
              style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.primary)),
        );
    DropdownMenuItem<String> font(String f) => DropdownMenuItem(
          value: f,
          child: Text(f, style: TextStyle(fontFamily: f, fontSize: 15)),
        );

    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(10),
      menuMaxHeight: 420,
      items: [
        const DropdownMenuItem(value: systemValue, child: Text('System default')),
        header('Included fonts'),
        for (final f in bundledFonts) font(f),
        if (isWindowsDesktop) ...[
          header('Windows fonts'),
          for (final f in windowsFonts) font(f),
        ],
      ],
      onChanged: (v) {
        if (v == null || v.startsWith('__h_')) return;
        settings.setFontFamily(v == systemValue ? null : v);
      },
    );
  }
}
