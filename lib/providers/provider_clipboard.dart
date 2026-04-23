import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ClipboardModel clipboardModel = ClipboardModel();

MyProvider providerClipboard = MyProvider(
    name: "Clipboard",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Clipboard History',
      keywords: 'clipboard history copy paste clip text snippet',
      action: () {
        Global.infoModel.addInfo("ClipboardHistory", "Clipboard History",
            subtitle: "View and manage copied text",
            icon: Icon(Icons.content_paste),
            onTap: () {});
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await clipboardModel.init();
  Global.infoModel.addInfoWidget(
      "Clipboard",
      ChangeNotifierProvider.value(
          value: clipboardModel,
          builder: (context, child) => ClipboardCard()),
      title: "Clipboard History");
}

Future<void> _update() async {
  await clipboardModel.refresh();
}

class ClipboardEntry {
  final String text;
  final DateTime timestamp;

  ClipboardEntry({
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ClipboardEntry.fromJson(Map<String, dynamic> json) => ClipboardEntry(
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class ClipboardModel extends ChangeNotifier {
  List<ClipboardEntry> _entries = [];
  static const int maxEntries = 15;
  static const String _entriesKey = 'Clipboard.Entries';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<ClipboardEntry> get entries => List.unmodifiable(_entries);
  int get length => _entries.length;
  bool get isInitialized => _isInitialized;
  bool get hasEntries => _entries.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadEntries();
    _isInitialized = true;
    Global.loggerModel.info("Clipboard initialized with ${_entries.length} entries", source: "Clipboard");
    notifyListeners();
  }

  Future<void> _loadEntries() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final entriesJson = prefs.getStringList(_entriesKey);
    if (entriesJson != null) {
      try {
        _entries = entriesJson.map((json) {
          final parts = json.split('|');
          return ClipboardEntry(
            text: parts[0],
            timestamp: DateTime.parse(parts[1]),
          );
        }).toList();
      } catch (e) {
        _entries = [];
        Global.loggerModel.error("Failed to load clipboard entries: $e", source: "Clipboard");
      }
    }
  }

  Future<void> _saveEntries() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final entriesJson = _entries.map((e) =>
        '${e.text}|${e.timestamp.toIso8601String()}'
      ).toList();
      await prefs.setStringList(_entriesKey, entriesJson);
      Global.loggerModel.info("Saved ${_entries.length} clipboard entries", source: "Clipboard");
    } catch (e) {
      Global.loggerModel.error("Failed to save clipboard entries: $e", source: "Clipboard");
    }
  }

  Future<void> refresh() async {
    await _loadEntries();
    notifyListeners();
    Global.loggerModel.info("Clipboard refreshed", source: "Clipboard");
  }

  Future<void> addEntry(String text) async {
    if (text.trim().isEmpty) return;

    final entry = ClipboardEntry(
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    _entries.insert(0, entry);

    if (_entries.length > maxEntries) {
      _entries.removeLast();
    }

    notifyListeners();
    await _saveEntries();
    final preview = text.trim().length > 20 ? text.trim().substring(0, 20) : text.trim();
    Global.loggerModel.info("Added clipboard entry: $preview...", source: "Clipboard");
  }

  Future<void> copyToSystemClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Global.loggerModel.info("Copied to system clipboard: ${text.length > 20 ? text.substring(0, 20) : text}...", source: "Clipboard");
  }

  Future<void> captureFromSystemClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      await addEntry(data.text!);
    }
  }

  void deleteEntry(int index) {
    if (index < 0 || index >= _entries.length) return;

    _entries.removeAt(index);
    notifyListeners();
    _saveEntries();
    Global.loggerModel.info("Deleted clipboard entry at index $index", source: "Clipboard");
  }

  void clearAllEntries() {
    _entries.clear();
    notifyListeners();
    _saveEntries();
    Global.loggerModel.info("Cleared all clipboard entries", source: "Clipboard");
  }

  void addTestEntry(ClipboardEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  void loadEntries(List<ClipboardEntry> entries) {
    _entries.clear();
    for (final entry in entries) {
      _entries.add(entry);
      if (_entries.length >= maxEntries) break;
    }
    notifyListeners();
    _saveEntries();
  }
}

class ClipboardCard extends StatefulWidget {
  @override
  State<ClipboardCard> createState() => _ClipboardCardState();
}

class _ClipboardCardState extends State<ClipboardCard> {
  @override
  Widget build(BuildContext context) {
    final clipboard = context.watch<ClipboardModel>();

    if (!clipboard.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.content_paste, size: 24),
              SizedBox(width: 12),
              Text("Clipboard: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Clipboard History",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (clipboard.hasEntries)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear all entries",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddDialog(context),
                      tooltip: "Add entry",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.content_paste_go, size: 18),
                      onPressed: () async {
                        await clipboard.captureFromSystemClipboard();
                        if (clipboard.entries.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Captured from clipboard"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      tooltip: "Capture from clipboard",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!clipboard.hasEntries)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No clipboard history. Tap + to add or capture.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: clipboard.length,
                itemBuilder: (context, index) {
                  final entry = clipboard.entries[index];
                  return _buildEntryItem(context, index, entry);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryItem(BuildContext context, int index, ClipboardEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayText = entry.text.length > 40 ? '${entry.text.substring(0, 40)}...' : entry.text;

    final timeDiff = DateTime.now().difference(entry.timestamp);
    String timeStr;
    if (timeDiff.inMinutes < 1) {
      timeStr = "Just now";
    } else if (timeDiff.inMinutes < 60) {
      timeStr = "${timeDiff.inMinutes}m ago";
    } else if (timeDiff.inHours < 24) {
      timeStr = "${timeDiff.inHours}h ago";
    } else {
      timeStr = "${timeDiff.inDays}d ago";
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(Icons.content_copy, size: 18, color: colorScheme.primary),
      title: Text(
        displayText,
        style: TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        timeStr,
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
      ),
      onTap: () async {
        await context.read<ClipboardModel>().copyToSystemClipboard(entry.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Copied to clipboard"),
            duration: Duration(seconds: 1),
          ),
        );
      },
      trailing: IconButton(
        icon: Icon(Icons.close, size: 16),
        onPressed: () => context.read<ClipboardModel>().deleteEntry(index),
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Entries"),
        content: Text("This will delete all clipboard history. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<ClipboardModel>().clearAllEntries();
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Clipboard Entry"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter text to save...",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await context.read<ClipboardModel>().addEntry(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );

    controller.dispose();
  }
}