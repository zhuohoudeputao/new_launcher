import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

AgeModel ageModel = AgeModel();

MyProvider providerAge = MyProvider(
  name: "Age",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Calculate Age',
      keywords: 'age birthday birthdate calculate years old zodiac',
      action: () {
        Global.infoModel.addInfo("CalculateAge", "Age Calculator",
            subtitle: "Calculate age from birthdate",
            icon: Icon(Icons.cake),
            onTap: () => ageModel.requestFocus());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await ageModel.init();
  Global.infoModel.addInfoWidget(
    "Age",
    ChangeNotifierProvider.value(
      value: ageModel,
      builder: (context, child) => AgeCard(),
    ),
    title: "Age Calculator",
  );
}

Future<void> _update() async {
  await ageModel.refresh();
}

class AgeEntry {
  final String name;
  final DateTime birthdate;
  final DateTime createdAt;

  AgeEntry({
    required this.name,
    required this.birthdate,
    required this.createdAt,
  });

  String toJson() {
    return jsonEncode({
      'name': name,
      'birthdate': birthdate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static AgeEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AgeEntry(
      name: map['name'] as String,
      birthdate: DateTime.parse(map['birthdate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class AgeModel extends ChangeNotifier {
  static const int maxSavedEntries = 10;
  static const String _storageKey = 'age_saved_entries';
  static const String _birthdateKey = 'age_birthdate';

  List<AgeEntry> _savedEntries = [];
  DateTime? _birthdate;
  bool _isInitialized = false;
  bool _focusInput = false;

  bool get isInitialized => _isInitialized;
  DateTime? get birthdate => _birthdate;
  List<AgeEntry> get savedEntries => _savedEntries;
  bool get hasSavedEntries => _savedEntries.isNotEmpty;
  bool get shouldFocus => _focusInput;
  bool get hasBirthdate => _birthdate != null;

  String getZodiacSign(DateTime date) {
    int month = date.month;
    int day = date.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Aries ♈';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Taurus ♉';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gemini ♊';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Cancer ♋';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leo ♌';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgo ♍';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra ♎';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Scorpio ♏';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagittarius ♐';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Capricorn ♑';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquarius ♒';
    return 'Pisces ♓';
  }

  String getChineseZodiac(DateTime date) {
    int year = date.year;
    int index = (year - 1900) % 12;
    const animals = ['Rat 🐀', 'Ox 🐂', 'Tiger 🐅', 'Rabbit 🐇', 'Dragon 🐲', 'Snake 🐍', 
                     'Horse 🐎', 'Goat 🐐', 'Monkey 🐒', 'Rooster 🐓', 'Dog 🐕', 'Pig 🐖'];
    return animals[index];
  }

  int calculateAgeYears(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month || 
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  int calculateAgeMonths(DateTime birthdate) {
    final now = DateTime.now();
    int months = (now.year - birthdate.year) * 12 + now.month - birthdate.month;
    if (now.day < birthdate.day) {
      months--;
    }
    return months;
  }

  int calculateAgeDays(DateTime birthdate) {
    final now = DateTime.now();
    return now.difference(birthdate).inDays;
  }

  int calculateDaysUntilNextBirthday(DateTime birthdate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
    if (nextBirthday.isBefore(today) || nextBirthday.isAtSameMomentAs(today)) {
      nextBirthday = DateTime(now.year + 1, birthdate.month, birthdate.day);
    }
    return nextBirthday.difference(today).inDays;
  }

  String formatAge(DateTime birthdate) {
    int years = calculateAgeYears(birthdate);
    int months = calculateAgeMonths(birthdate) % 12;
    int days = calculateAgeDays(birthdate);
    
    if (years < 1) {
      return "${months} months, ${days % 30} days";
    }
    return "${years} years, ${months} months";
  }

  String formatAgeDetailed(DateTime birthdate) {
    int years = calculateAgeYears(birthdate);
    int totalMonths = calculateAgeMonths(birthdate);
    int days = calculateAgeDays(birthdate);
    
    if (years < 1) {
      return "${totalMonths} months (${days} days)";
    }
    return "${years} years, ${totalMonths % 12} months (${days} days total)";
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final birthdateStr = prefs.getString(_birthdateKey);
    if (birthdateStr != null) {
      _birthdate = DateTime.parse(birthdateStr);
    }
    
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _savedEntries = entryStrings.map((s) => AgeEntry.fromJson(s)).toList();
    
    _isInitialized = true;
    Global.loggerModel.info("Age Calculator initialized with ${_savedEntries.length} saved entries", source: "Age");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  void setBirthdate(DateTime date) {
    _birthdate = date;
    Global.loggerModel.info("Birthdate set: ${date.toIso8601String()}", source: "Age");
    _saveBirthdate();
    notifyListeners();
  }

  Future<void> _saveBirthdate() async {
    final prefs = await SharedPreferences.getInstance();
    if (_birthdate != null) {
      await prefs.setString(_birthdateKey, _birthdate!.toIso8601String());
    } else {
      await prefs.remove(_birthdateKey);
    }
  }

  void saveEntry(String name) {
    if (_birthdate == null || name.trim().isEmpty) return;
    
    final entry = AgeEntry(
      name: name.trim(),
      birthdate: _birthdate!,
      createdAt: DateTime.now(),
    );
    
    _savedEntries.insert(0, entry);
    
    while (_savedEntries.length > maxSavedEntries) {
      _savedEntries.removeLast();
    }
    
    Global.loggerModel.info("Age entry saved: $name", source: "Age");
    _saveEntries();
    notifyListeners();
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _savedEntries.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void loadEntry(AgeEntry entry) {
    _birthdate = entry.birthdate;
    Global.loggerModel.info("Loaded age entry: ${entry.name}", source: "Age");
    _saveBirthdate();
    notifyListeners();
  }

  void deleteEntry(int index) {
    if (index < 0 || index >= _savedEntries.length) return;
    final removedName = _savedEntries[index].name;
    _savedEntries.removeAt(index);
    Global.loggerModel.info("Deleted age entry: $removedName", source: "Age");
    _saveEntries();
    notifyListeners();
  }

  void clearAllEntries() {
    _savedEntries.clear();
    Global.loggerModel.info("Cleared all age entries", source: "Age");
    _saveEntries();
    notifyListeners();
  }

  void clear() {
    _birthdate = null;
    Global.loggerModel.info("Age cleared", source: "Age");
    _saveBirthdate();
    notifyListeners();
  }

  void requestFocus() {
    _focusInput = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusInput = false;
      notifyListeners();
    });
  }
}

class AgeCard extends StatefulWidget {
  @override
  State<AgeCard> createState() => _AgeCardState();
}

class _AgeCardState extends State<AgeCard> {
  DateTime? _selectedDate;
  final _nameController = TextEditingController();
  final _dateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final age = context.read<AgeModel>();
    _selectedDate = age.birthdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final age = context.read<AgeModel>();
    final initialDate = _selectedDate ?? age.birthdate ?? DateTime.now().subtract(Duration(days: 365 * 25));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      age.setBirthdate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = context.watch<AgeModel>();

    if (!age.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.cake, size: 24),
              SizedBox(width: 12),
              Text("Age Calculator: Loading..."),
            ],
          ),
        ),
      );
    }

    if (age.shouldFocus && !_dateFocusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 50), () {
        _selectDate(context);
      });
    }

    final displayDate = _selectedDate ?? age.birthdate;

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
                Row(
                  children: [
                    Icon(Icons.cake, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Age Calculator",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (age.hasSavedEntries)
                      IconButton(
                        icon: Icon(Icons.history, size: 18),
                        onPressed: () => _showHistoryDialog(context, age),
                        tooltip: "Saved entries",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.calendar_today, size: 18),
                      onPressed: () => _selectDate(context),
                      tooltip: "Select birthdate",
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            if (displayDate == null)
              _buildEmptyState(context)
            else
              _buildAgeResult(context, age, displayDate),
            SizedBox(height: 12),
            if (displayDate != null)
              _buildSaveSection(context, age),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cake_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            SizedBox(height: 8),
            Text(
              "Select a birthdate to calculate age",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeResult(BuildContext context, AgeModel age, DateTime birthdate) {
    final colorScheme = Theme.of(context).colorScheme;
    final years = age.calculateAgeYears(birthdate);
    final daysUntilBirthday = age.calculateDaysUntilNextBirthday(birthdate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${birthdate.day}/${birthdate.month}/${birthdate.year}",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Text(
                years.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                "years old",
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoItem(context, "Age", age.formatAge(birthdate)),
            _buildInfoItem(context, "Total Days", "${age.calculateAgeDays(birthdate)}"),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoItem(context, "Zodiac", age.getZodiacSign(birthdate)),
            _buildInfoItem(context, "Chinese", age.getChineseZodiac(birthdate)),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: daysUntilBirthday <= 7 
                ? colorScheme.errorContainer.withValues(alpha: 0.3)
                : colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cake,
                size: 16,
                color: daysUntilBirthday <= 7 
                    ? colorScheme.error
                    : colorScheme.secondary,
              ),
              SizedBox(width: 8),
              Text(
                daysUntilBirthday == 0 
                    ? "Happy Birthday! 🎂"
                    : "$daysUntilBirthday days until next birthday",
                style: TextStyle(
                  fontSize: 12,
                  color: daysUntilBirthday <= 7 
                      ? colorScheme.error
                      : colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveSection(BuildContext context, AgeModel age) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Name (e.g., John's Birthday)",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.save, size: 20),
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              age.saveEntry(_nameController.text);
              _nameController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Saved to entries"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          tooltip: "Save entry",
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        IconButton(
          icon: Icon(Icons.clear, size: 20),
          onPressed: () {
            age.clear();
            setState(() {
              _selectedDate = null;
            });
          },
          tooltip: "Clear",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  void _showHistoryDialog(BuildContext context, AgeModel age) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text("Saved Birthdates"),
            Spacer(),
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text("Clear All"),
                    content: Text("Clear all saved birthdate entries?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          age.clearAllEntries();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: Text("Clear"),
                      ),
                    ],
                  ),
                );
              },
              tooltip: "Clear all",
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: age.savedEntries.length,
            itemBuilder: (context, index) {
              final entry = age.savedEntries[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    age.calculateAgeYears(entry.birthdate).toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(entry.name),
                subtitle: Text("${entry.birthdate.day}/${entry.birthdate.month}/${entry.birthdate.year} • ${age.formatAge(entry.birthdate)}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 18),
                  onPressed: () {
                    age.deleteEntry(index);
                    Navigator.pop(context);
                    _showHistoryDialog(context, age);
                  },
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  age.loadEntry(entry);
                  setState(() {
                    _selectedDate = entry.birthdate;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}