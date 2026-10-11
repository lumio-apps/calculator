import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_menu.dart';
import 'settings.dart';
import 'widgets.dart';

class _Unit {
  const _Unit(this.name, this.symbol, this.factor);

  final String name;
  final String symbol;

  /// How many base units one of this unit is (unused for temperature and fuel).
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
    _Unit('Nautical mile', 'nmi', 1852),
  ], fromIndex: 3, toIndex: 7),
  _Category('Weight', Icons.scale, [
    _Unit('Milligram', 'mg', 0.000001),
    _Unit('Gram', 'g', 0.001),
    _Unit('Kilogram', 'kg', 1),
    _Unit('Quintal', 'q', 100),
    _Unit('Tonne', 't', 1000),
    _Unit('Ounce', 'oz', 0.028349523125),
    _Unit('Pound', 'lb', 0.45359237),
    _Unit('Stone', 'st', 6.35029318),
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
    _Unit('Square mile', 'mi²', 2589988.110336),
  ], fromIndex: 1, toIndex: 6),
  _Category('Volume', Icons.local_drink_outlined, [
    _Unit('Millilitre', 'mL', 0.001),
    _Unit('Litre', 'L', 1),
    _Unit('Cubic metre', 'm³', 1000),
    _Unit('Teaspoon (US)', 'tsp', 0.00492892159375),
    _Unit('Tablespoon (US)', 'tbsp', 0.01478676478125),
    _Unit('Fluid ounce (US)', 'fl oz', 0.0295735295625),
    _Unit('Cup (US)', 'cup', 0.2365882365),
    _Unit('Pint (US)', 'pt', 0.473176473),
    _Unit('Gallon (US)', 'gal', 3.785411784),
    _Unit('Gallon (UK)', 'gal UK', 4.54609),
  ], fromIndex: 1, toIndex: 8),
  _Category('Speed', Icons.speed, [
    _Unit('Metre per second', 'm/s', 1),
    _Unit('Kilometre per hour', 'km/h', 1 / 3.6),
    _Unit('Mile per hour', 'mph', 0.44704),
    _Unit('Knot', 'kn', 1852 / 3600),
    _Unit('Foot per second', 'ft/s', 0.3048),
  ], fromIndex: 1, toIndex: 2),
  _Category('Time', Icons.schedule, [
    _Unit('Millisecond', 'ms', 0.001),
    _Unit('Second', 's', 1),
    _Unit('Minute', 'min', 60),
    _Unit('Hour', 'h', 3600),
    _Unit('Day', 'd', 86400),
    _Unit('Week', 'wk', 604800),
    _Unit('Month (average)', 'mo', 2629746),
    _Unit('Year (average)', 'yr', 31556952),
  ], fromIndex: 3, toIndex: 2),
  _Category('Data', Icons.sd_storage_outlined, [
    _Unit('Bit', 'bit', 0.125),
    _Unit('Byte', 'B', 1),
    _Unit('Kilobyte', 'KB', 1000),
    _Unit('Megabyte', 'MB', 1000000),
    _Unit('Gigabyte', 'GB', 1000000000),
    _Unit('Terabyte', 'TB', 1000000000000),
    _Unit('Kibibyte', 'KiB', 1024),
    _Unit('Mebibyte', 'MiB', 1048576),
    _Unit('Gibibyte', 'GiB', 1073741824),
  ], fromIndex: 4, toIndex: 3),
  _Category('Fuel', Icons.local_gas_station_outlined, [
    _Unit('Kilometres per litre', 'km/L', 1),
    _Unit('Litres per 100 km', 'L/100km', 1),
    _Unit('Miles per gallon (US)', 'mpg US', 0.425143707),
    _Unit('Miles per gallon (UK)', 'mpg UK', 0.354006189),
  ], fromIndex: 0, toIndex: 1),
  _Category('Pressure', Icons.compress, [
    _Unit('Pascal', 'Pa', 1),
    _Unit('Kilopascal', 'kPa', 1000),
    _Unit('Bar', 'bar', 100000),
    _Unit('Atmosphere', 'atm', 101325),
    _Unit('Pound per square inch', 'psi', 6894.757293168),
    _Unit('Millimetre of mercury', 'mmHg', 133.322387415),
  ], fromIndex: 2, toIndex: 4),
  _Category('Energy', Icons.bolt, [
    _Unit('Joule', 'J', 1),
    _Unit('Kilojoule', 'kJ', 1000),
    _Unit('Calorie', 'cal', 4.184),
    _Unit('Kilocalorie', 'kcal', 4184),
    _Unit('Watt-hour', 'Wh', 3600),
    _Unit('Kilowatt-hour', 'kWh', 3600000),
    _Unit('British thermal unit', 'BTU', 1055.05585262),
  ], fromIndex: 3, toIndex: 1),
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
    if (from == to) return v;
    switch (_cat.name) {
      case 'Temperature':
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
      case 'Fuel':
        // Work in km/L; L/100km is the inverse.
        double kmPerL(double x, int unit) =>
            unit == 1 ? (x == 0 ? double.infinity : 100 / x) : x * _cat.units[unit].factor;
        final k = kmPerL(v, from);
        if (to == 1) return k == 0 ? double.infinity : 100 / k;
        return k / _cat.units[to].factor;
    }
    return v * _cat.units[from].factor / _cat.units[to].factor;
  }

  String _format(AppSettings s, double v) {
    if (v.isNaN || v.isInfinite) return '—';
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e15 || a < 1e-6) return v.toStringAsExponential(6);
    final decimals = a >= 1000 ? 2 : (a >= 1 ? 6 : 8);
    return formatGrouped(v, s.numberStyle, decimals: decimals);
  }

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
                child: Text(
                  '${_cat.units[i].name} (${_cat.units[i].symbol})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final value = parseInput(_input.text, s.numberStyle);
    final result = value == null ? null : _convert(value, _from, _to);
    final resultText = result == null ? '—' : '${_format(s, result)} ${_cat.units[_to].symbol}';

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
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]'))],
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onLongPress: result == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: resultText));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Result', style: text.labelLarge?.copyWith(color: cs.onPrimaryContainer)),
                        const SizedBox(height: 8),
                        Text(
                          resultText,
                          style: text.headlineMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
                        '${_format(s, _convert(value, _from, i))} ${_cat.units[i].symbol}',
                        style: text.bodyLarge,
                      ),
                      onTap: () => setState(() => _to = i),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
