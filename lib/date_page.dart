import 'package:flutter/material.dart';

import 'app_menu.dart';

enum _DateMode { difference, age }

class DatePage extends StatefulWidget {
  const DatePage({super.key});

  @override
  State<DatePage> createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  _DateMode _mode = _DateMode.difference;
  late DateTime _from = _today;
  late DateTime _to = _today;
  late DateTime _birth = DateTime(_today.year - 25, _today.month, _today.day);

  static DateTime get _today => DateUtils.dateOnly(DateTime.now());

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Whole days between two dates, safe across daylight-saving changes.
  int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  /// Years, months and days from [a] to [b] (a must not be after b).
  (int, int, int) _ymd(DateTime a, DateTime b) {
    var y = b.year - a.year;
    var m = b.month - a.month;
    var d = b.day - a.day;
    if (d < 0) {
      m -= 1;
      final prevMonth = b.month == 1 ? 12 : b.month - 1;
      final prevYear = b.month == 1 ? b.year - 1 : b.year;
      d += DateUtils.getDaysInMonth(prevYear, prevMonth);
      if (d < 0) d = 0;
    }
    if (m < 0) {
      y -= 1;
      m += 12;
    }
    return (y, m, d);
  }

  String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

  String _ymdText(DateTime a, DateTime b) {
    final (y, m, d) = _ymd(a, b);
    final parts = <String>[
      if (y > 0) _plural(y, 'year'),
      if (m > 0) _plural(m, 'month'),
      if (d > 0 || (y == 0 && m == 0)) _plural(d, 'day'),
    ];
    return parts.join(', ');
  }

  Future<DateTime?> _pick(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
  }

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPicked) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(label),
      subtitle: Text('${_fmt(value)} · ${_weekdays[value.weekday - 1]}'),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: () async {
        final picked = await _pick(value);
        if (picked != null) onPicked(picked);
      },
    );
  }

  Widget _resultCard(String title, String main, List<String> lines) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.labelLarge?.copyWith(color: cs.onPrimaryContainer)),
            const SizedBox(height: 8),
            Text(
              main,
              style: text.headlineSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l, style: text.bodyLarge?.copyWith(color: cs.onPrimaryContainer)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _differenceView() {
    final swapped = _from.isAfter(_to);
    final a = swapped ? _to : _from;
    final b = swapped ? _from : _to;
    final days = _daysBetween(a, b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateField('From', _from, (d) => setState(() => _from = d)),
        const SizedBox(height: 12),
        _dateField('To', _to, (d) => setState(() => _to = d)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _from = _today;
              _to = _today;
            }),
            icon: const Icon(Icons.today),
            label: const Text('Reset to today'),
          ),
        ),
        const SizedBox(height: 8),
        _resultCard('Difference', _plural(days, 'day'), [
          _ymdText(a, b),
          '${_plural(days ~/ 7, 'week')}, ${_plural(days % 7, 'day')}',
          if (swapped) 'The "From" date is after the "To" date.',
        ]),
      ],
    );
  }

  Widget _ageView() {
    final today = _today;
    if (_birth.isAfter(today)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dateField('Date of birth', _birth, (d) => setState(() => _birth = d)),
          const SizedBox(height: 20),
          _resultCard('Age', 'Not born yet', ['Pick a date of birth before today.']),
        ],
      );
    }

    final (years, _, _) = _ymd(_birth, today);
    var next = DateTime(today.year, _birth.month, _birth.day);
    if (next.isBefore(today)) next = DateTime(today.year + 1, _birth.month, _birth.day);
    final untilBirthday = _daysBetween(today, next);
    final totalDays = _daysBetween(_birth, today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dateField('Date of birth', _birth, (d) => setState(() => _birth = d)),
        const SizedBox(height: 20),
        _resultCard('Age', _plural(years, 'year'), [
          _ymdText(_birth, today),
          'Born on a ${_weekdays[_birth.weekday - 1]}',
          '${_plural(totalDays, 'day')} lived',
          untilBirthday == 0
              ? 'Happy birthday!'
              : 'Next birthday in ${_plural(untilBirthday, 'day')} (${_weekdays[next.weekday - 1]})',
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(title: 'Date calculator'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              SegmentedButton<_DateMode>(
                segments: const [
                  ButtonSegment(
                    value: _DateMode.difference,
                    icon: Icon(Icons.date_range),
                    label: Text('Days between'),
                  ),
                  ButtonSegment(
                    value: _DateMode.age,
                    icon: Icon(Icons.cake_outlined),
                    label: Text('Age'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 24),
              if (_mode == _DateMode.difference) _differenceView() else _ageView(),
            ],
          ),
        ),
      ],
    );
  }
}
