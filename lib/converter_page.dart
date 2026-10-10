import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_menu.dart';

class _Unit {
  const _Unit(this.name, this.symbol, this.factor);

  final String name;
  final String symbol;

  /// How many base units one of this unit is (unused for temperature).
  final double factor;
}

class _Category {
  const _Category(this.name, this.icon, this.units, {this.fromIndex = 0, this.toIndex = 1});

  final String name;
  final IconData icon;
  final List<_Unit> units;
  final int fromIndex;
  final int toIndex;
}

const _categories = [
  _Category('Length', Icons.straighten, [
    _Unit('Millimetre', 'mm', 0.001),
    _Unit('Centimetre', 'cm', 0.01),
    _Unit('Metre', 'm', 1),
    _Unit('Kilometre', 'km', 1000),
    _Unit('Inch', 'in', 0.0254),
    _Unit('Foot', 'ft', 0.3048),
    _Unit('Yard', 'yd', 0.9144),
    _Unit('Mile', 'mi', 1609.344),
  ], fromIndex: 3, toIndex: 7),
  _Category('Weight', Icons.scale, [
    _Unit('Milligram', 'mg', 0.000001),
    _Unit('Gram', 'g', 0.001),
    _Unit('Kilogram', 'kg', 1),
    _Unit('Quintal', 'q', 100),
    _Unit('Tonne', 't', 1000),
    _Unit('Ounce', 'oz', 0.028349523125),
    _Unit('Pound', 'lb', 0.45359237),
  ], fromIndex: 2, toIndex: 6),
  _Category('Temperature', Icons.thermostat, [
    _Unit('Celsius', '°C', 1),
    _Unit('Fahrenheit', '°F', 1),
    _Unit('Kelvin', 'K', 1),
  ]),
  _Category('Area', Icons.crop_square, [
    _Unit('Square centimetre', 'cm²', 0.0001),
    _Unit('Square metre', 'm²', 1),
    _Unit('Square kilometre', 'km²', 1000000),
    _Unit('Hectare', 'ha', 10000),
    _Unit('Acre', 'ac', 4046.8564224),
    _Unit('Square inch', 'in²', 0.00064516),
    _Unit('Square foot', 'ft²', 0.09290304),
    _Unit('Square yard', 'yd²', 0.83612736),
  ], fromIndex: 1, toIndex: 6),
  _Category('Speed', Icons.speed, [
    _Unit('Metre per second', 'm/s', 1),
    _Unit('Kilometre per hour', 'km/h', 1 / 3.6),
    _Unit('Mile per hour', 'mph', 0.44704),
    _Unit('Knot', 'kn', 1852 / 3600),
    _Unit('Foot per second', 'ft/s', 0.3048),
  ], fromIndex: 1, toIndex: 2),
];

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  int _category = 0;
  int _from = _categories[0].fromIndex;
  int _to = _categories[0].toIndex;
  final _input = TextEditingController(text: '1');

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  _Category get _cat => _categories[_category];

  void _selectCategory(int i) {
    setState(() {
      _category = i;
      _from = _categories[i].fromIndex;
      _to = _categories[i].toIndex;
    });
  }

  double _convert(double v, int from, int to) {
    if (_cat.name == 'Temperature') {
      // Convert to Celsius first, then to the target unit.
      final c = switch (from) {
        0 => v,
        1 => (v - 32) * 5 / 9,
        _ => v - 273.15,
      };
      return switch (to) {
        0 => c,
        1 => c * 9 / 5 + 32,
        _ => c + 273.15,
      };
    }
    return v * _cat.units[from].factor / _cat.units[to].factor;
  }

  String _format(double v) {
    if (v.isNaN || v.isInfinite) return '—';
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e12 || a < 1e-6) return v.toStringAsExponential(6);
    var s = v.toStringAsFixed(8);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  double? get _value => double.tryParse(_input.text.replaceAll(',', '').trim());

  Widget _unitPicker(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: [
            for (var i = 0; i < _cat.units.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text('${_cat.units[i].name} (${_cat.units[i].symbol})'),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final value = _value;
    final result = value == null ? null : _convert(value, _from, _to);

    return Column(
      children: [
        const ScreenHeader(title: 'Unit converter'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _categories.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(_categories[i].icon, size: 18),
                          label: Text(_categories[i].name),
                          selected: i == _category,
                          showCheckmark: false,
                          onSelected: (_) => _selectCategory(i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _input,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]'))],
                style: text.headlineMedium,
                decoration: InputDecoration(
                  labelText: 'Value',
                  suffixText: _cat.units[_from].symbol,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _unitPicker('From', _from, (v) => setState(() => _from = v))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: IconButton.filledTonal(
                      tooltip: 'Swap units',
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: () => setState(() {
                        final t = _from;
                        _from = _to;
                        _to = t;
                      }),
                    ),
                  ),
                  Expanded(child: _unitPicker('To', _to, (v) => setState(() => _to = v))),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Result', style: text.labelLarge?.copyWith(color: cs.onPrimaryContainer)),
                      const SizedBox(height: 8),
                      SelectableText(
                        result == null ? '—' : '${_format(result)} ${_cat.units[_to].symbol}',
                        style: text.headlineMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (value != null) ...[
                Text('All units', style: text.titleMedium),
                const SizedBox(height: 8),
                for (var i = 0; i < _cat.units.length; i++)
                  if (i != _from)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(_cat.units[i].name),
                      trailing: Text(
                        '${_format(_convert(value, _from, i))} ${_cat.units[i].symbol}',
                        style: text.bodyLarge,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
