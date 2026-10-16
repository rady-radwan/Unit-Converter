import 'package:flutter/widgets.dart';

/// Which family a unit belongs to. Used to group units in the UI.
enum UnitSystem {
  metric('SI & Metric'),
  imperial('Imperial / US'),
  other('Other');

  const UnitSystem(this.label);
  final String label;
}

/// How values in a category are converted.
enum ConversionKind {
  /// value_in_base = value × factor (almost every category).
  linear,

  /// Offset scales (°C, °F, K, °R).
  temperature,
}

class Unit {
  const Unit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.system,
    this.factor = 1,
  });

  final String id;
  final String name;
  final String symbol;
  final UnitSystem system;

  /// How many base units one of this unit equals (linear categories only).
  final double factor;
}

class UnitCategory {
  const UnitCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.baseUnitId,
    required this.units,
    required this.defaultFrom,
    required this.defaultTo,
    this.kind = ConversionKind.linear,
    this.note,
  });

  final String id;
  final String name;
  final IconData icon;
  final String baseUnitId;
  final List<Unit> units;
  final String defaultFrom;
  final String defaultTo;
  final ConversionKind kind;

  /// Optional short note shown in the category (e.g. which gallon is used).
  final String? note;

  Unit unit(String id) => units.firstWhere((u) => u.id == id);

  List<Unit> unitsOf(UnitSystem system) =>
      units.where((u) => u.system == system).toList();
}
