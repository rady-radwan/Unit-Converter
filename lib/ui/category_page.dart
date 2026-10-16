import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../converter.dart';
import '../format.dart';
import '../main.dart';
import '../models.dart';
import '../settings.dart';

const _mono = TextStyle(
  fontFamily: 'Consolas',
  fontFamilyFallback: ['Cascadia Mono', 'Roboto Mono', 'monospace'],
);

final _numberChars = RegExp(r'[0-9.,eE+\-− ×⁻⁰¹²³⁴⁵⁶⁷⁸⁹]');
final _feetInchChars = RegExp(r'''[0-9.,+\-− '’′"”″/a-zA-Z]''');

/// Style used when a value is re-typed for the user (full precision).
NumberStyle _exact(NumberStyle s) =>
    NumberStyle(precision: 10, mode: PrecisionMode.significant, grouping: s.grouping, inchFraction: 0);

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.category});

  final UnitCategory category;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with AutomaticKeepAliveClientMixin {
  final _fromCtrl = TextEditingController(text: '1');
  final _toCtrl = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  late String _fromId = widget.category.defaultFrom;
  late String _toId = widget.category.defaultTo;

  /// Which box the user typed in last. The other box is calculated.
  bool _sourceIsFrom = true;
  AppSettings? _settings;

  UnitCategory get c => widget.category;
  Unit get _from => c.unit(_fromId);
  Unit get _to => c.unit(_toId);

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = SettingsScope.of(context);
    if (!identical(s, _settings)) {
      _settings?.removeListener(_syncOther);
      _settings = s;
      s.addListener(_syncOther);
      _syncOther();
    }
  }

  @override
  void dispose() {
    _settings?.removeListener(_syncOther);
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  // ───────────────────────────── State logic ─────────────────────────────

  /// The quantity expressed in the "From" unit (exact, not rounded).
  double? get _fromValue {
    if (_sourceIsFrom) return parseValue(_from, _fromCtrl.text);
    final v = parseValue(_to, _toCtrl.text);
    return v == null ? null : convert(c, _to, _from, v);
  }

  /// The quantity expressed in the "To" unit (exact, not rounded).
  double? get _toValue {
    if (!_sourceIsFrom) return parseValue(_to, _toCtrl.text);
    final v = parseValue(_from, _fromCtrl.text);
    return v == null ? null : convert(c, _from, _to, v);
  }

  void _setText(TextEditingController ctrl, String text) {
    if (ctrl.text == text) return;
    ctrl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  /// Rewrites the calculated box from the box the user typed in.
  void _syncOther() {
    final s = _settings;
    if (s == null) return;
    if (_sourceIsFrom) {
      final v = _toValue;
      _setText(_toCtrl, v == null ? '' : formatValue(_to, v, s.style));
    } else {
      final v = _fromValue;
      _setText(_fromCtrl, v == null ? '' : formatValue(_from, v, s.style));
    }
  }

  void _edited(bool fromSide) => setState(() {
        _sourceIsFrom = fromSide;
        _syncOther();
      });

  void _changeUnit({required bool fromSide, required String id}) {
    setState(() {
      if (fromSide == _sourceIsFrom) {
        // The typed box keeps its number. If that text can't be read in the
        // new unit (e.g. "1 ft 2 in" → meters), keep the same quantity instead.
        final ctrl = fromSide ? _fromCtrl : _toCtrl;
        final oldUnit = fromSide ? _from : _to;
        final newUnit = c.unit(id);
        final oldValue = parseValue(oldUnit, ctrl.text);
        if (oldValue != null && parseValue(newUnit, ctrl.text) == null) {
          _setText(ctrl, formatValue(newUnit, convert(c, oldUnit, newUnit, oldValue), _exact(_settings!.style)));
        }
      }
      if (fromSide) {
        _fromId = id;
      } else {
        _toId = id;
      }
      _syncOther();
    });
  }

  /// A card in the grid was clicked: show that unit in the "To" box.
  void _pickTo(Unit u) {
    setState(() {
      if (!_sourceIsFrom) {
        final v = _fromValue;
        _sourceIsFrom = true;
        if (v != null) _setText(_fromCtrl, formatValue(_from, v, _exact(_settings!.style)));
      }
      _toId = u.id;
      _syncOther();
    });
  }

  void _clear(bool fromSide) {
    setState(() {
      _sourceIsFrom = fromSide;
      _fromCtrl.clear();
      _toCtrl.clear();
    });
    (fromSide ? _fromFocus : _toFocus).requestFocus();
  }

  void _copyText(String shown, Unit unit) {
    if (shown.trim().isEmpty) return;
    final text = unit.feetInches ? shown : plainNumber(shown);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(unit.feetInches ? 'Copied $text' : 'Copied $text ${unit.symbol}'),
        behavior: SnackBarBehavior.floating,
        width: 340,
        duration: const Duration(seconds: 2),
      ));
  }

  // ─────────────────────────────── Build ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final style = SettingsScope.of(context).style;
    final from = _from;
    final to = _to;
    final fromValue = _fromValue;
    final toValue = _toValue;

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 720;
      final converter = _ConverterRow(
        wide: wide,
        fromBox: _ValueBox(
          label: 'FROM',
          calculated: !_sourceIsFrom,
          unitPicker: _UnitPicker(
            category: c,
            value: _fromId,
            onChanged: (id) => _changeUnit(fromSide: true, id: id),
          ),
          child: _valueField(fromSide: true),
        ),
        toBox: _ValueBox(
          label: 'TO',
          calculated: _sourceIsFrom,
          unitPicker: _UnitPicker(
            category: c,
            value: _toId,
            onChanged: (id) => _changeUnit(fromSide: false, id: id),
          ),
          child: _valueField(fromSide: false),
        ),
      );

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 14, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                converter,
                const SizedBox(height: 14),
                _FormulaPanel(
                  category: c,
                  source: _sourceIsFrom ? from : to,
                  target: _sourceIsFrom ? to : from,
                  input: _sourceIsFrom ? fromValue : toValue,
                  result: _sourceIsFrom ? toValue : fromValue,
                  reversed: !_sourceIsFrom,
                  style: style,
                ),
                if (c.kind == ConversionKind.temperature &&
                    fromValue != null &&
                    toKelvin(from, fromValue) < -1e-9) ...[
                  const SizedBox(height: 10),
                  _Warning('This is below absolute zero (0 K = −273.15 °C = −459.67 °F). '
                      'Such a temperature is not physically possible.'),
                ],
                if (c.note != null) ...[
                  const SizedBox(height: 10),
                  Text(c.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                ],
                const SizedBox(height: 26),
                _AllConversions(
                  category: c,
                  from: from,
                  selectedTo: _toId,
                  input: fromValue,
                  style: style,
                  onPick: _pickTo,
                  onCopy: _copyText,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _valueField({required bool fromSide}) {
    final scheme = Theme.of(context).colorScheme;
    final ctrl = fromSide ? _fromCtrl : _toCtrl;
    final unit = fromSide ? _from : _to;
    final isSource = fromSide == _sourceIsFrom;
    final text = ctrl.text.trim();
    final invalid = isSource && text.isNotEmpty && parseValue(unit, text) == null;
    final base = Theme.of(context).textTheme.headlineSmall;

    return TextField(
      controller: ctrl,
      focusNode: fromSide ? _fromFocus : _toFocus,
      autofocus: fromSide,
      onChanged: (_) => _edited(fromSide),
      keyboardType: unit.feetInches
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [FilteringTextInputFormatter.allow(unit.feetInches ? _feetInchChars : _numberChars)],
      style: isSource
          ? base
          : base?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: unit.feetInches ? 'e.g.  5\' 6"' : 'Type a value',
        fillColor: isSource ? scheme.surface : scheme.primaryContainer.withValues(alpha: 0.55),
        enabledBorder: isSource
            ? null
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
              ),
        errorText: invalid
            ? (unit.feetInches ? 'Try  5\' 6"   or   5 ft 6 in   or   5 6' : 'Not a valid number')
            : null,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!unit.feetInches)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(unit.symbol,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSource ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
                        )),
              ),
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: text.isEmpty ? null : () => _copyText(ctrl.text, unit),
            ),
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close, size: 20),
              onPressed: text.isEmpty ? null : () => _clear(fromSide),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Widgets ─────────────────────────────

class _ConverterRow extends StatelessWidget {
  const _ConverterRow({required this.wide, required this.fromBox, required this.toBox});

  final bool wide;
  final Widget fromBox;
  final Widget toBox;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final equals = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
      child: Text('=',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: scheme.onSecondaryContainer, height: 1)),
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: fromBox),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: equals),
          Expanded(child: toBox),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [fromBox, Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: equals)), toBox],
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.label, required this.calculated, required this.child, required this.unitPicker});

  final String label;
  final bool calculated;
  final Widget child;
  final Widget unitPicker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        );
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(label, style: labelStyle),
              const Spacer(),
              Text(calculated ? 'result · you can type here too' : 'typing here',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 10),
            child,
            const SizedBox(height: 12),
            unitPicker,
          ],
        ),
      ),
    );
  }
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({required this.category, required this.value, required this.onChanged});

  final UnitCategory category;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <DropdownMenuItem<String>>[];
    final selectedBuilders = <Widget>[];

    for (final system in UnitSystem.values) {
      final units = category.unitsOf(system);
      if (units.isEmpty) continue;
      items.add(DropdownMenuItem(
        value: '__header_${system.name}',
        enabled: false,
        child: Text(
          system.label.toUpperCase(),
          style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.primary),
        ),
      ));
      selectedBuilders.add(const SizedBox.shrink());
      for (final u in units) {
        items.add(DropdownMenuItem(
          value: u.id,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('${u.name}  (${u.symbol})', overflow: TextOverflow.ellipsis),
          ),
        ));
        selectedBuilders.add(Align(
          alignment: Alignment.centerLeft,
          child: Text('${u.name}  (${u.symbol})', overflow: TextOverflow.ellipsis),
        ));
      }
    }

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Unit',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 460,
          borderRadius: BorderRadius.circular(12),
          items: items,
          selectedItemBuilder: (_) => selectedBuilders,
          onChanged: (id) {
            if (id != null && !id.startsWith('__header_')) onChanged(id);
          },
        ),
      ),
    );
  }
}

class _FormulaPanel extends StatelessWidget {
  const _FormulaPanel({
    required this.category,
    required this.source,
    required this.target,
    required this.input,
    required this.result,
    required this.reversed,
    required this.style,
  });

  final UnitCategory category;
  final Unit source;
  final Unit target;
  final double? input;
  final double? result;
  final bool reversed;
  final NumberStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final f = formulaFor(category, source, target);
    final def = definitionLine(category, source, target);
    final fg = scheme.onSecondaryContainer;
    const exact = NumberStyle(precision: 10, mode: PrecisionMode.significant);

    final worked = <String>[];
    final x = input;
    final y = result;
    if (x != null && y != null) {
      final xs = formatNumber(x, exact);
      if (source.feetInches) {
        final whole = x.abs().floor() * (x < 0 ? -1 : 1);
        final inches = (x.abs() - x.abs().floor()) * 12;
        worked.add('ft = ${formatNumber(whole.toDouble(), exact)} + '
            '${formatNumber(inches, exact)} ÷ 12 = $xs ft');
      }
      if (!f.isIdentity) {
        var line = '${f.lhs} = ${f.substituted(xs)} = ${formatNumber(y, style)} ${f.lhs}';
        if (target.feetInches) line += '  =  ${formatFeetInches(y, style)}';
        worked.add(line);
      } else if (target.feetInches) {
        worked.add('= ${formatFeetInches(y, style)}');
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.functions, color: fg)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reversed ? 'FORMULA  ·  TO → FROM' : 'FORMULA  ·  FROM → TO',
                    style: t.labelSmall?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 4),
                for (final line in f.lines)
                  SelectableText(line, style: _mono.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: fg)),
                for (final line in worked) ...[
                  const SizedBox(height: 4),
                  SelectableText(line, style: _mono.copyWith(fontSize: 15, color: fg.withValues(alpha: 0.85))),
                ],
                if (def != null) ...[
                  const SizedBox(height: 8),
                  Text(def, style: t.bodySmall?.copyWith(color: fg.withValues(alpha: 0.75))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: scheme.onErrorContainer))),
      ]),
    );
  }
}

class _AllConversions extends StatelessWidget {
  const _AllConversions({
    required this.category,
    required this.from,
    required this.selectedTo,
    required this.input,
    required this.style,
    required this.onPick,
    required this.onCopy,
  });

  final UnitCategory category;
  final Unit from;
  final String selectedTo;
  final double? input;
  final NumberStyle style;
  final ValueChanged<Unit> onPick;
  final void Function(String shown, Unit unit) onCopy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final x = input;
    final shownInput = x == null
        ? null
        : formatValue(from, x, NumberStyle(precision: 10, mode: PrecisionMode.significant, inchFraction: style.inchFraction));
    final title = shownInput == null
        ? 'All ${category.name.toLowerCase()} units'
        : '$shownInput${from.feetInches ? '' : ' ${from.symbol}'} in every unit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('Click a card to show it in the “To” box.',
            style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        for (final system in UnitSystem.values)
          if (category.unitsOf(system).any((u) => u.id != from.id)) ...[
            const SizedBox(height: 18),
            Row(children: [
              Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(system.label, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, box) {
              const gap = 12.0;
              final cols = (box.maxWidth / 270).floor().clamp(1, 4);
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final u in category.unitsOf(system))
                    if (u.id != from.id)
                      SizedBox(
                        width: w,
                        child: _UnitTile(
                          category: category,
                          from: from,
                          unit: u,
                          input: x,
                          style: style,
                          selected: u.id == selectedTo,
                          onTap: () => onPick(u),
                          onCopy: onCopy,
                        ),
                      ),
                ],
              );
            }),
          ],
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.category,
    required this.from,
    required this.unit,
    required this.input,
    required this.style,
    required this.selected,
    required this.onTap,
    required this.onCopy,
  });

  final UnitCategory category;
  final Unit from;
  final Unit unit;
  final double? input;
  final NumberStyle style;
  final bool selected;
  final VoidCallback onTap;
  final void Function(String shown, Unit unit) onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final x = input;
    final shown = x == null ? null : formatValue(unit, convert(category, from, unit, x), style);
    final formula = formulaFor(category, from, unit).compact;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.6) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 1.6 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: shown ?? '—',
                          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (!unit.feetInches)
                          TextSpan(text: '  ${unit.symbol}', style: t.titleSmall?.copyWith(color: scheme.primary)),
                      ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    onPressed: shown == null ? null : () => onCopy(shown, unit),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              Text(unit.name, style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(formula, style: _mono.copyWith(fontSize: 13, color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
