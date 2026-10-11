import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_menu.dart';
import 'expression_parser.dart';
import 'settings.dart';
import 'share.dart';
import 'widgets.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expr = '';
  String _preview = '';
  bool _justEvaluated = false;
  bool _scientific = false;
  bool _degrees = true;

  static const _ops = ['+', '−', '×', '÷', '^'];
  static const _funcTokens = ['sin(', 'cos(', 'tan(', 'ln(', 'log(', '√('];

  static const _basicRows = [
    ['AC', '⌫', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['( )', '0', '.', '='],
  ];

  static const _sciKeys = ['DEG', 'sin', 'cos', 'tan', 'ln', 'log', '√', 'x²', 'xʸ', 'π', 'e', '1/x'];

  AppSettings get _settings => SettingsScope.read(context);

  bool _isOp(String c) => _ops.contains(c);
  bool _isDigit(String c) => c.isNotEmpty && '0123456789'.contains(c);

  void _haptic([bool strong = false]) {
    if (!_settings.vibration) return;
    strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
  }

  /// True when the expression ends with a complete value (number, ")", "%", π or e).
  bool get _endsWithValue {
    if (_expr.isEmpty) return false;
    final last = _expr[_expr.length - 1];
    return _isDigit(last) || last == ')' || last == '%' || last == 'π' || last == 'e';
  }

  /// True when the expression ends with something a digit can't follow directly.
  bool get _endsWithClosedValue {
    if (_expr.isEmpty) return false;
    final last = _expr[_expr.length - 1];
    return last == ')' || last == '%' || last == 'π' || last == 'e';
  }

  String _close(String e) {
    var t = e;
    while (t.isNotEmpty && (_isOp(t[t.length - 1]) || t.endsWith('.'))) {
      t = t.substring(0, t.length - 1);
    }
    final open = '('.allMatches(t).length - ')'.allMatches(t).length;
    if (open > 0) t += ')' * open;
    return t;
  }

  String? _tryEval(String e) {
    if (e.isEmpty) return null;
    try {
      final v = ExpressionParser(_close(e), degrees: _degrees).parse();
      return formatNumber(v, decimals: _settings.decimalPlaces);
    } catch (_) {
      return null;
    }
  }

  void _update() {
    final isPlainNumber = RegExp(r'^−?[\d.]+$').hasMatch(_expr);
    _preview = (_expr.isEmpty || isPlainNumber) ? '' : (_tryEval(_expr) ?? '');
  }

  void _press(String key) {
    _haptic();
    setState(() {
      switch (key) {
        case 'AC':
          _expr = '';
          _preview = '';
          _justEvaluated = false;
          return;
        case '⌫':
          _backspace();
          break;
        case '=':
          _equals();
          return;
        case '( )':
          _addParen();
          break;
        case '.':
          _addDot();
          break;
        case '%':
          if (_endsWithValue) _expr += '%';
          _justEvaluated = false;
          break;
        case 'DEG':
          _degrees = !_degrees;
          break;
        case 'sin':
        case 'cos':
        case 'tan':
        case 'ln':
        case 'log':
          _addFunction('$key(');
          break;
        case '√':
          _addFunction('√(');
          break;
        case 'x²':
          if (_endsWithValue) _expr += '^2';
          _justEvaluated = false;
          break;
        case 'xʸ':
          _addOp('^');
          break;
        case '1/x':
          if (_endsWithValue) _expr += '^(−1)';
          _justEvaluated = false;
          break;
        case 'π':
        case 'e':
          _addConstant(key);
          break;
        default:
          if (_isOp(key)) {
            _addOp(key);
          } else {
            _addDigit(key);
          }
      }
      _update();
    });
  }

  void _startFresh() {
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
  }

  void _backspace() {
    _justEvaluated = false;
    if (_expr.isEmpty) return;
    for (final t in _funcTokens) {
      if (_expr.endsWith(t)) {
        _expr = _expr.substring(0, _expr.length - t.length);
        return;
      }
    }
    _expr = _expr.substring(0, _expr.length - 1);
  }

  void _addDigit(String d) {
    _startFresh();
    if (_endsWithClosedValue) _expr += '×';
    final m = RegExp(r'(\d+\.?\d*)$').firstMatch(_expr);
    if (m != null && m.group(1) == '0') {
      if (d == '0') return;
      _expr = _expr.substring(0, _expr.length - 1);
    }
    _expr += d;
  }

  void _addDot() {
    _startFresh();
    final m = RegExp(r'[\d.]*$').firstMatch(_expr);
    if (m != null && m.group(0)!.contains('.')) return;
    if (_endsWithClosedValue) {
      _expr += '×0';
    } else if (!_endsWithValue) {
      _expr += '0';
    }
    _expr += '.';
  }

  void _addFunction(String token) {
    _justEvaluated = false;
    if (_endsWithValue) _expr += '×';
    _expr += token;
  }

  void _addConstant(String c) {
    _startFresh();
    if (_endsWithValue) _expr += '×';
    _expr += c;
  }

  void _addOp(String op) {
    _justEvaluated = false;
    if (_expr.isEmpty) {
      if (op == '−') _expr = '−';
      return;
    }
    final last = _expr[_expr.length - 1];
    if (last == '(') {
      if (op == '−') _expr += op;
      return;
    }
    if (_isOp(last)) {
      if (_expr.length == 1) return;
      _expr = _expr.substring(0, _expr.length - 1) + op;
    } else {
      _expr += op;
    }
  }

  void _addParen() {
    _justEvaluated = false;
    final open = '('.allMatches(_expr).length;
    final close = ')'.allMatches(_expr).length;
    if (open > close && _endsWithValue) {
      _expr += ')';
    } else if (_endsWithValue) {
      _expr += '×(';
    } else {
      _expr += '(';
    }
  }

  void _equals() {
    if (_expr.isEmpty) return;
    final t = _close(_expr);
    try {
      final res = formatNumber(
        ExpressionParser(t, degrees: _degrees).parse(),
        decimals: _settings.decimalPlaces,
      );
      if (t != res) _settings.addHistory('$t = $res');
      _expr = res;
      _preview = '';
      _justEvaluated = true;
      _haptic(true);
    } catch (_) {
      _preview = 'Error';
      if (_settings.vibration) HapticFeedback.heavyImpact();
    }
  }

  // --- Copy, paste and share ---------------------------------------------

  /// The current answer as plain text other apps understand ("-1234.5").
  String get _plainResult {
    final value = (_preview.isNotEmpty && _preview != 'Error') ? _preview : (_expr.isEmpty ? '0' : _expr);
    return value.replaceAll('−', '-');
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _plainResult));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final value = parseInput(data?.text ?? '', _settings.numberStyle);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard has no number')));
      return;
    }
    setState(() {
      _startFresh();
      var number = formatNumber(value, decimals: 10);
      if (_endsWithValue) _expr += '×';
      if (number.startsWith('−') && _expr.isNotEmpty) number = '($number)';
      _expr += number;
      _update();
    });
  }

  void _share() {
    final res = _plainResult;
    final hasExpression = _preview.isNotEmpty && _preview != 'Error';
    shareText(hasExpression ? '${_close(_expr)} = ${res.replaceAll('-', '−')}' : res.replaceAll('-', '−'));
  }

  void _showDisplayMenu() {
    _haptic(true);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy result'),
              onTap: () {
                Navigator.pop(ctx);
                _copy();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Paste number'),
              onTap: () {
                Navigator.pop(ctx);
                _paste();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                _share();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final history = SettingsScope.of(ctx).history;
        final style = SettingsScope.of(ctx).numberStyle;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            child: history.isEmpty
                ? const SizedBox(height: 160, child: Center(child: Text('No history yet')))
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      for (final h in history)
                        ListTile(
                          title: Text(formatExpression(h, style), textAlign: TextAlign.right),
                          onTap: () {
                            setState(() {
                              _expr = h.split(' = ').last;
                              _justEvaluated = true;
                              _preview = '';
                            });
                            Navigator.pop(ctx);
                          },
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(text: h.replaceAll('−', '-')));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Copied')));
                          },
                        ),
                      TextButton.icon(
                        onPressed: () {
                          _settings.clearHistory();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear history'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // --- Layout ------------------------------------------------------------

  Widget _keyGrid(List<List<String>> rows, {bool small = false}) {
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final k in row)
                  Expanded(
                    child: _CalcButton(
                      label: k == 'DEG' ? (_degrees ? 'DEG' : 'RAD') : k,
                      kind: _kindOf(k),
                      small: small,
                      onTap: () => _press(k),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  _KeyKind _kindOf(String k) {
    if (k == '=') return _KeyKind.equals;
    if (const ['÷', '×', '−', '+'].contains(k)) return _KeyKind.op;
    if (const ['AC', '⌫', '%', '( )'].contains(k)) return _KeyKind.action;
    if (_sciKeys.contains(k)) return _KeyKind.scientific;
    return _KeyKind.digit;
  }

  List<List<String>> _sciRows(int perRow) {
    final rows = <List<String>>[];
    for (var i = 0; i < _sciKeys.length; i += perRow) {
      rows.add(_sciKeys.sublist(i, i + perRow));
    }
    return rows;
  }

  Widget _display(ColorScheme cs, NumberStyle style, {required bool compact}) {
    final shownExpr = _expr.isEmpty ? '0' : formatExpression(_expr, style);
    final shownPreview = _preview.isEmpty
        ? ' '
        : (_preview == 'Error' ? _preview : '= ${formatExpression(_preview, style)}');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _showDisplayMenu,
      onHorizontalDragEnd: (details) {
        // Swipe left or right on the display to delete the last character.
        if ((details.primaryVelocity ?? 0).abs() > 200 && _expr.isNotEmpty) {
          _haptic();
          setState(() {
            _backspace();
            _update();
          });
        }
      },
      child: Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                shownExpr,
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact ? 36 : 56,
                  fontWeight: FontWeight.w300,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                shownPreview,
                maxLines: 1,
                style: TextStyle(
                  fontSize: compact ? 20 : 28,
                  color: _preview == 'Error' ? cs.error : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = SettingsScope.of(context).numberStyle;
    final landscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final header = ScreenHeader(
      actions: [
        if (!landscape)
          IconButton(
            tooltip: _scientific ? 'Basic mode' : 'Scientific mode',
            isSelected: _scientific,
            icon: const Icon(Icons.functions),
            onPressed: () => setState(() => _scientific = !_scientific),
          ),
        IconButton(
          tooltip: 'History',
          icon: const Icon(Icons.history),
          onPressed: _showHistory,
        ),
      ],
    );

    if (landscape) {
      return Column(
        children: [
          header,
          Expanded(flex: 2, child: _display(cs, style, compact: true)),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _keyGrid(_sciRows(3), small: true)),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: _keyGrid(_basicRows, small: true)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        Expanded(flex: 2, child: _display(cs, style, compact: false)),
        if (_scientific)
          SizedBox(
            height: 112,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _keyGrid(_sciRows(6), small: true),
            ),
          ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _keyGrid(_basicRows),
          ),
        ),
      ],
    );
  }
}

enum _KeyKind { digit, op, action, equals, scientific }

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.kind,
    required this.onTap,
    this.small = false,
  });

  final String label;
  final _KeyKind kind;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg = cs.surfaceContainerHigh;
    Color fg = cs.onSurface;
    switch (kind) {
      case _KeyKind.equals:
        bg = cs.primary;
        fg = cs.onPrimary;
        break;
      case _KeyKind.op:
        bg = cs.primaryContainer;
        fg = cs.onPrimaryContainer;
        break;
      case _KeyKind.action:
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        break;
      case _KeyKind.scientific:
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        break;
      case _KeyKind.digit:
        break;
    }

    final big = kind == _KeyKind.op || kind == _KeyKind.equals;
    final fontSize = small ? (kind == _KeyKind.scientific ? 17.0 : 22.0) : (big ? 32.0 : 28.0);
    final radius = small ? 18.0 : 28.0;

    return Padding(
      padding: EdgeInsets.all(small ? 3 : 5),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Center(
            child: label == '⌫'
                ? Icon(Icons.backspace_outlined, color: fg, size: small ? 20 : 24)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400, color: fg),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
