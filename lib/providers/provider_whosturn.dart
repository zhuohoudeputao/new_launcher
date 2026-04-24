import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

WhosTurnModel whosTurnModel = WhosTurnModel();

MyProvider providerWhosTurn = MyProvider(
    name: "WhosTurn",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Whos Turn',
      keywords: 'whosturn turn player game board card next who',
      action: () {
        Global.infoModel.addInfo(
            "WhosTurn",
            "Whos Turn",
            subtitle: whosTurnModel.players.isNotEmpty 
                ? "Current: ${whosTurnModel.getCurrentPlayerName()}"
                : "Add players to start",
            icon: Icon(Icons.people_alt),
            onTap: () => whosTurnModel.nextTurn());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await whosTurnModel.init();
  Global.infoModel.addInfoWidget(
      "WhosTurn",
      ChangeNotifierProvider.value(
          value: whosTurnModel,
          builder: (context, child) => WhosTurnCard()),
      title: "Whos Turn");
}

Future<void> _update() async {
  await whosTurnModel.refresh();
}

void _showAddPlayerDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddPlayerDialog(),
  );
}

void _showEditPlayerDialog(BuildContext context, int index, PlayerItem item) {
  showDialog(
    context: context,
    builder: (context) => EditPlayerDialog(index: index, item: item),
  );
}

class PlayerItem {
  final String name;
  final DateTime createdAt;

  PlayerItem({
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String toJson() {
    return jsonEncode({
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static PlayerItem fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PlayerItem(
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  PlayerItem copyWith({
    String? name,
    DateTime? createdAt,
  }) {
    return PlayerItem(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TurnEntry {
  final int playerIndex;
  final String playerName;
  final DateTime timestamp;

  TurnEntry({
    required this.playerIndex,
    required this.playerName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String toJson() {
    return jsonEncode({
      'playerIndex': playerIndex,
      'playerName': playerName,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  static TurnEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return TurnEntry(
      playerIndex: map['playerIndex'] as int,
      playerName: map['playerName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class WhosTurnModel extends ChangeNotifier {
  static const int maxPlayers = 10;
  static const int maxHistory = 20;
  static const String _playersStorageKey = 'whosturn_players';
  static const String _currentIndexKey = 'whosturn_current_index';
  static const String _historyStorageKey = 'whosturn_history';

  final Random _random = Random();
  List<PlayerItem> _players = [];
  List<TurnEntry> _history = [];
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _showHistory = false;

  bool get isInitialized => _isInitialized;
  List<PlayerItem> get players => _players;
  List<TurnEntry> get history => _history;
  int get currentIndex => _currentIndex;
  bool get showHistory => _showHistory;
  int get length => _players.length;
  bool get hasPlayers => _players.isNotEmpty;
  bool get hasHistory => _history.isNotEmpty;

  String getCurrentPlayerName() {
    if (_players.isEmpty || _currentIndex >= _players.length) {
      return "";
    }
    return _players[_currentIndex].name;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final playerStrings = prefs.getStringList(_playersStorageKey) ?? [];
    _players = playerStrings.map((s) => PlayerItem.fromJson(s)).toList();
    _currentIndex = prefs.getInt(_currentIndexKey) ?? 0;
    if (_currentIndex >= _players.length && _players.isNotEmpty) {
      _currentIndex = 0;
    }
    final historyStrings = prefs.getStringList(_historyStorageKey) ?? [];
    _history = historyStrings.map((s) => TurnEntry.fromJson(s)).toList();
    _isInitialized = true;
    Global.loggerModel
        .info("WhosTurn initialized with ${_players.length} players", source: "WhosTurn");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final playerStrings = _players.map((p) => p.toJson()).toList();
    await prefs.setStringList(_playersStorageKey, playerStrings);
    await prefs.setInt(_currentIndexKey, _currentIndex);
    final historyStrings = _history.map((h) => h.toJson()).toList();
    await prefs.setStringList(_historyStorageKey, historyStrings);
  }

  void addPlayer(String name) {
    if (_players.length >= maxPlayers) {
      _players.removeAt(0);
      if (_currentIndex > 0) _currentIndex--;
    }
    _players.add(PlayerItem(name: name));
    Global.loggerModel.info("Added player: $name", source: "WhosTurn");
    _save();
    notifyListeners();
  }

  void updatePlayer(int index, String name) {
    if (index >= 0 && index < _players.length) {
      _players[index] = _players[index].copyWith(name: name);
      Global.loggerModel.info("Updated player at index $index", source: "WhosTurn");
      _save();
      notifyListeners();
    }
  }

  void deletePlayer(int index) {
    if (index >= 0 && index < _players.length) {
      final name = _players[index].name;
      _players.removeAt(index);
      if (_currentIndex >= _players.length && _players.isNotEmpty) {
        _currentIndex = _players.length - 1;
      } else if (_players.isEmpty) {
        _currentIndex = 0;
      } else if (index < _currentIndex) {
        _currentIndex--;
      }
      Global.loggerModel.info("Deleted player: $name", source: "WhosTurn");
      _save();
      notifyListeners();
    }
  }

  void nextTurn() {
    if (_players.isEmpty) return;
    
    final currentPlayer = _players[_currentIndex];
    _addToHistory(_currentIndex, currentPlayer.name);
    
    _currentIndex = (_currentIndex + 1) % _players.length;
    Global.loggerModel.info("Next turn: ${_players[_currentIndex].name}", source: "WhosTurn");
    _save();
    notifyListeners();
  }

  void previousTurn() {
    if (_players.isEmpty) return;
    
    _currentIndex = (_currentIndex - 1 + _players.length) % _players.length;
    Global.loggerModel.info("Previous turn: ${_players[_currentIndex].name}", source: "WhosTurn");
    _save();
    notifyListeners();
  }

  void randomPlayer() {
    if (_players.isEmpty) return;
    
    _currentIndex = _random.nextInt(_players.length);
    final currentPlayer = _players[_currentIndex];
    _addToHistory(_currentIndex, currentPlayer.name);
    Global.loggerModel.info("Random turn: ${currentPlayer.name}", source: "WhosTurn");
    _save();
    notifyListeners();
  }

  void setCurrentPlayer(int index) {
    if (index >= 0 && index < _players.length) {
      final currentPlayer = _players[index];
      _addToHistory(index, currentPlayer.name);
      _currentIndex = index;
      Global.loggerModel.info("Set current turn: ${currentPlayer.name}", source: "WhosTurn");
      _save();
      notifyListeners();
    }
  }

  void _addToHistory(int playerIndex, String playerName) {
    if (_history.length >= maxHistory) {
      _history.removeAt(0);
    }
    _history.add(TurnEntry(
      playerIndex: playerIndex,
      playerName: playerName,
    ));
  }

  void toggleHistory() {
    _showHistory = !_showHistory;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("WhosTurn history cleared", source: "WhosTurn");
    _save();
    notifyListeners();
  }

  Future<void> clearAllPlayers() async {
    _players.clear();
    _history.clear();
    _currentIndex = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playersStorageKey);
    await prefs.remove(_currentIndexKey);
    await prefs.remove(_historyStorageKey);
    Global.loggerModel.info("Cleared all players", source: "WhosTurn");
    notifyListeners();
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return "just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }
}

class WhosTurnCard extends StatefulWidget {
  @override
  State<WhosTurnCard> createState() => _WhosTurnCardState();
}

class _WhosTurnCardState extends State<WhosTurnCard> {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<WhosTurnModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.people_alt, size: 24),
              SizedBox(width: 12),
              Text("Whos Turn: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Whos Turn",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  if (model.players.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${model.currentIndex + 1}/${model.length}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (model.players.isEmpty)
                Text(
                  "No players. Tap + to add players!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              if (model.players.isNotEmpty)
                _buildCurrentPlayerSection(context, model),
              SizedBox(height: 8),
              ...model.players.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildPlayerItem(context, model, index, item);
              }),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: () => _showAddPlayerDialog(context),
                    tooltip: "Add player",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (model.hasHistory)
                    IconButton(
                      icon: Icon(model.showHistory ? Icons.history : Icons.history_outlined, size: 18),
                      onPressed: () => model.toggleHistory(),
                      tooltip: model.showHistory ? "Hide history" : "Show history",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  if (model.players.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_sweep, size: 18),
                      onPressed: () => _showClearConfirmDialog(context, model),
                      tooltip: "Clear all players",
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
              if (model.showHistory && model.hasHistory)
                _buildHistorySection(context, model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlayerSection(BuildContext context, WhosTurnModel model) {
    final currentPlayer = model.players[model.currentIndex];
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentPlayer.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, size: 20),
                onPressed: () => model.previousTurn(),
                tooltip: "Previous",
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_forward, size: 16),
                label: Text("Next"),
                onPressed: () => model.nextTurn(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.shuffle, size: 20),
                onPressed: () => model.randomPlayer(),
                tooltip: "Random",
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(
      BuildContext context, WhosTurnModel model, int index, PlayerItem item) {
    final isCurrent = index == model.currentIndex;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onLongPress: () => _showEditPlayerDialog(context, index, item),
        onTap: () => model.setCurrentPlayer(index),
        child: Card(
          color: isCurrent 
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCurrent 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCurrent 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isCurrent)
                  Icon(
                    Icons.arrow_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, WhosTurnModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Divider(),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.history, size: 16),
            SizedBox(width: 4),
            Text(
              "Turn History",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Spacer(),
            if (model.hasHistory)
              TextButton(
                onPressed: () => model.clearHistory(),
                child: Text("Clear"),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        SizedBox(height: 4),
        ...model.history.map((entry) => Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  "${entry.playerIndex + 1}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.playerName,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Text(
                model.formatTimestamp(entry.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _showClearConfirmDialog(BuildContext context, WhosTurnModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear all players?"),
        content: Text("This will delete all ${model.length} players and turn history."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              model.clearAllPlayers();
              Navigator.pop(context);
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }
}

class AddPlayerDialog extends StatefulWidget {
  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Player"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "e.g., Alice, Bob, Player 1",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 8),
          Text(
            "Maximum ${WhosTurnModel.maxPlayers} players",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              whosTurnModel.addPlayer(_nameController.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditPlayerDialog extends StatefulWidget {
  final int index;
  final PlayerItem item;

  const EditPlayerDialog({required this.index, required this.item});

  @override
  State<EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<EditPlayerDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Player"),
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: "Player name",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            whosTurnModel.deletePlayer(widget.index);
            Navigator.pop(context);
          },
          child: Text("Delete"),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              whosTurnModel.updatePlayer(widget.index, _nameController.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}