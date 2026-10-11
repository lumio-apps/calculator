import 'package:flutter/material.dart';

import 'app_menu.dart';
import 'settings.dart';
import 'update_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _sectionTitle(context, 'Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                ],
                selected: {s.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (v) => s.themeMode = v.first,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (var i = 0; i < accentColors.length; i++)
                    Semantics(
                      label: 'Accent color ${i + 1}',
                      selected: i == s.accentIndex,
                      button: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => s.accentIndex = i,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i == s.accentIndex ? cs.onSurface : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: i == s.accentIndex ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _sectionTitle(context, 'Numbers'),
            ListTile(
              title: const Text('Number format'),
              subtitle: Text(s.numberStyle.example),
              trailing: DropdownButton<NumberStyle>(
                value: s.numberStyle,
                underline: const SizedBox.shrink(),
                onChanged: (v) {
                  if (v != null) s.numberStyle = v;
                },
                items: [
                  for (final style in NumberStyle.values)
                    DropdownMenuItem(value: style, child: Text(style.example)),
                ],
              ),
            ),
            ListTile(
              title: const Text('Decimal places'),
              subtitle: Text(s.decimalPlaces == 10 ? 'Up to 10 (automatic)' : 'Up to ${s.decimalPlaces}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Slider(
                value: s.decimalPlaces.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '${s.decimalPlaces}',
                onChanged: (v) => s.decimalPlaces = v.round(),
              ),
            ),
            _sectionTitle(context, 'Calculator'),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate when a key is pressed'),
              value: s.vibration,
              onChanged: (v) => s.vibration = v,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear history'),
              subtitle: Text('${s.history.length} saved calculations'),
              enabled: s.history.isNotEmpty,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text('All saved calculations will be deleted.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                    ],
                  ),
                );
                if (ok == true) s.clearHistory();
              },
            ),
            _sectionTitle(context, 'About'),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('Check for updates'),
              onTap: () => UpdateService.checkForUpdates(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Calculator'),
              subtitle: const Text('Free, open source, no ads, no tracking'),
              onTap: () => showAppAbout(context),
            ),
          ],
        ),
      ),
    );
  }
}
