import 'package:flutter_test/flutter_test.dart';
import 'package:unit_converter/converter.dart';
import 'package:unit_converter/data/categories.dart';
import 'package:unit_converter/format.dart';
import 'package:unit_converter/models.dart';

UnitCategory cat(String id) => categories.firstWhere((c) => c.id == id);

double conv(String category, String from, String to, double x) {
  final c = cat(category);
  return convert(c, c.unit(from), c.unit(to), x);
}

void expectClose(double actual, double expected, {double rel = 1e-9}) {
  final tol = expected.abs() * rel + 1e-12;
  expect((actual - expected).abs() <= tol, isTrue, reason: 'expected $expected, got $actual');
}

void main() {
  group('data integrity', () {
    test('every category has unique unit ids and valid defaults', () {
      for (final c in categories) {
        final ids = c.units.map((u) => u.id).toList();
        expect(ids.toSet().length, ids.length, reason: c.name);
        expect(ids, contains(c.defaultFrom));
        expect(ids, contains(c.defaultTo));
        expect(ids, contains(c.baseUnitId));
        if (c.kind == ConversionKind.linear) {
          expect(c.unit(c.baseUnitId).factor, 1.0, reason: '${c.name} base factor');
        }
      }
    });

    test('every pair has a formula and round-trips', () {
      for (final c in categories) {
        for (final a in c.units) {
          for (final b in c.units) {
            final f = formulaFor(c, a, b);
            expect(f.symbolic, isNotEmpty);
            final there = convert(c, a, b, 123.456);
            final back = convert(c, b, a, there);
            expectClose(back, 123.456, rel: 1e-9);
          }
        }
      }
    });
  });

  group('known values', () {
    test('length', () {
      expectClose(conv('length', 'mi', 'km', 1), 1.609344);
      expectClose(conv('length', 'ft', 'in', 1), 12);
      expectClose(conv('length', 'yd', 'ft', 1), 3);
      expectClose(conv('length', 'm', 'ft', 1), 3.280839895013123);
      expectClose(conv('length', 'mi', 'ft', 1), 5280);
    });

    test('area', () {
      expectClose(conv('area', 'ac', 'ft2', 1), 43560);
      expectClose(conv('area', 'mi2', 'ac', 1), 640);
      expectClose(conv('area', 'm2', 'ft2', 1), 10.763910416709722);
      expectClose(conv('area', 'ha', 'ac', 1), 2.471053814671653);
    });

    test('volume', () {
      expectClose(conv('volume', 'usgal', 'in3', 1), 231);
      expectClose(conv('volume', 'usgal', 'L', 1), 3.785411784);
      expectClose(conv('volume', 'ft3', 'usgal', 1), 7.480519480519481);
      expectClose(conv('volume', 'yd3', 'ft3', 1), 27);
      expectClose(conv('volume', 'ukgal', 'ukfloz', 1), 160);
    });

    test('mass', () {
      expectClose(conv('mass', 'lb', 'kg', 1), 0.45359237);
      expectClose(conv('mass', 'lb', 'oz', 1), 16);
      expectClose(conv('mass', 'shton', 'lb', 1), 2000);
      expectClose(conv('mass', 'slug', 'kg', 1), 14.593902937206364);
    });

    test('temperature', () {
      expectClose(conv('temperature', 'C', 'F', 100), 212);
      expectClose(conv('temperature', 'C', 'F', -40), -40);
      expectClose(conv('temperature', 'F', 'C', 32), 0);
      expectClose(conv('temperature', 'C', 'K', 0), 273.15);
      expectClose(conv('temperature', 'F', 'R', 0), 459.67);
      expectClose(conv('temperature', 'K', 'R', 100), 180);
      expectClose(conv('temperature', 'R', 'C', 491.67), 0);
    });

    test('speed', () {
      expectClose(conv('speed', 'mph', 'kmh', 60), 96.56064);
      expectClose(conv('speed', 'mps', 'kmh', 1), 3.6);
      expectClose(conv('speed', 'mph', 'fps', 60), 88);
    });

    test('pressure', () {
      expectClose(conv('pressure', 'psi', 'kPa', 1), 6.894757293168361);
      expectClose(conv('pressure', 'atm', 'psi', 1), 14.695948775513449);
      expectClose(conv('pressure', 'psi', 'psf', 1), 144);
      expectClose(conv('pressure', 'ksi', 'MPa', 1), 6.894757293168361);
    });

    test('force, energy, power, torque', () {
      expectClose(conv('force', 'lbf', 'N', 1), 4.4482216152605);
      expectClose(conv('force', 'kip', 'kN', 1), 4.4482216152605);
      expectClose(conv('energy', 'kWh', 'BTU', 1), 3412.141633127942);
      expectClose(conv('energy', 'ftlbf', 'J', 1), 1.3558179483314004);
      expectClose(conv('power', 'hp', 'W', 1), 745.6998715822702);
      expectClose(conv('power', 'TR', 'BTUh', 1), 12000);
      expectClose(conv('torque', 'lbfft', 'lbfin', 1), 12);
    });

    test('density and flow', () {
      expectClose(conv('density', 'gcm3', 'kgm3', 1), 1000);
      expectClose(conv('density', 'lbft3', 'kgm3', 1), 16.018463373960138);
      expectClose(conv('flow', 'cfs', 'cfm', 1), 60);
      expectClose(conv('flow', 'Ls', 'gpm', 1), 15.850323141488904);
    });
  });

  group('formulas', () {
    String formula(String c, String a, String b) {
      final cc = cat(c);
      return formulaFor(cc, cc.unit(a), cc.unit(b)).symbolic;
    }

    test('picks the clean form', () {
      expect(formula('length', 'm', 'ft'), 'ft = m ÷ 0.3048');
      expect(formula('length', 'ft', 'm'), 'm = ft × 0.3048');
      expect(formula('length', 'm', 'km'), 'km = m ÷ 1,000');
      expect(formula('length', 'ft', 'in'), 'in = ft × 12');
      expect(formula('length', 'in', 'ft'), 'ft = in ÷ 12');
      expect(formula('length', 'mi', 'km'), 'km = mi × 1.609344');
      expect(formula('length', 'm', 'nm'), 'nm = m × 1,000,000,000');
      expect(formula('length', 'm', 'um'), 'µm = m × 1,000,000');
      expect(formula('length', 'mm', 'm'), 'm = mm ÷ 1,000');
      expect(formula('area', 'ft2', 'm2'), 'm² = ft² × 0.09290304');
      expect(formula('area', 'mi2', 'mm2'), 'mm² = mi² × (2.58998811 × 10¹²)');
    });

    test('temperature formulas', () {
      expect(formula('temperature', 'C', 'F'), '°F = °C × 9/5 + 32');
      expect(formula('temperature', 'F', 'C'), '°C = (°F − 32) × 5/9');
      expect(formula('temperature', 'C', 'K'), 'K = °C + 273.15');
    });

    test('substitution wraps negatives', () {
      final c = cat('temperature');
      final f = formulaFor(c, c.unit('C'), c.unit('F'));
      expect(f.substituted('−40'), '(−40) × 9/5 + 32');
    });
  });

  group('number formatting', () {
    const d4 = NumberStyle(precision: 4);
    test('decimals', () {
      expect(formatNumber(3.280839895, d4), '3.2808');
      expect(formatNumber(12.000000000000002, d4), '12');
      expect(formatNumber(1234567.891, d4), '1,234,567.891');
      expect(formatNumber(-40, d4), '−40');
      expect(formatNumber(0, d4), '0');
      expect(formatNumber(2, const NumberStyle(precision: 3, trimZeros: false)), '2.000');
      expect(formatNumber(1e-9, d4), '1 × 10⁻⁹');
    });

    test('significant figures', () {
      const s3 = NumberStyle(precision: 3, mode: PrecisionMode.significant);
      expect(formatNumber(3.280839895, s3), '3.28');
      expect(formatNumber(12345, s3), '12,300');
      expect(formatNumber(0.000123456, s3), '0.000123');
    });

    test('parse input', () {
      expect(parseInput('1,234.5'), 1234.5);
      expect(parseInput('−40'), -40);
      expect(parseInput('2.5e3'), 2500);
      expect(parseInput(''), isNull);
      expect(parseInput('abc'), isNull);
    });
  });

  group('feet–inches', () {
    const d2 = NumberStyle(precision: 2);
    test('0.36 m shows as 1 ft 2.17 in', () {
      final feet = conv('length', 'm', 'ftin', 0.36);
      expect(formatFeetInches(feet, d2), '1 ft 2.17 in');
    });

    test('fractions and rounding up to the next foot', () {
      expect(formatFeetInches(1 + 2.1875 / 12, const NumberStyle(inchFraction: 16)), '1 ft 2 3/16 in');
      expect(formatFeetInches(0.5 / 12, const NumberStyle(inchFraction: 16)), '0 ft 1/2 in');
      expect(formatFeetInches(5 + 11.999 / 12, d2), '6 ft 0 in');
      expect(formatFeetInches(-(1 + 6 / 12), d2), '−1 ft 6 in');
    });

    test('parsing', () {
      void p(String text, double feet) =>
          expectClose(parseFeetInches(text)!, feet, rel: 1e-12);
      p('1\' 2"', 1 + 2 / 12);
      p('1 ft 2 in', 1 + 2 / 12);
      p('1ft2in', 1 + 2 / 12);
      p('5\' 6-1/2"', 5 + 6.5 / 12);
      p('5 6', 5.5);
      p('1.5', 1.5);
      p('8"', 8 / 12);
      p('14 in', 14 / 12);
      p('3/4"', 0.75 / 12);
      p('1 ft 2.17 in', 1 + 2.17 / 12);
      p('1 ft 2 3/16 in', 1 + 2.1875 / 12);
      p('-2 ft', -2);
      expect(parseFeetInches('abc'), isNull);
      expect(parseFeetInches(''), isNull);
    });

    test('formulas', () {
      final c = cat('length');
      expect(formulaFor(c, c.unit('m'), c.unit('ftin')).lines,
          ['ft = m ÷ 0.3048', 'inches = (ft − whole feet) × 12']);
      expect(formulaFor(c, c.unit('ftin'), c.unit('m')).lines,
          ['ft = feet + inches ÷ 12', 'm = ft × 0.3048']);
      expect(formulaFor(c, c.unit('ftin'), c.unit('ft')).lines, ['ft = feet + inches ÷ 12']);
    });
  });

  test('plain numbers for copying / re-typing', () {
    expect(plainNumber('1,234.5'), '1234.5');
    expect(plainNumber('−6.2137 × 10⁻¹³'), '-6.2137e-13');
    expect(parseInput('6.2 × 10¹²'), 6.2e12);
  });
}
