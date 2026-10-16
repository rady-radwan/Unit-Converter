# Unit Converter

A clean SI ⇄ Imperial / US unit converter for **Windows** (Android next), built with Flutter so both apps share one codebase.

## Features
- **14 categories, one tab each:** Length, Area, Volume, Mass, Temperature, Speed, Time, Pressure, Force, Energy, Power, Density, Flow Rate, Torque
- **Instant conversion** — results update as you type
- **Precision control** — 0–12 decimal places *or* significant figures
- **Formula under every conversion** (e.g. `ft = m ÷ 0.3048`, `°F = °C × 9/5 + 32`) plus the worked calculation
- **Every unit at once** — the “in every unit” grid shows the value in all SI and Imperial units; click a card to make it the target
- Swap button, copy buttons, thousands separator, hide-trailing-zeros, light/dark theme
- Exact legal definitions used (1 in = 25.4 mm, 1 lb = 0.45359237 kg, 1 US gal = 231 in³ …)

## Download
Go to **Releases** → download `UnitConverter-Setup-x.y.z.exe` and run it. No admin rights needed.
A portable `.zip` is also attached.

## How it is built
GitHub Actions (`.github/workflows/build-windows.yml`) runs the unit tests, builds the Windows app,
bundles the Visual C++ runtime, packages it with Inno Setup, and publishes the release `v<version>` from `pubspec.yaml`.
To ship a new version, bump `version:` in `pubspec.yaml` and push to `main`.

## Project layout
```
lib/
  data/categories.dart   all units and conversion factors
  converter.dart         conversion + formula generation
  format.dart            precision / number formatting
  settings.dart          saved preferences
  ui/category_page.dart  one tab
  main.dart              app shell, tabs, precision controls
test/converter_test.dart known-value checks for every category
installer/               Inno Setup script
```
