import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/card_config.dart';
import 'package:new_launcher/providers/provider_wallpaper.dart';
import 'package:new_launcher/settings_page.dart';

MyProvider providerSettings = MyProvider(
    name: "Settings",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
}

Future<void> _initActions() async {
  // Settings card entry widget
  Global.infoModel.addCard(CardConfig(
      key: "Settings",
      widget: Builder(
        builder: (context) => Card.filled(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Settings'),
                ],
              ),
            ),
          ),
        ),
      ),
      type: CardType.SETTINGS,
      size: CardSize.LARGE,
      layout: CardLayout.LIST,
title: "Settings"));
}

Future<void> _update() async {
  _initActions();
}