import 'dart:math' as math;

import 'models.dart';

enum PrecisionMode {
  decimals('Decimals'),
  significant('Sig. figures');

  const PrecisionMode(this.label);
  final String label;
}

class NumberStyle {
  const NumberStyle({
    this.precision = 4,
    this.mode = PrecisionMode.decimals,
    this.trimZeros = true,
    this.grouping = true,
    this.inchFraction = 0,
  });

  final int precision;
  final PrecisionMode mode;
  final bool trimZeros;
  final bool grouping;

  /// Feet–inches: 0 = decimal inches, otherwise round to 1/n inch (2…64).
  final int inchFraction;
}

const _superscripts = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻',
};

String _sup(int exponent) =>
    exponent.toString().split('').map((c) => _superscripts[c] ?? c).join();

String _trim(String s) {
  if (!s.contains('.')) return s;
  s = s.replaceFirst(RegExp(r'0+$'), '');
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}

String _group(String s) {
  var sign = '';
  if (s.startsWith('-')) {
    sign = '-';
    s = s.substring(1);
  }
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return sign + buf.toString() + (parts.length > 1 ? '.${parts[1]}' : '');
}

/// Uses a real minus sign (−) so negative numbers read nicely.
String _minus(String s) => s.startsWith('-') ? '−${s.substring(1)}' : s;

/// Scientific notation such as 6.2137 × 10⁻¹³.
String _scientific(double v, int mantissaDecimals, bool trim) {
  final raw = v.toStringAsExponential(mantissaDecimals.clamp(0, 20));
  final idx = raw.indexOf('e');
  var mantissa = raw.substring(0, idx);
  final exponent = int.parse(raw.substring(idx + 1));
  if (trim) mantissa = _trim(mantissa);
  if (exponent == 0) return _minus(mantissa);
  return '${_minus(mantissa)} × 10${_sup(exponent)}';
}

/// floor(log10(v)) that is safe for exact powers of ten (log10(1000) = 3).
int _exponent(double v) {
  var e = (math.log(v) / math.ln10).floor();
  if (math.pow(10, e + 1) <= v) e++;
  if (math.pow(10, e) > v) e--;
  return e;
}

/// Formats a converted value according to the user's precision settings.
String formatNumber(double v, NumberStyle style) {
  if (v.isNaN) return '—';
  if (v.isInfinite) return v > 0 ? '∞' : '−∞';
  final p = style.precision.clamp(0, 15);

  if (v == 0) {
    if (style.trimZeros || style.mode == PrecisionMode.significant || p == 0) {
      return '0';
    }
    return '0.${'0' * p}';
  }

  final abs = v.abs();
  String s;

  if (style.mode == PrecisionMode.decimals) {
    // Too big, or so small it would round to zero → scientific notation.
    if (abs >= 1e15 || abs < 0.5 * math.pow(10, -p)) {
      return _scientific(v, math.max(p, 3), style.trimZeros);
    }
    s = v.toStringAsFixed(p);
  } else {
    final sig = math.max(1, p);
    final rounded = double.parse(v.toStringAsPrecision(sig));
    final rAbs = rounded.abs();
    if (rAbs >= 1e15 || rAbs < 1e-6) {
      return _scientific(rounded, sig - 1, style.trimZeros);
    }
    final decimals = (sig - 1 - _exponent(rAbs)).clamp(0, 20);
    s = rounded.toStringAsFixed(decimals);
  }

  if (style.trimZeros) s = _trim(s);
  if (s == '-0') s = '0';
  if (style.grouping) s = _group(s);
  return _minus(s);
}

/// Compact form used inside formulas: up to 10 significant digits,
/// no trailing zeros, e.g. 0.3048, 3.280839895, 1,609.344.
String formatFactor(double v) {
  if (v == 0) return '0';
  final abs = v.abs();
  if (abs >= 1e12 || abs < 1e-6) {
    final sci = _scientific(v, 9, true);
    // "1 × 10⁻⁹" → "10⁻⁹"
    return sci.startsWith('1 × ') ? sci.substring(4) : sci;
  }
  final rounded = double.parse(v.toStringAsPrecision(10));
  final decimals = (9 - _exponent(rounded.abs())).clamp(0, 20);
  return _minus(_group(_trim(rounded.toStringAsFixed(decimals))));
}

/// How many significant digits a formatted factor has
/// ("0.3048" → 4, "1,000,000" → 1, "3.280839895" → 10).
int significantDigits(String formatted) {
  if (formatted.contains('10')) {
    // scientific forms count as long so plain numbers win
    if (formatted.contains('×') || RegExp(r'10[⁻⁰¹²³⁴⁵⁶⁷⁸⁹]').hasMatch(formatted)) return 99;
  }
  final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
  final core = digits.replaceFirst(RegExp(r'^0+'), '').replaceFirst(RegExp(r'0+$'), '');
  return core.isEmpty ? 1 : core.length;
}

const _fromSuperscript = {
  '⁰': '0', '¹': '1', '²': '2', '³': '3', '⁴': '4',
  '⁵': '5', '⁶': '6', '⁷': '7', '⁸': '8', '⁹': '9', '⁻': '-',
};

/// "1,234.5" → "1234.5",  "−6.2 × 10⁻¹³" → "-6.2e-13" (for copying and parsing).
String plainNumber(String shown) {
  var t = shown.trim().replaceAll(',', '').replaceAll('−', '-');
  final sci = RegExp(r'^(.*?)\s*×\s*10([⁻⁰¹²³⁴⁵⁶⁷⁸⁹]+)$').firstMatch(t);
  if (sci != null) {
    final exp = sci.group(2)!.split('').map((c) => _fromSuperscript[c] ?? c).join();
    final mantissa = sci.group(1)!.trim();
    t = '${mantissa.isEmpty ? '1' : mantissa}e$exp';
  }
  return t.replaceAll(' ', '');
}

/// Parses what the user typed. Accepts "1,234.5", "-40", "2.5e3", " 7 ".
double? parseInput(String text) {
  var t = plainNumber(text);
  if (t.isEmpty || t == '-' || t == '+' || t == '.') return null;
  return double.tryParse(t);
}

// ───────────────────────────── Feet–inches ─────────────────────────────

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// 1.1811 ft → "1 ft 2.17 in" (decimal) or "1 ft 2 3/16 in" (fractions).
String formatFeetInches(double feet, NumberStyle style) {
  if (feet.isNaN) return '—';
  if (feet.isInfinite) return feet > 0 ? '∞' : '−∞';
  final negative = feet < 0;
  final totalInches = feet.abs() * 12;
  var ft = (totalInches / 12).floor();
  var inches = totalInches - ft * 12;
  String inchText;

  if (style.inchFraction > 0) {
    final d = style.inchFraction;
    var n = (inches * d).round();
    if (n >= 12 * d) {
      ft += 1;
      n -= 12 * d;
    }
    final whole = n ~/ d;
    var top = n % d;
    var den = d;
    if (top == 0) {
      inchText = '$whole';
    } else {
      final g = _gcd(top, den);
      top ~/= g;
      den ~/= g;
      inchText = whole == 0 ? '$top/$den' : '$whole $top/$den';
    }
  } else {
    final p = style.precision.clamp(0, 10);
    var rounded = double.parse(inches.toStringAsFixed(p));
    if (rounded >= 12) {
      ft += 1;
      rounded -= 12;
      if (rounded < 0) rounded = 0;
    }
    inchText = formatNumber(
      rounded,
      NumberStyle(precision: p, trimZeros: style.trimZeros, grouping: false),
    );
  }

  final ftText = formatNumber(ft.toDouble(), NumberStyle(precision: 0, grouping: style.grouping));
  final zero = ft == 0 && (inchText == '0' || RegExp(r'^0(\.0+)?$').hasMatch(inchText));
  return '${negative && !zero ? '−' : ''}$ftText ft $inchText in';
}

final _feetMark = RegExp(r"(feet|foot|ft|'|’|′)", caseSensitive: false);
final _inchMark = RegExp(r'(inches|inch|in|"|”|″)', caseSensitive: false);

/// Inch text such as "6", "6.5", "6 1/2", "6-1/2", "1/2". Null if invalid.
double? _parseInches(String t) {
  t = t.trim();
  if (t.isEmpty) return 0;
  final mixed = RegExp(r'^(\d+(?:\.\d+)?)?[\s-]*(?:(\d+)\s*/\s*(\d+))?$').firstMatch(t);
  if (mixed == null) return null;
  final whole = mixed.group(1);
  final top = mixed.group(2);
  final den = mixed.group(3);
  if (whole == null && top == null) return null;
  var v = whole == null ? 0.0 : double.parse(whole);
  if (top != null && den != null) {
    final d = int.parse(den);
    if (d == 0) return null;
    v += int.parse(top) / d;
  }
  return v;
}

/// Parses feet–inches text and returns the length in FEET.
/// Accepts: 1' 2"  ·  1 ft 2 in  ·  1ft 2.5in  ·  5' 6-1/2"  ·  1 2 (ft in)
///          8"  ·  14 in (inches only)  ·  1.5 (decimal feet).
double? parseFeetInches(String text) {
  var t = text.trim().replaceAll(',', '').replaceAll('−', '-');
  if (t.isEmpty) return null;
  var sign = 1.0;
  if (t.startsWith('-')) {
    sign = -1;
    t = t.substring(1).trim();
  } else if (t.startsWith('+')) {
    t = t.substring(1).trim();
  }
  if (t.isEmpty) return null;

  String feetPart;
  String inchPart;
  final fm = _feetMark.firstMatch(t);
  if (fm != null) {
    feetPart = t.substring(0, fm.start).trim();
    inchPart = t.substring(fm.end).replaceAll(_inchMark, '').trim();
  } else if (_inchMark.hasMatch(t)) {
    feetPart = '';
    inchPart = t.replaceAll(_inchMark, '').trim();
  } else {
    final parts = t.split(RegExp(r'\s+'));
    feetPart = parts.first;
    inchPart = parts.skip(1).join(' ');
  }
  // allow "5'-6"" style separators
  inchPart = inchPart.replaceFirst(RegExp(r'^-\s*'), '');

  final feet = feetPart.isEmpty ? 0.0 : double.tryParse(feetPart);
  final inches = _parseInches(inchPart);
  if (feet == null || inches == null) return null;
  if (feetPart.isEmpty && inchPart.isEmpty) return null;
  return sign * (feet + inches / 12);
}

/// Formats a value for a given unit (handles feet–inches).
String formatValue(Unit unit, double v, NumberStyle style) =>
    unit.feetInches ? formatFeetInches(v, style) : formatNumber(v, style);

/// Parses text typed for a given unit (handles feet–inches).
double? parseValue(Unit unit, String text) =>
    unit.feetInches ? parseFeetInches(text) : parseInput(text);
