import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'settings_page.dart';
import 'update_service.dart';

/// Shows the About dialog with the installed version.
Future<void> showAppAbout(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  showAboutDialog(
    context: context,
    applicationName: 'Calculator',
    applicationVersion: 'Version ${info.version}',
    applicationLegalese: 'By Lumio Apps\nOpen source under the MIT License\ngithub.com/lumio-apps/calculator',
  );
}

/// The ⋮ menu shared by every screen.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: (value) {
        switch (value) {
          case 'settings':
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
          case 'update':
            UpdateService.checkForUpdates(context);
          case 'about':
            showAppAbout(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
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
    );
  }
}

/// A simple screen header: title on the left, actions and the menu on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, this.title, this.actions = const []});

  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
      child: Row(
        children: [
          if (title != null)
            Text(title!, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          ...actions,
          const AppMenuButton(),
        ],
      ),
    );
  }
}
