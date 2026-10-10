import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'update_service.dart';

/// The ⋮ menu shared by every screen: Check for updates and About.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Calculator',
      applicationVersion: 'Version ${info.version}',
      applicationLegalese: 'By Lumio Apps\nOpen source under the MIT License',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: (value) {
        if (value == 'update') {
          UpdateService.checkForUpdates(context);
        } else if (value == 'about') {
          _showAbout(context);
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
