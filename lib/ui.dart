/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-12 18:09:05
 * @Description: file content
 */

import 'package:flutter/material.dart';
import 'package:new_launcher/logger.dart';
import 'package:provider/provider.dart';
// Contains some custom widgets here

/// ``customInfoWidget`` is designed for displaying a message
/// with informations. The most important part of a "info" should be
/// displayed on title area. And the second important part is displayed
/// on subtitle.
class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? icon;
  final void Function()? onTap;

  const InfoCard({
    Key? key,
    required this.title,
    this.subtitle = "",
    this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          textAlign: TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: icon,
      ),
    );
  }
}

Widget customInfoWidget(
    {required String title,
    String subtitle = "",
    Widget? icon,
    void Function()? onTap}) {
  return InfoCard(
    title: title,
    subtitle: subtitle,
    icon: icon,
    onTap: onTap,
  );
}

/// ``customSuggestWidget`` is designed for displaying a suggest action
/// above the input box.
Widget customSuggestWidget(
    {required String name, required void Function() onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      elevation: 0,
    ),
    child: Text(name),
  );
}

Widget customTextSettingWidget(
    {required String key,
    required var value,
    required void Function(String) onSubmitted}) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      title: TextField(
        textAlign: TextAlign.left,
        style: TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: value.toString(),
          labelText: key,
          border: InputBorder.none,
        ),
        onSubmitted: onSubmitted,
      ),
    ),
  );
}

class CustomBoolSettingWidget extends StatefulWidget {
  final String settingKey;
  final bool value;
  final void Function(bool) onChanged;

  const CustomBoolSettingWidget({
    Key? key,
    required this.settingKey,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CustomBoolSettingWidget> createState() =>
      CustomBoolSettingWidgetState();
}

class CustomBoolSettingWidgetState extends State<CustomBoolSettingWidget> {
  late String key;
  late bool value;
  late void Function(bool) onChanged;
  late String subtitle;

  @override
  void initState() {
    super.initState();
    key = widget.settingKey;
    value = widget.value;
    onChanged = widget.onChanged;
    subtitle = "is " + value.toString();
  }

  void updateUI(bool newValue) {
    setState(() {
      value = newValue;
      subtitle = "is " + newValue.toString();
      onChanged.call(newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          key,
          textAlign: TextAlign.left,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Switch(value: value, onChanged: updateUI),
      ),
    );
  }
}

class CardOpacitySlider extends StatefulWidget {
  final double value;
  final void Function(double) onChanged;

  const CardOpacitySlider({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<CardOpacitySlider> createState() => _CardOpacitySliderState();
}

class _CardOpacitySliderState extends State<CardOpacitySlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          "Card Opacity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Opacity: ${(_value * 100).toInt()}%"),
        trailing: SizedBox(
          width: 150,
          child: Slider(
            value: _value,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (newValue) {
              setState(() {
                _value = newValue;
              });
              widget.onChanged(newValue);
            },
          ),
        ),
      ),
    );
  }
}

class WallpaperPickerButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const WallpaperPickerButton({
    Key? key,
    required this.onTap,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.filled(
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Tap to select from gallery"),
        trailing: IconButton(
          icon: Icon(Icons.photo_library),
          style: IconButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class LogViewerWidget extends StatefulWidget {
  const LogViewerWidget({Key? key}) : super(key: key);

  @override
  State<LogViewerWidget> createState() => _LogViewerWidgetState();
}

class _LogViewerWidgetState extends State<LogViewerWidget> {
  LogLevel? _filterLevel;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final logger = context.watch<LoggerModel>();
    var logs = logger.logs;

    if (_filterLevel != null) {
      logs = logger.filterByLevel(_filterLevel!);
    }
    if (_searchQuery.isNotEmpty) {
      logs = logs.where((l) =>
          l.message.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text("Logs: ${logs.length}", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
                SizedBox(width: 8),
                DropdownButton<LogLevel?>(
                  value: _filterLevel,
                  items: [
                    DropdownMenuItem(value: null, child: Text("All")),
                    DropdownMenuItem(value: LogLevel.error, child: Text("Error")),
                    DropdownMenuItem(value: LogLevel.warning, child: Text("Warn")),
                    DropdownMenuItem(value: LogLevel.info, child: Text("Info")),
                    DropdownMenuItem(value: LogLevel.debug, child: Text("Debug")),
                  ],
                  onChanged: (v) => setState(() => _filterLevel = v),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[logs.length - index - 1];
                return ListTile(
                  dense: true,
                  leading: Icon(log.levelIcon, color: _getLevelColor(log.level), size: 20),
                  title: Text(log.message, style: TextStyle(fontSize: 12)),
                  subtitle: Text(
                    "${log.source ?? ''} - ${log.timestamp.toIso8601String()}",
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => logger.clear(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  child: Text("Clear"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (level) {
      case LogLevel.error: return colorScheme.error;
      case LogLevel.warning: return colorScheme.tertiary;
      case LogLevel.info: return colorScheme.primary;
      case LogLevel.debug: return colorScheme.onSurfaceVariant;
    }
  }
}
