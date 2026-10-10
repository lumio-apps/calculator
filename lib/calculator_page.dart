import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_menu.dart';
import 'expression_parser.dart';

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
  final List<String> _history = [];

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

  bool _isOp(String c) => _ops.contains(c);
  bool _isDigit(String c) => c.isNotEmpty && '0123456789'.contains(c);

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
      return formatNumber(ExpressionParser(_close(e), degrees: _degrees).parse());
    } catch (_) {
      return null;
    }
  }

  void _update() {
    final isPlainNumber = RegExp(r'^−?[\d.]+$').hasMatch(_expr);
    _preview = (_expr.isEmpty || isPlainNumber) ? '' : (_tryEval(_expr) ?? '');
  }

  void _press(String key) {
    HapticFeedback.selectionClick();
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
      final res = formatNumber(ExpressionParser(t, degrees: _degrees).parse());
      _history.insert(0, '$t = $res');
      if (_history.length > 50) _history.removeLast();
      _expr = res;
      _preview = '';
      _justEvaluated = true;
      HapticFeedback.lightImpact();
    } catch (_) {
      _preview = 'Error';
      HapticFeedback.heavyImpact();
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: _history.isEmpty
            ? const SizedBox(
                height: 160,
                child: Center(child: Text('No history yet')),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final h in _history)
                    ListTile(
                      title: Text(h, textAlign: TextAlign.right),
                      onTap: () {
                        setState(() {
                          _expr = h.split(' = ').last;
                          _justEvaluated = true;
                          _preview = '';
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  TextButton.icon(
                    onPressed: () {
                      setState(_history.clear);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear history'),
                  ),
                ],
              ),
      ),
    );
  }

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

  Widget _display(ColorScheme cs, {required bool compact}) {
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _expr.isEmpty ? '0' : _expr,
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
              _preview.isEmpty ? ' ' : (_preview == 'Error' ? _preview : '= $_preview'),
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 20 : 28,
                color: _preview == 'Error' ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          Expanded(flex: 2, child: _display(cs, compact: true)),
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
        Expanded(flex: 2, child: _display(cs, compact: false)),
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
