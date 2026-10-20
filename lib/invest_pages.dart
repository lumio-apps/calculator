import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'settings.dart';
import 'widgets.dart';

enum InvestKind { sip, fd, rd, compound }

/// One page for the four savings calculators: SIP, FD, RD and compound interest.
class InvestPage extends StatefulWidget {
  const InvestPage(this.kind, {super.key});

  final InvestKind kind;

  @override
  State<InvestPage> createState() => _InvestPageState();
}

class _InvestPageState extends State<InvestPage> {
  late final TextEditingController _amount;
  final _rate = TextEditingController(text: '8');
  final _term = TextEditingController(text: '5');
  bool _years = true;
  int _freq = 4;

  static const _freqs = <(String, int)>[
    ('Yearly', 1),
    ('Half-yearly', 2),
    ('Quarterly', 4),
    ('Monthly', 12),
    ('Daily', 365),
  ];

  InvestKind get _kind => widget.kind;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _kind == InvestKind.sip || _kind == InvestKind.rd ? '5000' : '100000');
    _freq = _kind == InvestKind.compound ? 1 : 4;
  }

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _term.dispose();
    super.dispose();
  }

  String get _title => switch (_kind) {
        InvestKind.sip => 'SIP',
        InvestKind.fd => 'Fixed Deposit',
        InvestKind.rd => 'Recurring Deposit',
        InvestKind.compound => 'Compound interest',
      };

  String get _amountLabel => switch (_kind) {
        InvestKind.sip => 'Monthly investment',
        InvestKind.rd => 'Monthly deposit',
        InvestKind.fd => 'Deposit amount',
        InvestKind.compound => 'Starting amount',
      };

  String get _rateLabel => _kind == InvestKind.sip ? 'Expected return (per year)' : 'Interest rate (per year)';

  bool get _monthly => _kind == InvestKind.sip || _kind == InvestKind.rd;

  String get _footnote => switch (_kind) {
        InvestKind.sip => 'Monthly investing with returns compounded monthly. Real returns are not guaranteed.',
        InvestKind.fd => 'Interest is compounded quarterly, as most banks do.',
        InvestKind.rd => 'Interest is compounded quarterly, as most banks do.',
        InvestKind.compound => 'Interest is added to the balance at the chosen frequency.',
      };

  /// Final value for [amount], [rate] % a year and [months] months.
  double _futureValue(double amount, double rate, int months) {
    switch (_kind) {
      case InvestKind.sip:
        final i = rate / 12 / 100;
        if (i == 0) return amount * months;
        return amount * ((math.pow(1 + i, months) - 1) / i) * (1 + i);
      case InvestKind.rd:
        // Each monthly deposit earns quarterly-compounded interest until the end.
        final q = rate / 4 / 100;
        var total = 0.0;
        for (var m = 1; m <= months; m++) {
          total += amount * math.pow(1 + q, (months - m + 1) / 3);
        }
        return total;
      case InvestKind.fd:
      case InvestKind.compound:
        final f = _kind == InvestKind.fd ? 4 : _freq;
        final years = months / 12;
        return amount * math.pow(1 + rate / 100 / f, f * years);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final amount = parseInput(_amount.text, s.numberStyle);
    final rate = parseInput(_rate.text, s.numberStyle);
    final term = parseInput(_term.text, s.numberStyle);
    void refresh(String _) => setState(() {});

    final rows = <ResultRow>[];
    if (amount != null && rate != null && term != null && amount > 0 && rate >= 0 && term > 0) {
      final months = (_years ? term * 12 : term).round();
      if (months > 0 && months <= 1200) {
        final value = _futureValue(amount, rate, months);
        final invested = _monthly ? amount * months : amount;
        rows.addAll([
          ResultRow('Total invested', s.money(invested)),
          ResultRow('Interest earned', s.money(value - invested)),
          ResultRow(_kind == InvestKind.sip ? 'Estimated value' : 'Maturity value', s.money(value), highlight: true),
        ]);
      }
    }

    return ToolScaffold(
      title: _title,
      children: [
        NumberField(controller: _amount, label: _amountLabel, onChanged: refresh),
        gap16,
        NumberField(controller: _rate, label: _rateLabel, suffix: '%', onChanged: refresh),
        gap16,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: NumberField(controller: _term, label: 'Time period', onChanged: refresh)),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Years')),
                  ButtonSegment(value: false, label: Text('Months')),
                ],
                selected: {_years},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _years = v.first),
              ),
            ),
          ],
        ),
        if (_kind == InvestKind.compound) ...[
          gap16,
          Text('Compounded', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final f in _freqs)
                ChoiceChip(
                  label: Text(f.$1),
                  selected: _freq == f.$2,
                  onSelected: (_) => setState(() => _freq = f.$2),
                ),
            ],
          ),
        ],
        gap24,
        if (rows.isNotEmpty) ResultCard(rows: rows, footnote: _footnote),
      ],
    );
  }
}
