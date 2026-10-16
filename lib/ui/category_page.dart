import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../converter.dart';
import '../format.dart';
import '../main.dart';
import '../models.dart';

const _mono = TextStyle(
  fontFamily: 'Consolas',
  fontFamilyFallback: ['Cascadia Mono', 'Roboto Mono', 'monospace'],
);

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.category});

  final UnitCategory category;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with AutomaticKeepAliveClientMixin {
  final _input = TextEditingController(text: '1');
  final _focus = FocusNode();
  late String _fromId = widget.category.defaultFrom;
  late String _toId = widget.category.defaultTo;

  UnitCategory get c => widget.category;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _swap() => setState(() {
        final t = _fromId;
        _fromId = _toId;
        _toId = t;
      });

  void _copy(double value, Unit unit) {
    final text = formatNumber(value, SettingsScope.of(context).style)
        .replaceAll(',', '')
        .replaceAll('−', '-');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Copied $text ${unit.symbol}'),
        behavior: SnackBarBehavior.floating,
        width: 320,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final style = SettingsScope.of(context).style;
    final from = c.unit(_fromId);
    final to = c.unit(_toId);
    final x = parseInput(_input.text);
    final result = x == null ? null : convert(c, from, to, x);
    final hasText = _input.text.trim().isNotEmpty;

    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 720;
      final converter = _ConverterRow(
        wide: wide,
        fromBox: _ValueBox(
          label: 'FROM',
          unitPicker: _UnitPicker(
            category: c,
            value: _fromId,
            onChanged: (id) => setState(() => _fromId = id),
          ),
          child: TextField(
            controller: _input,
            focusNode: _focus,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,eE+\-− ]'))],
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: InputDecoration(
              hintText: 'Type a value',
              suffixText: from.symbol,
              errorText: hasText && x == null ? 'Not a valid number' : null,
              suffixIcon: hasText
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _input.clear();
                        _focus.requestFocus();
                      },
                    )
                  : null,
            ),
          ),
        ),
        swap: IconButton.filledTonal(
          tooltip: 'Swap units',
          onPressed: _swap,
          icon: Icon(wide ? Icons.swap_horiz : Icons.swap_vert),
        ),
        toBox: _ValueBox(
          label: 'TO',
          unitPicker: _UnitPicker(
            category: c,
            value: _toId,
            onChanged: (id) => setState(() => _toId = id),
          ),
          child: _ResultField(
            text: result == null ? '—' : formatNumber(result, style),
            symbol: to.symbol,
            onCopy: result == null ? null : () => _copy(result, to),
          ),
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
                  from: from,
                  to: to,
                  input: x,
                  result: result,
                  style: style,
                ),
                if (c.kind == ConversionKind.temperature && x != null && toKelvin(from, x) < -1e-9) ...[
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
                  input: x,
                  style: style,
                  onPick: (u) => setState(() => _toId = u.id),
                  onCopy: _copy,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ───────────────────────────── Widgets ─────────────────────────────

class _ConverterRow extends StatelessWidget {
  const _ConverterRow({required this.wide, required this.fromBox, required this.swap, required this.toBox});

  final bool wide;
  final Widget fromBox;
  final Widget swap;
  final Widget toBox;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: fromBox),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: swap),
          Expanded(child: toBox),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [fromBox, Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: swap)), toBox],
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.label, required this.child, required this.unitPicker});

  final String label;
  final Widget child;
  final Widget unitPicker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
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
            Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    )),
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

class _ResultField extends StatelessWidget {
  const _ResultField({required this.text, required this.symbol, required this.onCopy});

  final String text;
  final String symbol;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: scheme.primaryContainer.withValues(alpha: 0.55),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              text,
              maxLines: 1,
              style: t.headlineSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(symbol, style: t.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
          IconButton(
            tooltip: 'Copy result',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
        ],
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
    required this.from,
    required this.to,
    required this.input,
    required this.result,
    required this.style,
  });

  final UnitCategory category;
  final Unit from;
  final Unit to;
  final double? input;
  final double? result;
  final NumberStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final f = formulaFor(category, from, to);
    final def = definitionLine(category, from, to);
    final fg = scheme.onSecondaryContainer;

    String? worked;
    if (input != null && result != null) {
      final xs = formatNumber(input!, const NumberStyle(precision: 10, mode: PrecisionMode.significant));
      worked = '${f.substituted(xs)} = ${formatNumber(result!, style)} ${to.symbol}';
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
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.functions, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FORMULA',
                    style: t.labelSmall?.copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 4),
                SelectableText(f.symbolic,
                    style: _mono.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: fg)),
                if (worked != null) ...[
                  const SizedBox(height: 4),
                  SelectableText('${to.symbol} = $worked',
                      style: _mono.copyWith(fontSize: 15, color: fg.withValues(alpha: 0.85))),
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
  final void Function(double value, Unit unit) onCopy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final title = input == null
        ? 'All ${category.name.toLowerCase()} units'
        : '${formatNumber(input!, const NumberStyle(precision: 10, mode: PrecisionMode.significant))} '
            '${from.symbol} in every unit';

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
              Container(width: 4, height: 18, decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2))),
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
                          input: input,
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
  final void Function(double value, Unit unit) onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final value = input == null ? null : convert(category, from, unit, input!);
    final formula = formulaFor(category, from, unit).symbolic;

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
                          text: value == null ? '—' : formatNumber(value, style),
                          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
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
                    onPressed: value == null ? null : () => onCopy(value, unit),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
              Text(unit.name, style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(formula,
                    style: _mono.copyWith(fontSize: 13, color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
