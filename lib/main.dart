import 'package:flutter/material.dart';

import 'calculator_page.dart';
import 'converter_page.dart';
import 'date_page.dart';
import 'neo.dart';
import 'settings.dart';
import 'tools_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(CalculatorApp(settings: settings));
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsScope(
        settings: settings,
        child: MaterialApp(
          title: 'Calculator',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settings.accent,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: settings.accent,
            brightness: Brightness.dark,
          ),
          home: const HomeShell(),
        ),
      ),
    );
  }
}

/// Holds the four sections and switches between them.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [CalculatorPage(), ConverterPage(), ToolsPage(), DatePage()];

  static const _items = [
    NeoNavItem(Icons.calculate_outlined, Icons.calculate, 'Calculator'),
    NeoNavItem(Icons.swap_horiz, Icons.swap_horiz, 'Converter'),
    NeoNavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Tools'),
    NeoNavItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Date'),
  ];

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final body = IndexedStack(index: _index, children: _pages);

    if (landscape) {
      return NeoBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Row(
              children: [
                NeoNavBar(
                  items: _items,
                  selected: _index,
                  onSelected: _select,
                  vertical: true,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
    }

    return NeoBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(bottom: false, child: body),
        bottomNavigationBar: SafeArea(
          top: false,
          child: NeoNavBar(items: _items, selected: _index, onSelected: _select),
        ),
      ),
    );
  }
}
