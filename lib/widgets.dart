import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

/// Parses user input. Accepts "1,5" and "1.5" and ignores grouping characters.
double? parseInput(String text, NumberStyle style) {
  var t = text.trim().replaceAll(RegExp(r'[\s\u00A0]'), '').replaceAll('−', '-');
  if (t.isEmpty) return null;
  final hasComma = t.contains(',');
  final dotCount = '.'.allMatches(t).length;
  if (style.decimalSeparator == ',') {
    if (hasComma) {
      // "1.234,56": the comma is the decimal mark, dots are grouping.
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (dotCount > 1) {
      // "1.234.567": only grouping dots.
      t = t.replaceAll('.', '');
    }
    // A single dot with no comma ("1.5") is a decimal point.
  } else {
    t = t.replaceAll(',', '');
  }
  return double.tryParse(t);
}

/// A numeric text field used by all tools.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.prefix,
    this.onChanged,
    this.signed = false,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? prefix;
  final ValueChanged<String>? onChanged;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: signed),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]'))],
      style: Theme.of(context).textTheme.titleLarge,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixText: prefix,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

/// One line of a result card.
class ResultRow {
  const ResultRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;
}

/// A colored card listing results; long-press copies all of them.
class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.rows, this.footnote});

  final List<ResultRow> rows;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: rows.map((r) => '${r.label}: ${r.value}').join('\n')));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          r.label,
                          style: (r.highlight ? text.titleMedium : text.bodyLarge)
                              ?.copyWith(color: cs.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          r.value,
                          textAlign: TextAlign.right,
                          style: (r.highlight ? text.headlineSmall : text.titleMedium)?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: r.highlight ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (footnote != null) ...[
                const SizedBox(height: 8),
                Text(footnote!, style: text.bodySmall?.copyWith(color: cs.onPrimaryContainer)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard page frame for a tool opened from the Tools tab.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: children,
        ),
      ),
    );
  }
}

/// Vertical spacing used between form fields.
const gap16 = SizedBox(height: 16);
const gap24 = SizedBox(height: 24);
