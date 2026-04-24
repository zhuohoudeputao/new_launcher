import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

RockPaperScissorsModel rockPaperScissorsModel = RockPaperScissorsModel();

MyProvider providerRockPaperScissors = MyProvider(
    name: "RockPaperScissors",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Rock Paper Scissors',
      keywords: 'rock paper scissors game rps play hand',
      action: () {
        rockPaperScissorsModel.init();
        Global.infoModel.addInfoWidget(
            "RockPaperScissors",
            ChangeNotifierProvider.value(
                value: rockPaperScissorsModel,
                builder: (context, child) => RockPaperScissorsCard()),
            title: "Rock Paper Scissors");
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  rockPaperScissorsModel.init();
  Global.infoModel.addInfoWidget(
      "RockPaperScissors",
      ChangeNotifierProvider.value(
          value: rockPaperScissorsModel,
          builder: (context, child) => RockPaperScissorsCard()),
      title: "Rock Paper Scissors");
}

Future<void> _update() async {
  rockPaperScissorsModel.refresh();
}

enum RPSChoice { rock, paper, scissors }

enum RPSResult { win, lose, draw }

class RPSGameEntry {
  final RPSChoice playerChoice;
  final RPSChoice computerChoice;
  final RPSResult result;
  final DateTime timestamp;

  RPSGameEntry({
    required this.playerChoice,
    required this.computerChoice,
    required this.result,
    required this.timestamp,
  });
}

class RockPaperScissorsModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;
  
  RPSChoice? _playerChoice;
  RPSChoice? _computerChoice;
  RPSResult? _lastResult;
  
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;
  
  List<RPSGameEntry> _history = [];
  static const int maxHistory = 10;
  
  bool _shouldFocusInput = false;

  bool get isInitialized => _isInitialized;
  RPSChoice? get playerChoice => _playerChoice;
  RPSChoice? get computerChoice => _computerChoice;
  RPSResult? get lastResult => _lastResult;
  int get wins => _wins;
  int get losses => _losses;
  int get draws => _draws;
  int get totalGames => _wins + _losses + _draws;
  List<RPSGameEntry> get history => _history;
  bool get hasHistory => _history.isNotEmpty;
  bool get shouldFocusInput => _shouldFocusInput;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("RockPaperScissors initialized", source: "RockPaperScissors");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  RPSChoice _getComputerChoice() {
    return RPSChoice.values[_random.nextInt(3)];
  }

  RPSResult _determineResult(RPSChoice player, RPSChoice computer) {
    if (player == computer) return RPSResult.draw;
    
    if (player == RPSChoice.rock && computer == RPSChoice.scissors) return RPSResult.win;
    if (player == RPSChoice.paper && computer == RPSChoice.rock) return RPSResult.win;
    if (player == RPSChoice.scissors && computer == RPSChoice.paper) return RPSResult.win;
    
    return RPSResult.lose;
  }

  void play(RPSChoice choice) {
    _playerChoice = choice;
    _computerChoice = _getComputerChoice();
    _lastResult = _determineResult(_playerChoice!, _computerChoice!);
    
    switch (_lastResult!) {
      case RPSResult.win:
        _wins++;
        break;
      case RPSResult.lose:
        _losses++;
        break;
      case RPSResult.draw:
        _draws++;
        break;
    }
    
    _history.insert(0, RPSGameEntry(
      playerChoice: _playerChoice!,
      computerChoice: _computerChoice!,
      result: _lastResult!,
      timestamp: DateTime.now(),
    ));
    
    if (_history.length > maxHistory) {
      _history.removeLast();
    }
    
    Global.loggerModel.info(
      "RPS: Player ${choice.name} vs Computer ${_computerChoice!.name} = ${_lastResult!.name}",
      source: "RockPaperScissors"
    );
    
    notifyListeners();
  }

  void resetStats() {
    _wins = 0;
    _losses = 0;
    _draws = 0;
    _playerChoice = null;
    _computerChoice = null;
    _lastResult = null;
    Global.loggerModel.info("RPS stats reset", source: "RockPaperScissors");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("RPS history cleared", source: "RockPaperScissors");
    notifyListeners();
  }

  void requestFocus() {
    _shouldFocusInput = true;
    notifyListeners();
    _shouldFocusInput = false;
  }

  String getChoiceEmoji(RPSChoice choice) {
    switch (choice) {
      case RPSChoice.rock:
        return "🪨";
      case RPSChoice.paper:
        return "📄";
      case RPSChoice.scissors:
        return "✂️";
    }
  }

  String getChoiceName(RPSChoice choice) {
    return choice.name[0].toUpperCase() + choice.name.substring(1);
  }

  String getResultText(RPSResult result) {
    switch (result) {
      case RPSResult.win:
        return "You Win!";
      case RPSResult.lose:
        return "You Lose!";
      case RPSResult.draw:
        return "Draw!";
    }
  }

  Color getResultColor(RPSResult result, BuildContext context) {
    switch (result) {
      case RPSResult.win:
        return Colors.green;
      case RPSResult.lose:
        return Colors.red;
      case RPSResult.draw:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  double getWinRate() {
    if (totalGames == 0) return 0;
    return _wins / totalGames;
  }
}

class RockPaperScissorsCard extends StatefulWidget {
  @override
  State<RockPaperScissorsCard> createState() => _RockPaperScissorsCardState();
}

class _RockPaperScissorsCardState extends State<RockPaperScissorsCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final rps = context.watch<RockPaperScissorsModel>();

    if (!rps.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.games, size: 24),
              SizedBox(width: 12),
              Text("Rock Paper Scissors: Loading..."),
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
              children: [
                Icon(Icons.games, size: 20),
                SizedBox(width: 8),
                Text(
                  "Rock Paper Scissors",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildGameArea(context, rps),
            SizedBox(height: 12),
            _buildStatsRow(context, rps),
            SizedBox(height: 8),
            _buildHistoryToggle(context, rps),
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea(BuildContext context, RockPaperScissorsModel rps) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChoiceColumn(context, rps, "You", rps.playerChoice),
                Text("VS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildChoiceColumn(context, rps, "Computer", rps.computerChoice),
              ],
            ),
            if (rps.lastResult != null) ...[
              SizedBox(height: 12),
              Text(
                rps.getResultText(rps.lastResult!),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: rps.getResultColor(rps.lastResult!, context),
                ),
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: RPSChoice.values.map((choice) => 
                _buildChoiceButton(context, rps, choice)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceColumn(BuildContext context, RockPaperScissorsModel rps, String label, RPSChoice? choice) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              choice != null ? rps.getChoiceEmoji(choice) : "?",
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
        if (choice != null) ...[
          SizedBox(height: 4),
          Text(rps.getChoiceName(choice), style: TextStyle(fontSize: 10)),
        ],
      ],
    );
  }

  Widget _buildChoiceButton(BuildContext context, RockPaperScissorsModel rps, RPSChoice choice) {
    return ElevatedButton(
      onPressed: () => rps.play(choice),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rps.getChoiceEmoji(choice), style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text(rps.getChoiceName(choice), style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, RockPaperScissorsModel rps) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, "Wins", rps.wins, Colors.green),
        _buildStatItem(context, "Losses", rps.losses, Colors.red),
        _buildStatItem(context, "Draws", rps.draws, Theme.of(context).colorScheme.secondary),
        _buildStatItem(context, "Rate", "${(rps.getWinRate() * 100).toInt()}%", Theme.of(context).colorScheme.primary),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildHistoryToggle(BuildContext context, RockPaperScissorsModel rps) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          icon: Icon(Icons.history, size: 16),
          label: Text(_showHistory ? "Hide History" : "Show History"),
          onPressed: () {
            setState(() {
              _showHistory = !_showHistory;
            });
          },
        ),
        if (rps.hasHistory || rps.totalGames > 0)
          TextButton.icon(
            icon: Icon(Icons.refresh, size: 16),
            label: Text("Reset"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Reset Stats"),
                  content: Text("Reset all game statistics and clear history?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        rps.resetStats();
                        rps.clearHistory();
                        Navigator.pop(context);
                      },
                      child: Text("Reset"),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}