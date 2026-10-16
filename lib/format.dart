import 'dart:math' as math;

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
  });

  final int precision;
  final PrecisionMode mode;
  final bool trimZeros;
  final bool grouping;
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
  if (abs >= 1e12 || abs < 1e-6) return _scientific(v, 9, true);
  final rounded = double.parse(v.toStringAsPrecision(10));
  final decimals = (9 - _exponent(rounded.abs())).clamp(0, 20);
  return _minus(_group(_trim(rounded.toStringAsFixed(decimals))));
}

/// Parses what the user typed. Accepts "1,234.5", "-40", "2.5e3", " 7 ".
double? parseInput(String text) {
  var t = text.trim().replaceAll(',', '').replaceAll(' ', '');
  t = t.replaceAll('−', '-');
  if (t.isEmpty || t == '-' || t == '+' || t == '.') return null;
  return double.tryParse(t);
}
