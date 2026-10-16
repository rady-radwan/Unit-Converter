import 'package:flutter/material.dart';

import '../models.dart';

// All factors are "how many base units one unit equals".
// Exact legal definitions are used where they exist
// (e.g. 1 in = 0.0254 m, 1 lb = 0.45359237 kg, 1 US gal = 231 in³).

const _m = UnitSystem.metric;
const _i = UnitSystem.imperial;
const _o = UnitSystem.other;

// Shared constants.
const double _inch = 0.0254;
const double _foot = 0.3048;
const double _yard = 0.9144;
const double _mile = 1609.344;
const double _pound = 0.45359237;
const double _usGallon = 0.003785411784; // 231 in³
const double _ukGallon = 0.00454609;
const double _cubicFoot = 0.028316846592;
const double _gravity = 9.80665; // standard gravity, m/s²
const double _poundForce = _pound * _gravity; // 4.4482216152605 N
const double _footPoundForce = _foot * _poundForce; // 1.3558179483314 J
const double _btu = 1055.05585262; // International Table BTU

final List<UnitCategory> categories = [
  // ───────────────────────────── Length ─────────────────────────────
  UnitCategory(
    id: 'length',
    name: 'Length',
    icon: Icons.straighten,
    baseUnitId: 'm',
    defaultFrom: 'm',
    defaultTo: 'ft',
    units: const [
      Unit(id: 'nm', name: 'Nanometer', symbol: 'nm', system: _m, factor: 1e-9),
      Unit(id: 'um', name: 'Micrometer', symbol: 'µm', system: _m, factor: 1e-6),
      Unit(id: 'mm', name: 'Millimeter', symbol: 'mm', system: _m, factor: 1e-3),
      Unit(id: 'cm', name: 'Centimeter', symbol: 'cm', system: _m, factor: 1e-2),
      Unit(id: 'm', name: 'Meter', symbol: 'm', system: _m, factor: 1),
      Unit(id: 'km', name: 'Kilometer', symbol: 'km', system: _m, factor: 1e3),
      Unit(id: 'mil', name: 'Mil (thou)', symbol: 'mil', system: _i, factor: _inch / 1000),
      Unit(id: 'in', name: 'Inch', symbol: 'in', system: _i, factor: _inch),
      Unit(id: 'ft', name: 'Foot', symbol: 'ft', system: _i, factor: _foot),
      Unit(id: 'yd', name: 'Yard', symbol: 'yd', system: _i, factor: _yard),
      Unit(id: 'mi', name: 'Mile', symbol: 'mi', system: _i, factor: _mile),
      Unit(id: 'nmi', name: 'Nautical mile', symbol: 'nmi', system: _o, factor: 1852),
    ],
  ),

  // ────────────────────────────── Area ──────────────────────────────
  UnitCategory(
    id: 'area',
    name: 'Area',
    icon: Icons.crop_square,
    baseUnitId: 'm2',
    defaultFrom: 'm2',
    defaultTo: 'ft2',
    units: const [
      Unit(id: 'mm2', name: 'Square millimeter', symbol: 'mm²', system: _m, factor: 1e-6),
      Unit(id: 'cm2', name: 'Square centimeter', symbol: 'cm²', system: _m, factor: 1e-4),
      Unit(id: 'm2', name: 'Square meter', symbol: 'm²', system: _m, factor: 1),
      Unit(id: 'ha', name: 'Hectare', symbol: 'ha', system: _m, factor: 1e4),
      Unit(id: 'km2', name: 'Square kilometer', symbol: 'km²', system: _m, factor: 1e6),
      Unit(id: 'in2', name: 'Square inch', symbol: 'in²', system: _i, factor: _inch * _inch),
      Unit(id: 'ft2', name: 'Square foot', symbol: 'ft²', system: _i, factor: _foot * _foot),
      Unit(id: 'yd2', name: 'Square yard', symbol: 'yd²', system: _i, factor: _yard * _yard),
      Unit(id: 'ac', name: 'Acre', symbol: 'ac', system: _i, factor: 4046.8564224),
      Unit(id: 'mi2', name: 'Square mile', symbol: 'mi²', system: _i, factor: _mile * _mile),
    ],
  ),

  // ───────────────────────────── Volume ─────────────────────────────
  UnitCategory(
    id: 'volume',
    name: 'Volume',
    icon: Icons.water_drop,
    baseUnitId: 'm3',
    defaultFrom: 'L',
    defaultTo: 'usgal',
    note: 'US = US customary units · UK = British imperial units',
    units: const [
      Unit(id: 'mL', name: 'Milliliter', symbol: 'mL', system: _m, factor: 1e-6),
      Unit(id: 'cm3', name: 'Cubic centimeter', symbol: 'cm³', system: _m, factor: 1e-6),
      Unit(id: 'L', name: 'Liter', symbol: 'L', system: _m, factor: 1e-3),
      Unit(id: 'm3', name: 'Cubic meter', symbol: 'm³', system: _m, factor: 1),
      Unit(id: 'in3', name: 'Cubic inch', symbol: 'in³', system: _i, factor: _inch * _inch * _inch),
      Unit(id: 'ft3', name: 'Cubic foot', symbol: 'ft³', system: _i, factor: _cubicFoot),
      Unit(id: 'yd3', name: 'Cubic yard', symbol: 'yd³', system: _i, factor: _yard * _yard * _yard),
      Unit(id: 'usfloz', name: 'Fluid ounce (US)', symbol: 'fl oz (US)', system: _i, factor: _usGallon / 128),
      Unit(id: 'uscup', name: 'Cup (US)', symbol: 'cup (US)', system: _i, factor: _usGallon / 16),
      Unit(id: 'uspt', name: 'Pint (US)', symbol: 'pt (US)', system: _i, factor: _usGallon / 8),
      Unit(id: 'usqt', name: 'Quart (US)', symbol: 'qt (US)', system: _i, factor: _usGallon / 4),
      Unit(id: 'usgal', name: 'Gallon (US)', symbol: 'gal (US)', system: _i, factor: _usGallon),
      Unit(id: 'ukfloz', name: 'Fluid ounce (UK)', symbol: 'fl oz (UK)', system: _i, factor: _ukGallon / 160),
      Unit(id: 'ukpt', name: 'Pint (UK)', symbol: 'pt (UK)', system: _i, factor: _ukGallon / 8),
      Unit(id: 'ukgal', name: 'Gallon (UK)', symbol: 'gal (UK)', system: _i, factor: _ukGallon),
    ],
  ),

  // ────────────────────────────── Mass ──────────────────────────────
  UnitCategory(
    id: 'mass',
    name: 'Mass',
    icon: Icons.scale,
    baseUnitId: 'kg',
    defaultFrom: 'kg',
    defaultTo: 'lb',
    units: const [
      Unit(id: 'mg', name: 'Milligram', symbol: 'mg', system: _m, factor: 1e-6),
      Unit(id: 'g', name: 'Gram', symbol: 'g', system: _m, factor: 1e-3),
      Unit(id: 'kg', name: 'Kilogram', symbol: 'kg', system: _m, factor: 1),
      Unit(id: 't', name: 'Metric ton (tonne)', symbol: 't', system: _m, factor: 1e3),
      Unit(id: 'gr', name: 'Grain', symbol: 'gr', system: _i, factor: _pound / 7000),
      Unit(id: 'oz', name: 'Ounce', symbol: 'oz', system: _i, factor: _pound / 16),
      Unit(id: 'lb', name: 'Pound', symbol: 'lb', system: _i, factor: _pound),
      Unit(id: 'st', name: 'Stone', symbol: 'st', system: _i, factor: _pound * 14),
      Unit(id: 'slug', name: 'Slug', symbol: 'slug', system: _i, factor: _poundForce / _foot),
      Unit(id: 'shton', name: 'Short ton (US)', symbol: 'ton (US)', system: _i, factor: _pound * 2000),
      Unit(id: 'lgton', name: 'Long ton (UK)', symbol: 'ton (UK)', system: _i, factor: _pound * 2240),
    ],
  ),

  // ─────────────────────────── Temperature ──────────────────────────
  UnitCategory(
    id: 'temperature',
    name: 'Temperature',
    icon: Icons.thermostat,
    baseUnitId: 'K',
    defaultFrom: 'C',
    defaultTo: 'F',
    kind: ConversionKind.temperature,
    units: const [
      Unit(id: 'C', name: 'Celsius', symbol: '°C', system: _m),
      Unit(id: 'K', name: 'Kelvin', symbol: 'K', system: _m),
      Unit(id: 'F', name: 'Fahrenheit', symbol: '°F', system: _i),
      Unit(id: 'R', name: 'Rankine', symbol: '°R', system: _i),
    ],
  ),

  // ────────────────────────────── Speed ─────────────────────────────
  UnitCategory(
    id: 'speed',
    name: 'Speed',
    icon: Icons.speed,
    baseUnitId: 'mps',
    defaultFrom: 'kmh',
    defaultTo: 'mph',
    units: const [
      Unit(id: 'mps', name: 'Meter per second', symbol: 'm/s', system: _m, factor: 1),
      Unit(id: 'kmh', name: 'Kilometer per hour', symbol: 'km/h', system: _m, factor: 1 / 3.6),
      Unit(id: 'ips', name: 'Inch per second', symbol: 'in/s', system: _i, factor: _inch),
      Unit(id: 'fpm', name: 'Foot per minute', symbol: 'ft/min', system: _i, factor: _foot / 60),
      Unit(id: 'fps', name: 'Foot per second', symbol: 'ft/s', system: _i, factor: _foot),
      Unit(id: 'mph', name: 'Mile per hour', symbol: 'mph', system: _i, factor: _mile / 3600),
      Unit(id: 'kn', name: 'Knot', symbol: 'kn', system: _o, factor: 1852 / 3600),
    ],
  ),

  // ────────────────────────────── Time ──────────────────────────────
  UnitCategory(
    id: 'time',
    name: 'Time',
    icon: Icons.schedule,
    baseUnitId: 's',
    defaultFrom: 'h',
    defaultTo: 'min',
    note: 'Month = 30.4375 days and year = 365.25 days (average values).',
    units: const [
      Unit(id: 'ms', name: 'Millisecond', symbol: 'ms', system: _m, factor: 1e-3),
      Unit(id: 's', name: 'Second', symbol: 's', system: _m, factor: 1),
      Unit(id: 'min', name: 'Minute', symbol: 'min', system: _o, factor: 60),
      Unit(id: 'h', name: 'Hour', symbol: 'h', system: _o, factor: 3600),
      Unit(id: 'd', name: 'Day', symbol: 'd', system: _o, factor: 86400),
      Unit(id: 'wk', name: 'Week', symbol: 'wk', system: _o, factor: 604800),
      Unit(id: 'mo', name: 'Month (avg.)', symbol: 'mo', system: _o, factor: 2629800),
      Unit(id: 'yr', name: 'Year (avg.)', symbol: 'yr', system: _o, factor: 31557600),
    ],
  ),

  // ──────────────────────────── Pressure ────────────────────────────
  UnitCategory(
    id: 'pressure',
    name: 'Pressure',
    icon: Icons.compress,
    baseUnitId: 'Pa',
    defaultFrom: 'kPa',
    defaultTo: 'psi',
    units: const [
      Unit(id: 'Pa', name: 'Pascal', symbol: 'Pa', system: _m, factor: 1),
      Unit(id: 'kPa', name: 'Kilopascal', symbol: 'kPa', system: _m, factor: 1e3),
      Unit(id: 'MPa', name: 'Megapascal', symbol: 'MPa', system: _m, factor: 1e6),
      Unit(id: 'mbar', name: 'Millibar', symbol: 'mbar', system: _m, factor: 100),
      Unit(id: 'bar', name: 'Bar', symbol: 'bar', system: _m, factor: 1e5),
      Unit(id: 'mmHg', name: 'Millimeter of mercury', symbol: 'mmHg', system: _m, factor: 133.322387415),
      Unit(id: 'psf', name: 'Pound per square foot', symbol: 'psf', system: _i, factor: _poundForce / (_foot * _foot)),
      Unit(id: 'psi', name: 'Pound per square inch', symbol: 'psi', system: _i, factor: _poundForce / (_inch * _inch)),
      Unit(id: 'ksi', name: 'Kip per square inch', symbol: 'ksi', system: _i, factor: 1000 * _poundForce / (_inch * _inch)),
      Unit(id: 'inH2O', name: 'Inch of water (4 °C)', symbol: 'inH₂O', system: _i, factor: 249.08891),
      Unit(id: 'inHg', name: 'Inch of mercury', symbol: 'inHg', system: _i, factor: 3386.389),
      Unit(id: 'atm', name: 'Standard atmosphere', symbol: 'atm', system: _o, factor: 101325),
    ],
  ),

  // ────────────────────────────── Force ─────────────────────────────
  UnitCategory(
    id: 'force',
    name: 'Force',
    icon: Icons.fitness_center,
    baseUnitId: 'N',
    defaultFrom: 'kN',
    defaultTo: 'kip',
    units: const [
      Unit(id: 'N', name: 'Newton', symbol: 'N', system: _m, factor: 1),
      Unit(id: 'kN', name: 'Kilonewton', symbol: 'kN', system: _m, factor: 1e3),
      Unit(id: 'MN', name: 'Meganewton', symbol: 'MN', system: _m, factor: 1e6),
      Unit(id: 'kgf', name: 'Kilogram-force', symbol: 'kgf', system: _m, factor: _gravity),
      Unit(id: 'ozf', name: 'Ounce-force', symbol: 'ozf', system: _i, factor: _poundForce / 16),
      Unit(id: 'lbf', name: 'Pound-force', symbol: 'lbf', system: _i, factor: _poundForce),
      Unit(id: 'kip', name: 'Kip (1000 lbf)', symbol: 'kip', system: _i, factor: 1000 * _poundForce),
      Unit(id: 'tonf', name: 'Short ton-force (US)', symbol: 'tonf', system: _i, factor: 2000 * _poundForce),
    ],
  ),

  // ───────────────────────────── Energy ─────────────────────────────
  UnitCategory(
    id: 'energy',
    name: 'Energy',
    icon: Icons.bolt,
    baseUnitId: 'J',
    defaultFrom: 'kWh',
    defaultTo: 'BTU',
    note: 'BTU = International Table BTU · cal = thermochemical calorie',
    units: const [
      Unit(id: 'J', name: 'Joule', symbol: 'J', system: _m, factor: 1),
      Unit(id: 'kJ', name: 'Kilojoule', symbol: 'kJ', system: _m, factor: 1e3),
      Unit(id: 'MJ', name: 'Megajoule', symbol: 'MJ', system: _m, factor: 1e6),
      Unit(id: 'Wh', name: 'Watt-hour', symbol: 'Wh', system: _m, factor: 3600),
      Unit(id: 'kWh', name: 'Kilowatt-hour', symbol: 'kWh', system: _m, factor: 3.6e6),
      Unit(id: 'cal', name: 'Calorie', symbol: 'cal', system: _m, factor: 4.184),
      Unit(id: 'kcal', name: 'Kilocalorie', symbol: 'kcal', system: _m, factor: 4184),
      Unit(id: 'ftlbf', name: 'Foot-pound', symbol: 'ft·lbf', system: _i, factor: _footPoundForce),
      Unit(id: 'BTU', name: 'British thermal unit', symbol: 'BTU', system: _i, factor: _btu),
      Unit(id: 'MBTU', name: 'Thousand BTU', symbol: 'MBtu', system: _i, factor: 1000 * _btu),
      Unit(id: 'therm', name: 'Therm', symbol: 'thm', system: _i, factor: 100000 * _btu),
    ],
  ),

  // ────────────────────────────── Power ─────────────────────────────
  UnitCategory(
    id: 'power',
    name: 'Power',
    icon: Icons.power,
    baseUnitId: 'W',
    defaultFrom: 'kW',
    defaultTo: 'hp',
    units: const [
      Unit(id: 'W', name: 'Watt', symbol: 'W', system: _m, factor: 1),
      Unit(id: 'kW', name: 'Kilowatt', symbol: 'kW', system: _m, factor: 1e3),
      Unit(id: 'MW', name: 'Megawatt', symbol: 'MW', system: _m, factor: 1e6),
      Unit(id: 'PS', name: 'Metric horsepower', symbol: 'PS', system: _m, factor: 75 * _gravity),
      Unit(id: 'ftlbfs', name: 'Foot-pound per second', symbol: 'ft·lbf/s', system: _i, factor: _footPoundForce),
      Unit(id: 'BTUh', name: 'BTU per hour', symbol: 'BTU/h', system: _i, factor: _btu / 3600),
      Unit(id: 'hp', name: 'Horsepower (mechanical)', symbol: 'hp', system: _i, factor: 550 * _footPoundForce),
      Unit(id: 'TR', name: 'Ton of refrigeration', symbol: 'TR', system: _i, factor: 12000 * _btu / 3600),
    ],
  ),

  // ───────────────────────────── Density ────────────────────────────
  UnitCategory(
    id: 'density',
    name: 'Density',
    icon: Icons.layers,
    baseUnitId: 'kgm3',
    defaultFrom: 'kgm3',
    defaultTo: 'lbft3',
    units: const [
      Unit(id: 'gL', name: 'Gram per liter', symbol: 'g/L', system: _m, factor: 1),
      Unit(id: 'kgm3', name: 'Kilogram per cubic meter', symbol: 'kg/m³', system: _m, factor: 1),
      Unit(id: 'kgL', name: 'Kilogram per liter', symbol: 'kg/L', system: _m, factor: 1000),
      Unit(id: 'gcm3', name: 'Gram per cubic centimeter', symbol: 'g/cm³', system: _m, factor: 1000),
      Unit(id: 'lbft3', name: 'Pound per cubic foot', symbol: 'lb/ft³', system: _i, factor: _pound / _cubicFoot),
      Unit(id: 'lbyd3', name: 'Pound per cubic yard', symbol: 'lb/yd³', system: _i, factor: _pound / (_yard * _yard * _yard)),
      Unit(id: 'lbgal', name: 'Pound per gallon (US)', symbol: 'lb/gal', system: _i, factor: _pound / _usGallon),
      Unit(id: 'lbin3', name: 'Pound per cubic inch', symbol: 'lb/in³', system: _i, factor: _pound / (_inch * _inch * _inch)),
    ],
  ),

  // ──────────────────────────── Flow rate ───────────────────────────
  UnitCategory(
    id: 'flow',
    name: 'Flow Rate',
    icon: Icons.waves,
    baseUnitId: 'm3s',
    defaultFrom: 'Ls',
    defaultTo: 'gpm',
    units: const [
      Unit(id: 'Lmin', name: 'Liter per minute', symbol: 'L/min', system: _m, factor: 1e-3 / 60),
      Unit(id: 'Ls', name: 'Liter per second', symbol: 'L/s', system: _m, factor: 1e-3),
      Unit(id: 'm3h', name: 'Cubic meter per hour', symbol: 'm³/h', system: _m, factor: 1 / 3600),
      Unit(id: 'm3s', name: 'Cubic meter per second', symbol: 'm³/s', system: _m, factor: 1),
      Unit(id: 'gpm', name: 'US gallon per minute', symbol: 'gpm', system: _i, factor: _usGallon / 60),
      Unit(id: 'ukgpm', name: 'UK gallon per minute', symbol: 'gpm (UK)', system: _i, factor: _ukGallon / 60),
      Unit(id: 'cfm', name: 'Cubic foot per minute', symbol: 'cfm', system: _i, factor: _cubicFoot / 60),
      Unit(id: 'cfs', name: 'Cubic foot per second', symbol: 'cfs', system: _i, factor: _cubicFoot),
    ],
  ),

  // ───────────────────────────── Torque ─────────────────────────────
  UnitCategory(
    id: 'torque',
    name: 'Torque',
    icon: Icons.rotate_right,
    baseUnitId: 'Nm',
    defaultFrom: 'Nm',
    defaultTo: 'lbfft',
    units: const [
      Unit(id: 'Nm', name: 'Newton-meter', symbol: 'N·m', system: _m, factor: 1),
      Unit(id: 'kNm', name: 'Kilonewton-meter', symbol: 'kN·m', system: _m, factor: 1e3),
      Unit(id: 'kgfm', name: 'Kilogram-force meter', symbol: 'kgf·m', system: _m, factor: _gravity),
      Unit(id: 'lbfin', name: 'Pound-force inch', symbol: 'lbf·in', system: _i, factor: _poundForce * _inch),
      Unit(id: 'lbfft', name: 'Pound-force foot', symbol: 'lbf·ft', system: _i, factor: _footPoundForce),
      Unit(id: 'kipft', name: 'Kip-foot', symbol: 'kip·ft', system: _i, factor: 1000 * _footPoundForce),
    ],
  ),
];
