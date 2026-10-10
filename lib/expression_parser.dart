import 'dart:math' as math;

/// Recursive-descent parser for calculator expressions.
///
/// Supports: + − × ÷ ^ % ( ), unary minus, constants π and e,
/// and the functions sin, cos, tan, ln, log and √.
class ExpressionParser {
  ExpressionParser(String input, {this.degrees = true}) : _s = input.replaceAll(' ', '');

  final String _s;
  final bool degrees;
  int _i = 0;

  static const functions = ['sin', 'cos', 'tan', 'ln', 'log', '√'];

  double parse() {
    final v = _expr();
    if (_i != _s.length) throw const FormatException('Unexpected input');
    return v;
  }

  bool _peek(String c) => _i < _s.length && _s[_i] == c;

  double _expr() {
    var v = _term();
    while (_peek('+') || _peek('−')) {
      final op = _s[_i++];
      final r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    var v = _unary();
    while (_peek('×') || _peek('÷')) {
      final op = _s[_i++];
      final r = _unary();
      v = op == '×' ? v * r : v / r;
    }
    return v;
  }

  double _unary() {
    if (_peek('−')) {
      _i++;
      return -_unary();
    }
    return _power();
  }

  double _power() {
    final base = _postfix();
    if (_peek('^')) {
      _i++;
      final exponent = _unary(); // right-associative
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  double _postfix() {
    var v = _primary();
    while (_peek('%')) {
      _i++;
      v /= 100;
    }
    return v;
  }

  double _primary() {
    if (_peek('(')) {
      _i++;
      final v = _expr();
      if (!_peek(')')) throw const FormatException('Missing )');
      _i++;
      return v;
    }
    if (_peek('π')) {
      _i++;
      return math.pi;
    }
    if (_peek('e')) {
      _i++;
      return math.e;
    }
    for (final f in functions) {
      if (_s.startsWith(f, _i)) {
        _i += f.length;
        final arg = _primary();
        return _apply(f, arg);
      }
    }
    final start = _i;
    while (_i < _s.length && (_isDigit(_s[_i]) || _s[_i] == '.')) {
      _i++;
    }
    if (start == _i) throw const FormatException('Number expected');
    return double.parse(_s.substring(start, _i));
  }

  double _apply(String f, double x) {
    final rad = degrees ? x * math.pi / 180 : x;
    switch (f) {
      case 'sin':
        return _clean(math.sin(rad));
      case 'cos':
        return _clean(math.cos(rad));
      case 'tan':
        final c = _clean(math.cos(rad));
        if (c == 0) throw const FormatException('Undefined');
        return _clean(math.sin(rad) / math.cos(rad));
      case 'ln':
        if (x <= 0) throw const FormatException('Undefined');
        return math.log(x);
      case 'log':
        if (x <= 0) throw const FormatException('Undefined');
        return math.log(x) / math.ln10;
      case '√':
        if (x < 0) throw const FormatException('Undefined');
        return math.sqrt(x);
    }
    throw const FormatException('Unknown function');
  }

  /// Removes floating point noise such as sin(180°) = 1.2e-16.
  double _clean(double v) => v.abs() < 1e-12 ? 0 : v;

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

/// Formats a result for display, using × 10^n for very large or small values.
String formatNumber(double v) {
  if (v.isNaN || v.isInfinite) throw const FormatException('Math error');
  if (v.abs() < 1e-12) return '0';
  final a = v.abs();
  String s;
  if (a >= 1e15 || a < 1e-6) {
    final parts = v.toStringAsExponential(9).split('e');
    var mantissa = parts[0];
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    final exponent = int.parse(parts[1]);
    s = '$mantissa×10^$exponent';
  } else if (v == v.roundToDouble()) {
    s = v.toInt().toString();
  } else {
    s = v.toStringAsFixed(10);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('-', '−');
}
