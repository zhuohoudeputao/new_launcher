import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

AnniversaryModel anniversaryModel = AnniversaryModel();

MyProvider providerAnniversary = MyProvider(
  name: "Anniversary",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Add Anniversary',
      keywords: 'anniversary birthday recurring event date add',
      action: () {
        Global.infoModel.addInfo("AddAnniversary", "Add Anniversary",
            subtitle: "Tap to add a recurring event like birthday or anniversary",
            icon: Icon(Icons.cake),
            onTap: () => _showAddAnniversaryDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await anniversaryModel.init();
  Global.infoModel.addInfoWidget(
    "Anniversary",
    ChangeNotifierProvider.value(
      value: anniversaryModel,
      builder: (context, child) => AnniversaryCard(),
    ),
    title: "Anniversaries",
  );
}

Future<void> _update() async {
  await anniversaryModel.refresh();
}

void _showAddAnniversaryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddAnniversaryDialog(),
  );
}

void _showEditAnniversaryDialog(BuildContext context, int index, AnniversaryEntry entry) {
  showDialog(
    context: context,
    builder: (context) => EditAnniversaryDialog(index: index, entry: entry),
  );
}

class AnniversaryEntry {
  final String name;
  final int month;
  final int day;
  final int? year;
  final DateTime createdAt;

  AnniversaryEntry({
    required this.name,
    required this.month,
    required this.day,
    this.year,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DateTime getNextOccurrence() {
    final now = DateTime.now();
    int nextYear = now.year;
    
    if (month < now.month || (month == now.month && day < now.day)) {
      nextYear++;
    }
    
    return DateTime(nextYear, month, day);
  }

  int getDaysUntilNext() {
    final next = getNextOccurrence();
    final now = DateTime.now();
    return next.difference(now).inDays;
  }

  int? getOccurrences() {
    if (year == null) return null;
    final now = DateTime.now();
    int nextYear = now.year;
    if (month < now.month || (month == now.month && day < now.day)) {
      nextYear++;
    }
    return nextYear - year!;
  }

  String toJsonString() {
    return '$name|$month|$day|$year|${createdAt.toIso8601String()}';
  }

  factory AnniversaryEntry.fromJsonString(String jsonStr) {
    final parts = jsonStr.split('|');
    return AnniversaryEntry(
      name: parts[0],
      month: int.parse(parts[1]),
      day: int.parse(parts[2]),
      year: parts[3] != 'null' ? int.parse(parts[3]) : null,
      createdAt: DateTime.parse(parts[4]),
    );
  }
}

class AnniversaryModel extends ChangeNotifier {
  List<AnniversaryEntry> _anniversaries = [];
  static const int maxAnniversaries = 15;
  static const String _anniversariesKey = 'Anniversary.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<AnniversaryEntry> get anniversaries => List.unmodifiable(_anniversaries);
  int get length => _anniversaries.length;
  bool get isInitialized => _isInitialized;
  bool get hasAnniversaries => _anniversaries.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAnniversaries();
    _isInitialized = true;
    Global.loggerModel.info("Anniversary initialized with ${_anniversaries.length} anniversaries", source: "Anniversary");
    notifyListeners();
  }

  Future<void> _loadAnniversaries() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final anniversaryStrings = prefs.getStringList(_anniversariesKey);
    if (anniversaryStrings != null) {
      _anniversaries = anniversaryStrings
          .map((s) => AnniversaryEntry.fromJsonString(s))
          .toList();
    }
  }

  Future<void> _saveAnniversaries() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final anniversaryStrings = _anniversaries.map((a) => a.toJsonString()).toList();
    await prefs.setStringList(_anniversariesKey, anniversaryStrings);
    Global.loggerModel.info("Saved ${_anniversaries.length} anniversaries", source: "Anniversary");
  }

  Future<void> refresh() async {
    await _loadAnniversaries();
    notifyListeners();
    Global.loggerModel.info("Anniversary refreshed", source: "Anniversary");
  }

  void addAnniversary(String name, int month, int day, int? year) {
    if (name.trim().isEmpty) return;

    final entry = AnniversaryEntry(
      name: name.trim(),
      month: month,
      day: day,
      year: year,
      createdAt: DateTime.now(),
    );

    _anniversaries.insert(0, entry);

    if (_anniversaries.length > maxAnniversaries) {
      _anniversaries.removeLast();
    }

    notifyListeners();
    _saveAnniversaries();
    Global.loggerModel.info("Added anniversary: $name", source: "Anniversary");
  }

  void updateAnniversary(int index, String name, int month, int day, int? year) {
    if (index < 0 || index >= _anniversaries.length) return;
    if (name.trim().isEmpty) {
      deleteAnniversary(index);
      return;
    }

    _anniversaries[index] = AnniversaryEntry(
      name: name.trim(),
      month: month,
      day: day,
      year: year,
      createdAt: _anniversaries[index].createdAt,
    );
    notifyListeners();
    _saveAnniversaries();
    Global.loggerModel.info("Updated anniversary at index $index", source: "Anniversary");
  }

  void deleteAnniversary(int index) {
    if (index < 0 || index >= _anniversaries.length) return;

    final removedName = _anniversaries[index].name;
    _anniversaries.removeAt(index);
    notifyListeners();
    _saveAnniversaries();
    Global.loggerModel.info("Deleted anniversary: $removedName", source: "Anniversary");
  }

  void clearAllAnniversaries() {
    _anniversaries.clear();
    notifyListeners();
    _saveAnniversaries();
    Global.loggerModel.info("Cleared all anniversaries", source: "Anniversary");
  }

  String formatDaysUntil(AnniversaryEntry entry) {
    final days = entry.getDaysUntilNext();
    
    if (days == 0) {
      return "Today!";
    } else if (days == 1) {
      return "Tomorrow";
    } else if (days < 7) {
      return "$days days";
    } else if (days < 30) {
      final weeks = days ~/ 7;
      return "$weeks weeks";
    } else if (days < 365) {
      final months = days ~/ 30;
      return "$months months";
    } else {
      return "$days days";
    }
  }
}

class AnniversaryCard extends StatefulWidget {
  @override
  State<AnniversaryCard> createState() => _AnniversaryCardState();
}

class _AnniversaryCardState extends State<AnniversaryCard> {
  @override
  Widget build(BuildContext context) {
    final anniversaries = context.watch<AnniversaryModel>();

    if (!anniversaries.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.cake, size: 24),
              SizedBox(width: 12),
              Text("Anniversaries: Loading..."),
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
                  "Anniversaries",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (anniversaries.hasAnniversaries)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear all anniversaries",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddAnniversaryDialog(context),
                      tooltip: "Add anniversary",
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!anniversaries.hasAnniversaries)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No anniversaries. Tap + to add one.",
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
                itemCount: anniversaries.length,
                itemBuilder: (context, index) {
                  final entry = anniversaries.anniversaries[index];
                  return _buildAnniversaryItem(context, index, entry, anniversaries);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnniversaryItem(BuildContext context, int index, AnniversaryEntry entry, AnniversaryModel model) {
    final daysUntil = entry.getDaysUntilNext();
    final formatted = model.formatDaysUntil(entry);
    final occurrences = entry.getOccurrences();
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon = Icons.cake;
    Color iconColor = colorScheme.primary;
    
    if (daysUntil == 0) {
      icon = Icons.celebration;
      iconColor = colorScheme.tertiary;
    } else if (daysUntil < 7) {
      icon = Icons.event;
      iconColor = colorScheme.secondary;
    }

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(
        entry.name,
        style: TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        "${_formatDate(entry.day, entry.month)}${occurrences != null ? ' - ${occurrences} years' : ''}",
        style: TextStyle(fontSize: 11),
      ),
      trailing: Text(
        formatted,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: daysUntil == 0 ? colorScheme.tertiary : colorScheme.primary,
        ),
      ),
      onTap: () => _showEditAnniversaryDialog(context, index, entry),
    );
  }

  String _formatDate(int day, int month) {
    return "${day}/${month}";
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Anniversaries"),
        content: Text("This will delete all anniversaries. This action cannot be undone."),
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
      context.read<AnniversaryModel>().clearAllAnniversaries();
    }
  }
}

class AddAnniversaryDialog extends StatefulWidget {
  @override
  State<AddAnniversaryDialog> createState() => _AddAnniversaryDialogState();
}

class _AddAnniversaryDialogState extends State<AddAnniversaryDialog> {
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _includeYear = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Anniversary"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Event name (e.g., Mom's Birthday)",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Date"),
              subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("Include Year"),
              subtitle: Text(_includeYear 
                ? "Yes - will show years count"
                : "No - only date (month/day)"),
              trailing: Switch(
                value: _includeYear,
                onChanged: (value) {
                  setState(() {
                    _includeYear = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              context.read<AnniversaryModel>().addAnniversary(
                _nameController.text,
                _selectedDate.month,
                _selectedDate.day,
                _includeYear ? _selectedDate.year : null,
              );
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditAnniversaryDialog extends StatefulWidget {
  final int index;
  final AnniversaryEntry entry;

  const EditAnniversaryDialog({
    required this.index,
    required this.entry,
  });

  @override
  State<EditAnniversaryDialog> createState() => _EditAnniversaryDialogState();
}

class _EditAnniversaryDialogState extends State<EditAnniversaryDialog> {
  late TextEditingController _nameController;
  late DateTime _selectedDate;
  late bool _includeYear;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.name);
    _selectedDate = DateTime(
      widget.entry.year ?? DateTime.now().year,
      widget.entry.month,
      widget.entry.day,
    );
    _includeYear = widget.entry.year != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Anniversary"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Event name",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Date"),
              subtitle: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text("Include Year"),
              subtitle: Text(_includeYear 
                ? "Yes - will show years count"
                : "No - only date (month/day)"),
              trailing: Switch(
                value: _includeYear,
                onChanged: (value) {
                  setState(() {
                    _includeYear = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            context.read<AnniversaryModel>().deleteAnniversary(widget.index);
            Navigator.pop(context);
          },
          tooltip: "Delete",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
        FilledButton(
          onPressed: () {
            context.read<AnniversaryModel>().updateAnniversary(
              widget.index,
              _nameController.text,
              _selectedDate.month,
              _selectedDate.day,
              _includeYear ? _selectedDate.year : null,
            );
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}