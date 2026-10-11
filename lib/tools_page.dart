import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_menu.dart';
import 'settings.dart';
import 'widgets.dart';

class _ToolInfo {
  const _ToolInfo(this.title, this.subtitle, this.icon, this.builder);

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

final _tools = <_ToolInfo>[
  _ToolInfo('Discount & Tax', 'Sale price, VAT or GST', Icons.local_offer_outlined, (_) => const DiscountTaxPage()),
  _ToolInfo('Tip & Split', 'Tip and split the bill', Icons.restaurant_outlined, (_) => const TipSplitPage()),
  _ToolInfo('Percentage', 'Percent of, ratio and change', Icons.percent, (_) => const PercentagePage()),
  _ToolInfo('Loan / EMI', 'Monthly payment and interest', Icons.account_balance_outlined, (_) => const LoanPage()),
  _ToolInfo('BMI', 'Body mass index', Icons.monitor_weight_outlined, (_) => const BmiPage()),
];

/// The Tools tab: a list of everyday calculators.
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const ScreenHeader(title: 'Tools'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final t in _tools)
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHigh,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                      child: Icon(t.icon),
                    ),
                    title: Text(t.title),
                    subtitle: Text(t.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: t.builder)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Discount & Tax

class DiscountTaxPage extends StatefulWidget {
  const DiscountTaxPage({super.key});

  @override
  State<DiscountTaxPage> createState() => _DiscountTaxPageState();
}

class _DiscountTaxPageState extends State<DiscountTaxPage> {
  final _price = TextEditingController(text: '100');
  final _discount = TextEditingController(text: '20');
  final _tax = TextEditingController(text: '0');

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    _tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final price = parseInput(_price.text, s.numberStyle);
    final discount = parseInput(_discount.text, s.numberStyle) ?? 0;
    final tax = parseInput(_tax.text, s.numberStyle) ?? 0;
    void refresh(String _) => setState(() {});

    final rows = <ResultRow>[];
    if (price != null) {
      final saved = price * discount / 100;
      final afterDiscount = price - saved;
      final taxAmount = afterDiscount * tax / 100;
      rows.addAll([
        ResultRow('You save', s.money(saved)),
        ResultRow('Price after discount', s.money(afterDiscount)),
        if (tax != 0) ResultRow('Tax', s.money(taxAmount)),
        ResultRow('Final price', s.money(afterDiscount + taxAmount), highlight: true),
      ]);
    }

    return ToolScaffold(
      title: 'Discount & Tax',
      children: [
        NumberField(controller: _price, label: 'Original price', onChanged: refresh),
        gap16,
        NumberField(controller: _discount, label: 'Discount', suffix: '%', onChanged: refresh),
        gap16,
        NumberField(controller: _tax, label: 'Tax (VAT / GST / sales tax)', suffix: '%', onChanged: refresh),
        gap24,
        if (rows.isNotEmpty) ResultCard(rows: rows, footnote: 'Tax is added after the discount.'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tip & Split

class TipSplitPage extends StatefulWidget {
  const TipSplitPage({super.key});

  @override
  State<TipSplitPage> createState() => _TipSplitPageState();
}

class _TipSplitPageState extends State<TipSplitPage> {
  final _bill = TextEditingController(text: '50');
  final _tip = TextEditingController(text: '15');
  int _people = 2;

  static const _presets = [0, 10, 15, 18, 20];

  @override
  void dispose() {
    _bill.dispose();
    _tip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final text = Theme.of(context).textTheme;
    final bill = parseInput(_bill.text, s.numberStyle);
    final tipPct = parseInput(_tip.text, s.numberStyle) ?? 0;
    void refresh(String _) => setState(() {});

    final rows = <ResultRow>[];
    if (bill != null) {
      final tip = bill * tipPct / 100;
      final total = bill + tip;
      rows.addAll([
        ResultRow('Tip', s.money(tip)),
        ResultRow('Total', s.money(total)),
        if (_people > 1) ResultRow('Tip per person', s.money(tip / _people)),
        ResultRow(_people > 1 ? 'Each person pays' : 'You pay', s.money(total / _people), highlight: true),
      ]);
    }

    return ToolScaffold(
      title: 'Tip & Split',
      children: [
        NumberField(controller: _bill, label: 'Bill amount', onChanged: refresh),
        gap16,
        NumberField(controller: _tip, label: 'Tip', suffix: '%', onChanged: refresh),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final p in _presets)
              ChoiceChip(
                label: Text('$p%'),
                selected: tipPct == p,
                onSelected: (_) => setState(() => _tip.text = '$p'),
              ),
          ],
        ),
        gap24,
        Row(
          children: [
            Expanded(child: Text('People', style: text.titleMedium)),
            IconButton.filledTonal(
              tooltip: 'Fewer people',
              icon: const Icon(Icons.remove),
              onPressed: _people > 1 ? () => setState(() => _people--) : null,
            ),
            SizedBox(
              width: 56,
              child: Text('$_people', textAlign: TextAlign.center, style: text.headlineSmall),
            ),
            IconButton.filledTonal(
              tooltip: 'More people',
              icon: const Icon(Icons.add),
              onPressed: _people < 99 ? () => setState(() => _people++) : null,
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
// Percentage

class PercentagePage extends StatefulWidget {
  const PercentagePage({super.key});

  @override
  State<PercentagePage> createState() => _PercentagePageState();
}

class _PercentagePageState extends State<PercentagePage> {
  final _a1 = TextEditingController(text: '15');
  final _b1 = TextEditingController(text: '200');
  final _a2 = TextEditingController(text: '30');
  final _b2 = TextEditingController(text: '120');
  final _a3 = TextEditingController(text: '80');
  final _b3 = TextEditingController(text: '100');

  @override
  void dispose() {
    for (final c in [_a1, _b1, _a2, _b2, _a3, _b3]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _section(String title, Widget a, Widget b, String result) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: a),
                const SizedBox(width: 12),
                Expanded(child: b),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              result,
              style: text.headlineSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    double? p(TextEditingController c) => parseInput(c.text, s.numberStyle);
    void refresh(String _) => setState(() {});

    final a1 = p(_a1), b1 = p(_b1), a2 = p(_a2), b2 = p(_b2), a3 = p(_a3), b3 = p(_b3);

    final r1 = (a1 != null && b1 != null) ? s.number(a1 * b1 / 100) : '—';
    final r2 = (a2 != null && b2 != null && b2 != 0) ? '${s.number(a2 / b2 * 100, decimals: 2)}%' : '—';
    String r3 = '—';
    if (a3 != null && b3 != null && a3 != 0) {
      final change = (b3 - a3) / a3.abs() * 100;
      final word = change > 0 ? 'increase' : (change < 0 ? 'decrease' : 'no change');
      r3 = change == 0 ? 'No change' : '${s.number(change.abs(), decimals: 2)}% $word';
    }

    return ToolScaffold(
      title: 'Percentage',
      children: [
        _section(
          'What is X% of Y?',
          NumberField(controller: _a1, label: 'X', suffix: '%', onChanged: refresh, signed: true),
          NumberField(controller: _b1, label: 'Y', onChanged: refresh, signed: true),
          r1,
        ),
        _section(
          'X is what percent of Y?',
          NumberField(controller: _a2, label: 'X', onChanged: refresh, signed: true),
          NumberField(controller: _b2, label: 'Y', onChanged: refresh, signed: true),
          r2,
        ),
        _section(
          'Percent change from X to Y',
          NumberField(controller: _a3, label: 'From', onChanged: refresh, signed: true),
          NumberField(controller: _b3, label: 'To', onChanged: refresh, signed: true),
          r3,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loan / EMI

class LoanPage extends StatefulWidget {
  const LoanPage({super.key});

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final _amount = TextEditingController(text: '10000');
  final _rate = TextEditingController(text: '8');
  final _term = TextEditingController(text: '3');
  bool _years = true;

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _term.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final amount = parseInput(_amount.text, s.numberStyle);
    final rate = parseInput(_rate.text, s.numberStyle);
    final term = parseInput(_term.text, s.numberStyle);
    void refresh(String _) => setState(() {});

    final rows = <ResultRow>[];
    if (amount != null && rate != null && term != null && term > 0 && amount > 0 && rate >= 0) {
      final months = (_years ? term * 12 : term).round();
      if (months > 0) {
        final r = rate / 12 / 100;
        final payment = r == 0
            ? amount / months
            : amount * r * math.pow(1 + r, months) / (math.pow(1 + r, months) - 1);
        final total = payment * months;
        rows.addAll([
          ResultRow('Monthly payment', s.money(payment), highlight: true),
          ResultRow('Number of payments', '$months'),
          ResultRow('Total interest', s.money(total - amount)),
          ResultRow('Total amount paid', s.money(total)),
        ]);
      }
    }

    return ToolScaffold(
      title: 'Loan / EMI',
      children: [
        NumberField(controller: _amount, label: 'Loan amount', onChanged: refresh),
        gap16,
        NumberField(controller: _rate, label: 'Interest rate (per year)', suffix: '%', onChanged: refresh),
        gap16,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: NumberField(controller: _term, label: 'Loan term', onChanged: refresh)),
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
        gap24,
        if (rows.isNotEmpty)
          ResultCard(rows: rows, footnote: 'Fixed-rate loan with equal monthly payments.'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BMI

class BmiPage extends StatefulWidget {
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  bool _metric = true;
  final _cm = TextEditingController(text: '170');
  final _kg = TextEditingController(text: '65');
  final _ft = TextEditingController(text: '5');
  final _inch = TextEditingController(text: '7');
  final _lb = TextEditingController(text: '145');

  @override
  void dispose() {
    for (final c in [_cm, _kg, _ft, _inch, _lb]) {
      c.dispose();
    }
    super.dispose();
  }

  String _category(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obesity';
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    double? p(TextEditingController c) => parseInput(c.text, s.numberStyle);
    void refresh(String _) => setState(() {});

    double? heightM;
    double? weightKg;
    if (_metric) {
      final cm = p(_cm);
      heightM = cm == null ? null : cm / 100;
      weightKg = p(_kg);
    } else {
      final ft = p(_ft) ?? 0;
      final inch = p(_inch) ?? 0;
      final totalIn = ft * 12 + inch;
      heightM = totalIn > 0 ? totalIn * 0.0254 : null;
      final lb = p(_lb);
      weightKg = lb == null ? null : lb * 0.45359237;
    }

    final rows = <ResultRow>[];
    if (heightM != null && weightKg != null && heightM > 0 && weightKg > 0) {
      final bmi = weightKg / (heightM * heightM);
      final low = 18.5 * heightM * heightM;
      final high = 24.9 * heightM * heightM;
      String w(double kg) => _metric ? '${s.number(kg, decimals: 1)} kg' : '${s.number(kg / 0.45359237, decimals: 1)} lb';
      rows.addAll([
        ResultRow('BMI', s.number(bmi, decimals: 1), highlight: true),
        ResultRow('Category', _category(bmi)),
        ResultRow('Normal range for your height', '${w(low)} – ${w(high)}'),
      ]);
    }

    return ToolScaffold(
      title: 'BMI',
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Metric (cm, kg)')),
            ButtonSegment(value: false, label: Text('Imperial (ft, lb)')),
          ],
          selected: {_metric},
          onSelectionChanged: (v) => setState(() => _metric = v.first),
        ),
        gap24,
        if (_metric) ...[
          NumberField(controller: _cm, label: 'Height', suffix: 'cm', onChanged: refresh),
          gap16,
          NumberField(controller: _kg, label: 'Weight', suffix: 'kg', onChanged: refresh),
        ] else ...[
          Row(
            children: [
              Expanded(child: NumberField(controller: _ft, label: 'Height', suffix: 'ft', onChanged: refresh)),
              const SizedBox(width: 12),
              Expanded(child: NumberField(controller: _inch, label: '', suffix: 'in', onChanged: refresh)),
            ],
          ),
          gap16,
          NumberField(controller: _lb, label: 'Weight', suffix: 'lb', onChanged: refresh),
        ],
        gap24,
        if (rows.isNotEmpty)
          ResultCard(
            rows: rows,
            footnote: 'BMI is a general guide for adults. It does not measure body fat and is not a diagnosis.',
          ),
      ],
    );
  }
}
