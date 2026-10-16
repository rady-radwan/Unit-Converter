import 'format.dart';
import 'models.dart';

/// A formula such as "ft = m ÷ 0.3048".
///
/// [template] uses `{x}` for the input value, e.g. "{x} ÷ 0.3048" or
/// "{x} × 9/5 + 32".
class Formula {
  const Formula({
    required this.lhs,
    required this.template,
    required this.inputSymbol,
    this.before,
    this.after,
  });

  final String lhs;
  final String template;
  final String inputSymbol;

  /// Extra step shown before the main formula (feet–inches input).
  final String? before;

  /// Extra step shown after the main formula (feet–inches output).
  final String? after;

  /// Every line of the formula, in order, for display.
  List<String> get lines => [
        if (before != null) before!,
        if (!isIdentity || (before == null && after == null)) symbolic,
        if (after != null) after!,
      ];

  /// One-line version for the small cards.
  String get compact => lines.join('  →  ');

  /// Symbolic form: "ft = m ÷ 0.3048".
  String get symbolic => '$lhs = ${template.replaceAll('{x}', inputSymbol)}';

  /// Same formula with the typed number put in: "10 ÷ 0.3048".
  String substituted(String value) {
    final shown = value.startsWith('−') || value.startsWith('-') ? '($value)' : value;
    return template.replaceAll('{x}', shown);
  }

  bool get isIdentity => template == '{x}';
}

// ───────────────────────── Conversion ─────────────────────────

double convert(UnitCategory c, Unit from, Unit to, double x) {
  if (from.id == to.id) return x;
  return switch (c.kind) {
    ConversionKind.linear => x * from.factor / to.factor,
    ConversionKind.temperature => _fromKelvin(to.id, _toKelvin(from.id, x)),
  };
}

double _toKelvin(String id, double x) {
  switch (id) {
    case 'C':
      return x + 273.15;
    case 'F':
      return (x + 459.67) * 5 / 9;
    case 'R':
      return x * 5 / 9;
    default: // K
      return x;
  }
}

double _fromKelvin(String id, double k) {
  switch (id) {
    case 'C':
      return k - 273.15;
    case 'F':
      return k * 9 / 5 - 459.67;
    case 'R':
      return k * 9 / 5;
    default: // K
      return k;
  }
}

/// Returns the value in kelvin (temperature category only) — used to warn
/// about values below absolute zero.
double toKelvin(Unit from, double x) => _toKelvin(from.id, x);

// ─────────────────────────── Formulas ───────────────────────────

const Map<String, String> _temperatureTemplates = {
  'C>F': '{x} × 9/5 + 32',
  'F>C': '({x} − 32) × 5/9',
  'C>K': '{x} + 273.15',
  'K>C': '{x} − 273.15',
  'F>K': '({x} − 32) × 5/9 + 273.15',
  'K>F': '({x} − 273.15) × 9/5 + 32',
  'C>R': '({x} + 273.15) × 9/5',
  'R>C': '{x} × 5/9 − 273.15',
  'F>R': '{x} + 459.67',
  'R>F': '{x} − 459.67',
  'K>R': '{x} × 9/5',
  'R>K': '{x} × 5/9',
};

const _feetInchesIn = 'ft = feet + inches ÷ 12';
const _feetInchesOut = 'inches = (ft − whole feet) × 12';

Formula formulaFor(UnitCategory c, Unit from, Unit to) {
  if (from.feetInches || to.feetInches) {
    // Work in decimal feet, then add the split / join step.
    final foot = c.units.firstWhere((u) => u.id == 'ft');
    final f0 = from.feetInches ? foot : from;
    final t0 = to.feetInches ? foot : to;
    final base = formulaFor(c, f0, t0);
    if (from.feetInches && to.feetInches) {
      return Formula(lhs: 'ft-in', template: '{x}', inputSymbol: 'ft-in');
    }
    return Formula(
      lhs: base.lhs,
      template: base.template,
      inputSymbol: base.inputSymbol,
      before: from.feetInches ? _feetInchesIn : null,
      after: to.feetInches ? _feetInchesOut : null,
    );
  }
  String template;
  if (from.id == to.id) {
    template = '{x}';
  } else if (c.kind == ConversionKind.temperature) {
    template = _temperatureTemplates['${from.id}>${to.id}']!;
  } else {
    final ratio = from.factor / to.factor;
    if ((ratio - 1).abs() < 1e-12) {
      template = '{x}';
    } else {
      final times = formatFactor(ratio);
      final divide = formatFactor(1 / ratio);
      // Show whichever form uses the number with fewer significant digits.
      // e.g. m → ft:  "m ÷ 0.3048" instead of "m × 3.280839895".
      // On a tie, prefer the number that is ≥ 1 (m → km: "÷ 1,000",
      // m → µm: "× 1,000,000").
      final dt = significantDigits(times);
      final dd = significantDigits(divide);
      final useDivide = dd < dt || (dd == dt && ratio < 1);
      String wrap(String n) => n.contains('×') ? '($n)' : n;
      template = useDivide ? '{x} ÷ ${wrap(divide)}' : '{x} × ${wrap(times)}';
    }
  }
  return Formula(lhs: to.symbol, template: template, inputSymbol: from.symbol);
}

/// "1 ft = 0.3048 m" — the definition behind a linear conversion.
String? definitionLine(UnitCategory c, Unit from, Unit to) {
  if (c.kind != ConversionKind.linear || from.id == to.id) return null;
  if (from.feetInches || to.feetInches) {
    final foot = c.units.firstWhere((u) => u.id == 'ft');
    final f0 = from.feetInches ? foot : from;
    final t0 = to.feetInches ? foot : to;
    if (f0.id == t0.id) return '1 ft = 12 in';
    return definitionLine(c, f0, t0);
  }
  final a = formatFactor(from.factor / to.factor);
  final b = formatFactor(to.factor / from.factor);
  return '1 ${from.symbol} = $a ${to.symbol}   ·   1 ${to.symbol} = $b ${from.symbol}';
}
