import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update_service.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
      ),
      home: const CalculatorPage(),
    );
  }
}

/// Small recursive-descent parser: + - × ÷ % ( ) and unary minus.
class ExpressionParser {
  ExpressionParser(String input) : _s = input.replaceAll(' ', '');
  final String _s;
  int _i = 0;

  double parse() {
    final v = _expr();
    if (_i != _s.length) throw const FormatException('Unexpected input');
    return v;
  }

  double _expr() {
    var v = _term();
    while (_i < _s.length && (_s[_i] == '+' || _s[_i] == '−')) {
      final op = _s[_i++];
      final r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    var v = _unary();
    while (_i < _s.length && (_s[_i] == '×' || _s[_i] == '÷')) {
      final op = _s[_i++];
      final r = _unary();
      v = op == '×' ? v * r : v / r;
    }
    return v;
  }

  double _unary() {
    if (_i < _s.length && _s[_i] == '−') {
      _i++;
      return -_unary();
    }
    return _postfix();
  }

  double _postfix() {
    var v = _primary();
    while (_i < _s.length && _s[_i] == '%') {
      _i++;
      v /= 100;
    }
    return v;
  }

  double _primary() {
    if (_i < _s.length && _s[_i] == '(') {
      _i++;
      final v = _expr();
      if (_i >= _s.length || _s[_i] != ')') {
        throw const FormatException('Missing )');
      }
      _i++;
      return v;
    }
    final start = _i;
    while (_i < _s.length && (_isDigit(_s[_i]) || _s[_i] == '.')) {
      _i++;
    }
    if (start == _i) throw const FormatException('Number expected');
    return double.parse(_s.substring(start, _i));
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expr = '';
  String _preview = '';
  bool _justEvaluated = false;
  final List<String> _history = [];

  static const _ops = ['+', '−', '×', '÷'];

  bool _isOp(String c) => _ops.contains(c);
  bool _isDigit(String c) => c.isNotEmpty && '0123456789'.contains(c);

  String _format(double v) {
    if (v.isNaN || v.isInfinite) throw const FormatException('Math error');
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    var s = v.toStringAsFixed(10);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s == '-0' ? '0' : s.replaceAll('-', '−');
  }

  String? _tryEval(String e) {
    if (e.isEmpty) return null;
    var t = e;
    // Auto-close open brackets and drop a trailing operator for live preview.
    while (t.isNotEmpty && (_isOp(t[t.length - 1]) || t.endsWith('.'))) {
      t = t.substring(0, t.length - 1);
    }
    final open = '('.allMatches(t).length - ')'.allMatches(t).length;
    t += ')' * (open > 0 ? open : 0);
    try {
      return _format(ExpressionParser(t).parse());
    } catch (_) {
      return null;
    }
  }

  void _update() {
    final hasOp = _expr.split('').any(_isOp) || _expr.contains('%') || _expr.contains('(');
    _preview = hasOp ? (_tryEval(_expr) ?? '') : '';
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
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
          _justEvaluated = false;
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
          if (_expr.isNotEmpty &&
              (_isDigit(_expr[_expr.length - 1]) || _expr.endsWith(')') || _expr.endsWith('%'))) {
            _expr += '%';
          }
          _justEvaluated = false;
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

  void _addDigit(String d) {
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    if (_expr.endsWith(')') || _expr.endsWith('%')) _expr += '×';
    // Avoid leading zeros like "007".
    final m = RegExp(r'(\d+\.?\d*)$').firstMatch(_expr);
    if (m != null && m.group(1) == '0' && d != '0') {
      _expr = _expr.substring(0, _expr.length - 1);
    } else if (m != null && m.group(1) == '0' && d == '0') {
      return;
    }
    _expr += d;
  }

  void _addDot() {
    if (_justEvaluated) {
      _expr = '';
      _justEvaluated = false;
    }
    final m = RegExp(r'[\d.]*$').firstMatch(_expr);
    if (m != null && m.group(0)!.contains('.')) return;
    if (_expr.isEmpty || _isOp(_expr[_expr.length - 1]) || _expr.endsWith('(')) {
      _expr += '0';
    } else if (_expr.endsWith(')') || _expr.endsWith('%')) {
      _expr += '×0';
    }
    _expr += '.';
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
    final last = _expr.isEmpty ? '' : _expr[_expr.length - 1];
    final afterValue = _isDigit(last) || last == ')' || last == '%';
    if (open > close && afterValue) {
      _expr += ')';
    } else if (afterValue) {
      _expr += '×(';
    } else {
      _expr += '(';
    }
  }

  void _equals() {
    if (_expr.isEmpty) return;
    var t = _expr;
    while (t.isNotEmpty && (_isOp(t[t.length - 1]) || t.endsWith('.'))) {
      t = t.substring(0, t.length - 1);
    }
    final open = '('.allMatches(t).length - ')'.allMatches(t).length;
    if (open > 0) t += ')' * open;
    try {
      final res = _format(ExpressionParser(t).parse());
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

  Future<void> _showAbout() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Calculator',
      applicationVersion: 'Version ${info.version}',
      applicationLegalese: 'By Lumio Apps\nOpen source under the MIT License',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const rows = [
      ['AC', '⌫', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['( )', '0', '.', '='],
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'History',
                  icon: const Icon(Icons.history),
                  onPressed: _showHistory,
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  onSelected: (value) {
                    if (value == 'update') {
                      UpdateService.checkForUpdates(context);
                    } else if (value == 'about') {
                      _showAbout();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'update',
                      child: ListTile(
                        leading: Icon(Icons.system_update),
                        title: Text('Check for updates'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'about',
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('About'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _preview.isEmpty ? ' ' : (_preview == 'Error' ? _preview : '= $_preview'),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 28,
                          color: _preview == 'Error' ? cs.error : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    for (final row in rows)
                      Expanded(
                        child: Row(
                          children: [
                            for (final k in row)
                              Expanded(child: _CalcButton(label: k, onTap: () => _press(k))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEquals = label == '=';
    final isOp = const ['÷', '×', '−', '+'].contains(label);
    final isAction = const ['AC', '⌫', '%', '( )'].contains(label);

    Color bg = cs.surfaceContainerHigh;
    Color fg = cs.onSurface;
    if (isEquals) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (isOp) {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    } else if (isAction) {
      bg = cs.secondaryContainer;
      fg = cs.onSecondaryContainer;
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Center(
            child: label == '⌫'
                ? Icon(Icons.backspace_outlined, color: fg)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: isOp || isEquals ? 32 : 28,
                      fontWeight: FontWeight.w400,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
