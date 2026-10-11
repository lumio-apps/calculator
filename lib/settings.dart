import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How numbers are grouped and which decimal separator is shown.
enum NumberStyle {
  plain('1234567.89'),
  comma('1,234,567.89'),
  dot('1.234.567,89'),
  space('1 234 567,89'),
  indian('12,34,567.89');

  const NumberStyle(this.example);
  final String example;

  String get groupSeparator => switch (this) {
        NumberStyle.plain => '',
        NumberStyle.comma => ',',
        NumberStyle.dot => '.',
        NumberStyle.space => ' ',
        NumberStyle.indian => ',',
      };

  String get decimalSeparator => switch (this) {
        NumberStyle.dot || NumberStyle.space => ',',
        _ => '.',
      };
}

/// Accent colors the user can choose from.
const accentColors = <Color>[
  Color(0xFF6C63FF),
  Color(0xFF2F80ED),
  Color(0xFF14B8A6),
  Color(0xFF22A35A),
  Color(0xFFF97316),
  Color(0xFFE5487F),
];

/// App-wide settings and the saved calculation history, stored on the device.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs) {
    _themeMode = ThemeMode.values[(_prefs.getInt('themeMode') ?? 0).clamp(0, ThemeMode.values.length - 1)];
    _accentIndex = (_prefs.getInt('accent') ?? 0).clamp(0, accentColors.length - 1);
    _vibration = _prefs.getBool('vibration') ?? true;
    _decimalPlaces = (_prefs.getInt('decimals') ?? 10).clamp(0, 10);
    _numberStyle = NumberStyle.values[(_prefs.getInt('numberStyle') ?? 1).clamp(0, NumberStyle.values.length - 1)];
    _history = _prefs.getStringList('history') ?? <String>[];
  }

  static Future<AppSettings> load() async => AppSettings._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  late ThemeMode _themeMode;
  late int _accentIndex;
  late bool _vibration;
  late int _decimalPlaces;
  late NumberStyle _numberStyle;
  late List<String> _history;

  ThemeMode get themeMode => _themeMode;
  int get accentIndex => _accentIndex;
  Color get accent => accentColors[_accentIndex];
  bool get vibration => _vibration;
  int get decimalPlaces => _decimalPlaces;
  NumberStyle get numberStyle => _numberStyle;
  List<String> get history => List.unmodifiable(_history);

  set themeMode(ThemeMode v) {
    _themeMode = v;
    _prefs.setInt('themeMode', v.index);
    notifyListeners();
  }

  set accentIndex(int v) {
    _accentIndex = v;
    _prefs.setInt('accent', v);
    notifyListeners();
  }

  set vibration(bool v) {
    _vibration = v;
    _prefs.setBool('vibration', v);
    notifyListeners();
  }

  set decimalPlaces(int v) {
    _decimalPlaces = v;
    _prefs.setInt('decimals', v);
    notifyListeners();
  }

  set numberStyle(NumberStyle v) {
    _numberStyle = v;
    _prefs.setInt('numberStyle', v.index);
    notifyListeners();
  }

  void addHistory(String entry) {
    _history.insert(0, entry);
    if (_history.length > 100) _history.removeRange(100, _history.length);
    _prefs.setStringList('history', _history);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _prefs.setStringList('history', _history);
    notifyListeners();
  }

  /// Formats [v] with the user's grouping style, e.g. 1234.5 → "1,234.50".
  String money(double v) => formatGrouped(v, _numberStyle, decimals: 2, trimZeros: false);

  /// Formats [v] with the user's grouping style, trimming trailing zeros.
  String number(double v, {int decimals = 4}) => formatGrouped(v, _numberStyle, decimals: decimals);
}

/// Makes [AppSettings] available to every screen.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  /// Use in build methods; the widget rebuilds when settings change.
  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// Use in callbacks; does not subscribe to changes.
  static AppSettings read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

/// Groups the digits of a plain integer string, e.g. "1234567" → "1,234,567".
String groupDigits(String digits, NumberStyle style) {
  final sep = style.groupSeparator;
  if (sep.isEmpty || digits.length <= 3) return digits;
  final buf = StringBuffer();
  if (style == NumberStyle.indian) {
    final head = digits.substring(0, digits.length - 3);
    final tail = digits.substring(digits.length - 3);
    for (var i = 0; i < head.length; i++) {
      if (i > 0 && (head.length - i) % 2 == 0) buf.write(sep);
      buf.write(head[i]);
    }
    buf
      ..write(sep)
      ..write(tail);
    return buf.toString();
  }
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(sep);
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Formats every number inside a calculator expression for display.
String formatExpression(String expr, NumberStyle style) {
  if (style == NumberStyle.plain) return expr;
  return expr.replaceAllMapped(RegExp(r'(\d+)(\.(\d*))?'), (m) {
    final intPart = groupDigits(m.group(1)!, style);
    if (m.group(2) == null) return intPart;
    return '$intPart${style.decimalSeparator}${m.group(3) ?? ''}';
  });
}

/// Formats a value with grouping and a fixed number of decimals.
String formatGrouped(double v, NumberStyle style, {int decimals = 2, bool trimZeros = true}) {
  if (v.isNaN || v.isInfinite) return '—';
  if (v.abs() >= 1e15) return v.toStringAsExponential(4);
  var s = v.abs().toStringAsFixed(decimals);
  if (trimZeros && s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  final parts = s.split('.');
  var out = groupDigits(parts[0], style);
  if (parts.length > 1) out += '${style.decimalSeparator}${parts[1]}';
  final isZero = double.tryParse(s) == 0;
  return (v < 0 && !isZero) ? '−$out' : out;
}
