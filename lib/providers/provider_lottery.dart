import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

LotteryModel lotteryModel = LotteryModel();

MyProvider providerLottery = MyProvider(
    name: "Lottery",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'LotteryNumbers',
      keywords: 'lottery numbers lucky random pick draw win game lotto jackpot powerball mega millions',
      action: () => lotteryModel.generateNumbers(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await lotteryModel.init();
  Global.infoModel.addInfoWidget(
      "LotteryNumbers",
      ChangeNotifierProvider.value(
          value: lotteryModel,
          builder: (context, child) => LotteryCard()),
      title: "Lottery Numbers");
}

Future<void> _update() async {
  lotteryModel.refresh();
}

class LotteryHistoryEntry {
  final DateTime date;
  final String lotteryType;
  final List<int> numbers;

  LotteryHistoryEntry({
    required this.date,
    required this.lotteryType,
    required this.numbers,
  });

  String toJson() {
    return jsonEncode({
      'date': date.toIso8601String(),
      'lotteryType': lotteryType,
      'numbers': numbers,
    });
  }

  static LotteryHistoryEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return LotteryHistoryEntry(
      date: DateTime.parse(map['date'] as String),
      lotteryType: map['lotteryType'] as String,
      numbers: (map['numbers'] as List).map((e) => e as int).toList(),
    );
  }

  String get displayText {
    return '$lotteryType: ${numbers.map((n) => n.toString()).join(', ')}';
  }
}

class LotteryType {
  final String name;
  final int poolSize;
  final int count;
  final String description;

  LotteryType({
    required this.name,
    required this.poolSize,
    required this.count,
    required this.description,
  });
}

class LotteryModel extends ChangeNotifier {
  static const int maxHistory = 10;
  static const String _storageKey = 'lottery_history';

  final List<LotteryType> _lotteryTypes = [
    LotteryType(name: '6/49', poolSize: 49, count: 6, description: 'Classic lottery format'),
    LotteryType(name: '5/50', poolSize: 50, count: 5, description: 'European lottery'),
    LotteryType(name: '4/35', poolSize: 35, count: 4, description: 'Mini lottery'),
    LotteryType(name: '3/27', poolSize: 27, count: 3, description: 'Quick pick'),
    LotteryType(name: '5/90', poolSize: 90, count: 5, description: 'Large pool'),
    LotteryType(name: '7/47', poolSize: 47, count: 7, description: 'Super draw'),
  ];

  List<LotteryHistoryEntry> _history = [];
  LotteryType _selectedLottery = LotteryType(name: '6/49', poolSize: 49, count: 6, description: 'Classic lottery format');
  List<int> _currentNumbers = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<LotteryType> get lotteryTypes => _lotteryTypes;
  LotteryType get selectedLottery => _selectedLottery;
  List<int> get currentNumbers => _currentNumbers;
  List<LotteryHistoryEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  bool get hasNumbers => _currentNumbers.isNotEmpty;

  String get selectedLotteryName => _selectedLottery.name;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _history = entryStrings.map((s) => LotteryHistoryEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel.info("Lottery Numbers initialized with ${_history.length} entries", source: "Lottery");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Lottery Numbers refreshed", source: "Lottery");
  }

  void setLotteryType(LotteryType type) {
    _selectedLottery = type;
    _currentNumbers = [];
    notifyListeners();
  }

  void setLotteryTypeByName(String name) {
    final type = _lotteryTypes.firstWhere(
      (t) => t.name == name,
      orElse: () => _lotteryTypes.first,
    );
    setLotteryType(type);
  }

  void generateNumbers() {
    final random = Random();
    final numbers = <int>[];
    final pool = List.generate(_selectedLottery.poolSize, (i) => i + 1);
    
    for (int i = 0; i < _selectedLottery.count && pool.isNotEmpty; i++) {
      final index = random.nextInt(pool.length);
      numbers.add(pool.removeAt(index));
    }
    
    numbers.sort();
    _currentNumbers = numbers;
    notifyListeners();
    Global.loggerModel.info("Generated lottery numbers: ${numbers.join(', ')}", source: "Lottery");
  }

  void clearNumbers() {
    _currentNumbers = [];
    notifyListeners();
    Global.loggerModel.info("Lottery numbers cleared", source: "Lottery");
  }

  void saveToHistory() {
    if (_currentNumbers.isEmpty) return;

    _history.insert(0, LotteryHistoryEntry(
      date: DateTime.now(),
      lotteryType: _selectedLottery.name,
      numbers: List.from(_currentNumbers),
    ));

    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    _save();
    notifyListeners();
    Global.loggerModel.info("Lottery numbers saved to history", source: "Lottery");
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void loadFromHistory(LotteryHistoryEntry entry) {
    setLotteryTypeByName(entry.lotteryType);
    _currentNumbers = List.from(entry.numbers);
    notifyListeners();
    Global.loggerModel.info("Loaded lottery numbers from history", source: "Lottery");
  }

  void clearHistory() {
    _history.clear();
    _save();
    notifyListeners();
    Global.loggerModel.info("Lottery history cleared", source: "Lottery");
  }
}

class LotteryCard extends StatefulWidget {
  @override
  State<LotteryCard> createState() => _LotteryCardState();
}

class _LotteryCardState extends State<LotteryCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final lottery = context.watch<LotteryModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!lottery.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.casino, size: 24),
              SizedBox(width: 12),
              Text("Lottery Numbers: Loading..."),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lottery Numbers",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lottery.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.casino : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Generator" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (lottery.hasHistory)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearHistoryConfirmation(context),
                        tooltip: "Clear history",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (_showHistory) _buildHistoryView(lottery)
            else _buildGeneratorView(lottery),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratorView(LotteryModel lottery) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLotteryTypeSelector(lottery),
        SizedBox(height: 12),
        _buildNumbersDisplay(lottery),
        SizedBox(height: 8),
        _buildActionButtons(lottery),
      ],
    );
  }

  Widget _buildLotteryTypeSelector(LotteryModel lottery) {
    return SegmentedButton<String>(
      segments: lottery.lotteryTypes.map((type) {
        return ButtonSegment(
          value: type.name,
          label: Text(type.name),
        );
      }).toList(),
      selected: {lottery.selectedLotteryName},
      onSelectionChanged: (Set<String> selection) {
        context.read<LotteryModel>().setLotteryTypeByName(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildNumbersDisplay(LotteryModel lottery) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!lottery.hasNumbers) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          "Tap Generate to pick ${lottery.selectedLottery.count} numbers from 1-${lottery.selectedLottery.poolSize}",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lottery.selectedLottery.description,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: lottery.currentNumbers.map((number) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LotteryModel lottery) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.read<LotteryModel>().generateNumbers(),
          icon: Icon(Icons.casino, size: 18),
          label: Text("Generate"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
        ),
        if (lottery.hasNumbers)
          ElevatedButton.icon(
            onPressed: () => context.read<LotteryModel>().saveToHistory(),
            icon: Icon(Icons.save, size: 18),
            label: Text("Save"),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
          ),
        if (lottery.hasNumbers)
          ElevatedButton.icon(
            onPressed: () => context.read<LotteryModel>().clearNumbers(),
            icon: Icon(Icons.clear, size: 18),
            label: Text("Clear"),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryView(LotteryModel lottery) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: lottery.history.length,
        itemBuilder: (context, index) {
          final entry = lottery.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.casino, size: 20),
            title: Text(
              entry.displayText,
              style: TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatDate(entry.date),
              style: TextStyle(fontSize: 10),
            ),
            onTap: () {
              context.read<LotteryModel>().loadFromHistory(entry);
              setState(() => _showHistory = false);
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all lottery number history?"),
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
      context.read<LotteryModel>().clearHistory();
    }
  }
}