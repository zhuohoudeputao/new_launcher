/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 21:40:17
 * @Description: Settings Page for AI Launcher
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/ui.dart';
import 'package:new_launcher/ui/settings/api_keys.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _themeMode = 'system';
  double _cardOpacity = 0.7;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeMode = await Global.getValue('Theme.Mode', 'system');
    final cardOpacity = await Global.getValue('CardOpacity', 0.7);
    setState(() {
      _themeMode = themeMode as String;
      _cardOpacity = cardOpacity as double;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsModel = context.watch<SettingsModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        scrolledUnderElevation: 0, // Material 3 standard
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Settings Section Header
          _buildSectionHeader('AI Settings', Icons.psychology, colorScheme),
          const SizedBox(height: 8),

          // AI API Keys Navigation Button
          Card.filled(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const APIKeysSettings()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(Icons.key),
                title: const Text('AI API Keys'),
                subtitle: const Text('Configure API keys for AI providers'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 24),

          // Theme Section Header
          _buildSectionHeader('Theme', Icons.palette, colorScheme),
          const SizedBox(height: 8),

          // Theme Mode Selector
          DarkModeOptionSelector(
            currentMode: _themeMode,
            onChanged: (newMode) {
              setState(() {
                _themeMode = newMode;
              });
              Global.settingsModel.saveValue('Theme.Mode', newMode);
              Global.updateThemeMode(newMode);
            },
          ),
          const SizedBox(height: 8),

          // Card Opacity Slider
CardOpacitySlider(
            value: _cardOpacity,
            onChanged: (newValue) {
              setState(() {
                _cardOpacity = newValue;
              });
              Global.cardOpacityValue = newValue;
              Global.settingsModel.saveValue('CardOpacity', newValue);
              Global.refreshTheme();
            },
          ),
          const SizedBox(height: 8),

          // Wallpaper Settings Button
          Card.filled(
            child: InkWell(
              onTap: () async {
                try {
                  final channel = MethodChannel('accessibility_service');
                  final success = await channel.invokeMethod<bool>('openSettings', {
                    'action': 'android.intent.action.SET_WALLPAPER'
                  });
                  if (success == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to open wallpaper settings')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to open wallpaper settings')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(Icons.wallpaper),
                title: const Text('Change Wallpaper'),
                subtitle: const Text('Open Android wallpaper settings'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Providers Section Header
          _buildSectionHeader('Providers', Icons.widgets, colorScheme),
          const SizedBox(height: 8),

          // Provider Toggles
          ...Global.providerList.map((provider) {
            return Card(
              color: Theme.of(context).cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(provider.name),
                subtitle: Text('${Global.getProviderCardKeys(provider.name).length} cards'),
                value: settingsModel.isProviderEnabled(provider.name),
                onChanged: (bool value) {
                  settingsModel.setProviderEnabled(provider.name, value);
                },
              ),
            );
          }),
          const SizedBox(height: 24),

          // Display Section Header
          _buildSectionHeader('Display', Icons.display_settings, colorScheme),
          const SizedBox(height: 8),

          // Smart Sorting Toggle
          Card(
            color: Theme.of(context).cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Smart Sorting'),
              subtitle: const Text('Sort cards based on usage patterns'),
              value: settingsModel.isSmartSortingEnabled(),
              onChanged: (bool value) {
                settingsModel.setSmartSortingEnabled(value);
              },
            ),
          ),
          const SizedBox(height: 24),

          // About Section Header
          _buildSectionHeader('About', Icons.info, colorScheme),
          const SizedBox(height: 8),

          // App Info
          Card(
            color: Theme.of(context).cardColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('App Name'),
                  subtitle: const Text('AI Launcher'),
                ),
                ListTile(
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  title: const Text('Description'),
                  subtitle: const Text('Flutter-based Android launcher with command-based interface'),
                ),
                ListTile(
                  title: const Text('Developer'),
                  subtitle: const Text('zhuohoudeputao'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Card.filled(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}