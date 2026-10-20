import 'package:flutter/material.dart';

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
