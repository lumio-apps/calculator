import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings.dart';
import 'widgets.dart';

// ---------------------------------------------------------------------------
// GST

class GstPage extends StatefulWidget {
  const GstPage({super.key});

  @override
  State<GstPage> createState() => _GstPageState();
}

class _GstPageState extends State<GstPage> {
  final _amount = TextEditingController(text: '1000');
  final _rate = TextEditingController(text: '18');
  bool _remove = false;

  static const _presets = [5, 12, 18, 28];

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final amount = parseInput(_amount.text, s.numberStyle);
    final rate = parseInput(_rate.text, s.numberStyle);
    void refresh(String _) => setState(() {});

    final rows = <ResultRow>[];
    if (amount != null && rate != null && rate >= 0) {
      final net = _remove ? amount / (1 + rate / 100) : amount;
      final gst = net * rate / 100;
      final total = net + gst;
      rows.addAll([
        ResultRow('Amount without GST', s.money(net)),
        ResultRow('GST', s.money(gst)),
        ResultRow('CGST + SGST (half each)', '${s.money(gst / 2)} + ${s.money(gst / 2)}'),
        ResultRow('Amount with GST', s.money(total), highlight: true),
      ]);
    }

    return ToolScaffold(
      title: 'GST',
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, icon: Icon(Icons.add), label: Text('Add GST')),
            ButtonSegment(value: true, icon: Icon(Icons.remove), label: Text('Remove GST')),
          ],
          selected: {_remove},
          onSelectionChanged: (v) => setState(() => _remove = v.first),
        ),
        gap24,
        NumberField(
          controller: _amount,
          label: _remove ? 'Amount including GST' : 'Amount without GST',
          onChanged: refresh,
        ),
        gap16,
        NumberField(controller: _rate, label: 'GST rate', suffix: '%', onChanged: refresh),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final p in _presets)
              ChoiceChip(
                label: Text('$p%'),
                selected: rate == p,
                onSelected: (_) => setState(() => _rate.text = '$p'),
              ),
          ],
        ),
        gap24,
        if (rows.isNotEmpty) ResultCard(rows: rows),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Time calculator

class _TimeEntry {
  _TimeEntry({String hours = '0', String minutes = '0'})
      : hours = TextEditingController(text: hours),
        minutes = TextEditingController(text: minutes);

  bool minus = false;
  final TextEditingController hours;
  final TextEditingController minutes;

  void dispose() {
    hours.dispose();
    minutes.dispose();
  }
}

class TimePage extends StatefulWidget {
  const TimePage({super.key});

  @override
  State<TimePage> createState() => _TimePageState();
}

class _TimePageState extends State<TimePage> {
  final _entries = <_TimeEntry>[
    _TimeEntry(hours: '2', minutes: '45'),
    _TimeEntry(hours: '1', minutes: '30'),
  ];

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    void refresh(String _) => setState(() {});
    int whole(TextEditingController c) => (parseInput(c.text, s.numberStyle) ?? 0).round().abs();

    var total = 0;
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      final minutes = whole(e.hours) * 60 + whole(e.minutes);
      total += (i > 0 && e.minus) ? -minutes : minutes;
    }
    final negative = total < 0;
    final abs = total.abs();
    final h = abs ~/ 60, m = abs % 60;
    final sign = negative ? '−' : '';
    final days = abs ~/ 1440;
    final remH = (abs % 1440) ~/ 60;

    return ToolScaffold(
      title: 'Time calculator',
      children: [
        for (var i = 0; i < _entries.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 56,
                child: i == 0
                    ? const SizedBox.shrink()
                    : IconButton.filledTonal(
                        tooltip: _entries[i].minus ? 'Subtract (tap to add)' : 'Add (tap to subtract)',
                        icon: Icon(_entries[i].minus ? Icons.remove : Icons.add),
                        onPressed: () => setState(() => _entries[i].minus = !_entries[i].minus),
                      ),
              ),
              const SizedBox(width: 4),
              Expanded(child: NumberField(controller: _entries[i].hours, label: 'Hours', onChanged: refresh)),
              const SizedBox(width: 10),
              Expanded(child: NumberField(controller: _entries[i].minutes, label: 'Minutes', onChanged: refresh)),
              SizedBox(
                width: 40,
                height: 56,
                child: _entries.length > 2 && i > 0
                    ? IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          final removed = _entries[i];
                          setState(() => _entries.removeAt(i));
                          // Dispose after the field has left the screen.
                          WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
                        },
                      )
                    : null,
              ),
            ],
          ),
          gap16,
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _entries.length < 10 ? () => setState(() => _entries.add(_TimeEntry())) : null,
            icon: const Icon(Icons.add),
            label: const Text('Add another time'),
          ),
        ),
        gap24,
        ResultCard(
          rows: [
            ResultRow('Total', '$sign${h}h ${m}m', highlight: true),
            ResultRow('In hours', '$sign${s.number(abs / 60, decimals: 2)} h'),
            ResultRow('In minutes', '$sign$abs min'),
            if (days > 0) ResultRow('In days', '$sign$days d ${remH}h ${m}m'),
          ],
          footnote: 'Use the + / − button to add or subtract each line.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Number base converter

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  final _input = TextEditingController(text: '255');
  int _base = 10;

  static const _bases = <(String, int)>[
    ('DEC', 10),
    ('HEX', 16),
    ('BIN', 2),
    ('OCT', 8),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _group(String digits, int size) {
    final negative = digits.startsWith('-');
    final body = negative ? digits.substring(1) : digits;
    final parts = <String>[];
    for (var end = body.length; end > 0; end -= size) {
      parts.insert(0, body.substring(end - size < 0 ? 0 : end - size, end));
    }
    return '${negative ? '-' : ''}${parts.join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final raw = _input.text.trim().replaceAll(' ', '');
    final value = raw.isEmpty ? null : BigInt.tryParse(raw, radix: _base);
    final invalid = raw.isNotEmpty && raw != '-' && value == null;

    final rows = <ResultRow>[];
    if (value != null) {
      rows.addAll([
        ResultRow('Decimal', value.toString(), highlight: _base != 10),
        ResultRow('Hexadecimal', value.toRadixString(16).toUpperCase()),
        ResultRow('Binary', _group(value.toRadixString(2), 4)),
        ResultRow('Octal', value.toRadixString(8)),
      ]);
    }

    return ToolScaffold(
      title: 'Number base',
      children: [
        SegmentedButton<int>(
          segments: [
            for (final b in _bases) ButtonSegment(value: b.$2, label: Text(b.$1)),
          ],
          selected: {_base},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _base = v.first),
        ),
        gap24,
        TextField(
          controller: _input,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          keyboardType: _base == 16 ? TextInputType.visiblePassword : TextInputType.text,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F\- ]'))],
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            labelText: 'Number in base $_base',
            errorText: invalid ? 'Not a valid base $_base number' : null,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        gap24,
        if (rows.isNotEmpty)
          ResultCard(rows: rows, footnote: 'Works with very large whole numbers. Negative numbers start with −.'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fuel / trip cost

class FuelPage extends StatefulWidget {
  const FuelPage({super.key});

  @override
  State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  final _distance = TextEditingController(text: '250');
  final _economy = TextEditingController(text: '15');
  final _price = TextEditingController(text: '100');
  bool _perLitre = true; // true: km per litre, false: litres per 100 km
  bool _roundTrip = false;

  @override
  void dispose() {
    _distance.dispose();
    _economy.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final distance = parseInput(_distance.text, s.numberStyle);
    final economy = parseInput(_economy.text, s.numberStyle);
    final price = parseInput(_price.text, s.numberStyle);
    void refresh(String _) => setState(() {});

    final rows = <ResultRow>[];
    if (distance != null && economy != null && price != null && distance > 0 && economy > 0 && price >= 0) {
      final km = _roundTrip ? distance * 2 : distance;
      final litres = _perLitre ? km / economy : km * economy / 100;
      final cost = litres * price;
      rows.addAll([
        ResultRow('Trip distance', '${s.number(km, decimals: 1)} km'),
        ResultRow('Fuel needed', '${s.number(litres, decimals: 2)} L'),
        ResultRow('Cost per km', s.money(cost / km)),
        ResultRow('Trip cost', s.money(cost), highlight: true),
      ]);
    }

    return ToolScaffold(
      title: 'Fuel / trip cost',
      children: [
        NumberField(controller: _distance, label: 'Distance (one way)', suffix: 'km', onChanged: refresh),
        gap16,
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('km / L')),
            ButtonSegment(value: false, label: Text('L / 100 km')),
          ],
          selected: {_perLitre},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _perLitre = v.first),
        ),
        const SizedBox(height: 12),
        NumberField(
          controller: _economy,
          label: _perLitre ? 'Mileage' : 'Fuel use',
          suffix: _perLitre ? 'km/L' : 'L/100km',
          onChanged: refresh,
        ),
        gap16,
        NumberField(controller: _price, label: 'Fuel price per litre', onChanged: refresh),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Round trip'),
          subtitle: const Text('Count the way back too'),
          value: _roundTrip,
          onChanged: (v) => setState(() => _roundTrip = v),
        ),
        gap16,
        if (rows.isNotEmpty) ResultCard(rows: rows),
      ],
    );
  }
}
