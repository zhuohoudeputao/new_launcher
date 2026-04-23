import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/setting.dart';

MyProvider providerSettings = MyProvider(
    name: "Settings",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Open settings',
      keywords: 'settings launcher configuration options preferences',
      action: () {
        navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (BuildContext context) => Setting()));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  Global.infoModel.addInfoWidget(
      "SettingsCard",
      SettingsCard(),
      title: "Settings");
}

Future<void> _update() async {
  Global.infoModel.addInfoWidget(
      "SettingsCard",
      SettingsCard(),
      title: "Settings");
}

class SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card.filled(
      child: ListTile(
        leading: Icon(
          Icons.settings,
          color: colorScheme.primary,
        ),
        title: Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Tap to customize launcher"),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: () {
          navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (BuildContext context) => Setting()));
        },
      ),
    );
  }
}