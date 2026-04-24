import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

DecisionMakerModel decisionMakerModel = DecisionMakerModel();

MyProvider providerDecisionMaker = MyProvider(
    name: "DecisionMaker",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'DecisionMaker',
      keywords: 'decision maker decide choose random pick option spin wheel coin toss yes no',
      action: () => decisionMakerModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  decisionMakerModel.init();
  Global.infoModel.addInfoWidget(
      "DecisionMaker",
      ChangeNotifierProvider.value(
          value: decisionMakerModel,
          builder: (context, child) => DecisionMakerCard()),
      title: "DecisionMaker");
}

Future<void> _update() async {
  decisionMakerModel.refresh();
}

class DecisionMakerModel extends ChangeNotifier {
  static const int maxHistory = 10;

  String _inputOptions = "";
  String _selectedOption = "";
  DecisionType _decisionType = DecisionType.pick;
  final List<DecisionEntry> _history = [];
  Timer? _spinTimer;
  int _spinIndex = 0;
  bool _isSpinning = false;
  bool _isInitialized = false;
  bool _focusRequested = false;

  String get inputOptions => _inputOptions;
  String get selectedOption => _selectedOption;
  DecisionType get decisionType => _decisionType;
  List<DecisionEntry> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  bool get isInitialized => _isInitialized;
  bool get shouldFocus => _focusRequested;
  bool get isSpinning => _isSpinning;
  int get spinIndex => _spinIndex;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("DecisionMaker initialized", source: "DecisionMaker");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setInputOptions(String value) {
    _inputOptions = value;
    notifyListeners();
  }

  void setDecisionType(DecisionType type) {
    _decisionType = type;
    _selectedOption = "";
    notifyListeners();
  }

  List<String> parseOptions() {
    if (_inputOptions.trim().isEmpty) return [];
    return _inputOptions
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void makeDecision() {
    if (_isSpinning) return;

    switch (_decisionType) {
      case DecisionType.pick:
        _makePickDecision();
        break;
      case DecisionType.coinToss:
        _makeCoinTossDecision();
        break;
      case DecisionType.yesNo:
        _makeYesNoDecision();
        break;
    }
  }

  void _makePickDecision() {
    final options = parseOptions();
    if (options.isEmpty) {
      _selectedOption = "Enter options first";
      notifyListeners();
      return;
    }

    if (options.length >= 3) {
      _startSpinning(options);
    } else {
      _selectedOption = options[Random().nextInt(options.length)];
      _addToHistory(_selectedOption, _decisionType);
      Global.loggerModel.info("Decision made: $_selectedOption", source: "DecisionMaker");
      notifyListeners();
    }
  }

  void _startSpinning(List<String> options) {
    _isSpinning = true;
    _spinIndex = 0;
    notifyListeners();

    final random = Random();
    int spinDuration = 2000 + random.nextInt(1000);
    int elapsed = 0;
    int interval = 100;

    _spinTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      elapsed += interval;
      _spinIndex = (_spinIndex + 1) % options.length;
      notifyListeners();

      if (elapsed >= spinDuration) {
        timer.cancel();
        _isSpinning = false;
        _selectedOption = options[Random().nextInt(options.length)];
        _addToHistory(_selectedOption, _decisionType);
        Global.loggerModel.info("Decision made: $_selectedOption", source: "DecisionMaker");
        notifyListeners();
      }
    });
  }

  void _makeCoinTossDecision() {
    final result = Random().nextBool() ? "Heads" : "Tails";
    _selectedOption = result;
    _addToHistory(result, _decisionType);
    Global.loggerModel.info("Coin toss: $result", source: "DecisionMaker");
    notifyListeners();
  }

  void _makeYesNoDecision() {
    final result = Random().nextBool() ? "Yes" : "No";
    _selectedOption = result;
    _addToHistory(result, _decisionType);
    Global.loggerModel.info("Yes/No: $result", source: "DecisionMaker");
    notifyListeners();
  }

  void _addToHistory(String decision, DecisionType type) {
    _history.insert(0, DecisionEntry(
      decision: decision,
      type: type,
      timestamp: DateTime.now(),
    ));
    if (_history.length > maxHistory) {
      _history.removeLast();
    }
  }

  void clearInput() {
    _inputOptions = "";
    _selectedOption = "";
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("DecisionMaker history cleared", source: "DecisionMaker");
    notifyListeners();
  }

  void requestFocus() {
    _focusRequested = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusRequested = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }
}

enum DecisionType {
  pick,
  coinToss,
  yesNo,
}

class DecisionEntry {
  final String decision;
  final DecisionType type;
  final DateTime timestamp;

  DecisionEntry({
    required this.decision,
    required this.type,
    required this.timestamp,
  });
}

class DecisionMakerCard extends StatefulWidget {
  @override
  State<DecisionMakerCard> createState() => _DecisionMakerCardState();
}

class _DecisionMakerCardState extends State<DecisionMakerCard> {
  final TextEditingController _controller = TextEditingController();
  bool _showHistory = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    context.read<DecisionMakerModel>().setInputOptions(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final decision = context.watch<DecisionMakerModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (decision.shouldFocus && !_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    if (!decision.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 24),
              SizedBox(width: 12),
              Text("DecisionMaker: Loading..."),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Decision Maker",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (decision.hasHistory)
                        IconButton(
                          icon: Icon(_showHistory ? Icons.help_outline : Icons.history, size: 18),
                          onPressed: () => setState(() => _showHistory = !_showHistory),
                          tooltip: _showHistory ? "Decision" : "History",
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (decision.hasHistory)
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
              SizedBox(height: 12),
              if (_showHistory)
                _buildHistoryView(decision)
              else
                _buildMainView(decision),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(DecisionMakerModel decision) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<DecisionType>(
          segments: [
            ButtonSegment(
              value: DecisionType.pick,
              label: Text("Pick"),
              icon: Icon(Icons.select_all, size: 18),
            ),
            ButtonSegment(
              value: DecisionType.coinToss,
              label: Text("Coin"),
              icon: Icon(Icons.paid, size: 18),
            ),
            ButtonSegment(
              value: DecisionType.yesNo,
              label: Text("Yes/No"),
              icon: Icon(Icons.question_answer, size: 18),
            ),
          ],
          selected: {decision.decisionType},
          onSelectionChanged: (Set<DecisionType> newSelection) {
            decision.setDecisionType(newSelection.first);
          },
        ),
        SizedBox(height: 12),
        if (decision.decisionType == DecisionType.pick)
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: "Enter options (comma separated)",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _controller.clear();
                        decision.clearInput();
                      },
                    )
                  : null,
            ),
            maxLines: 1,
          ),
        SizedBox(height: 12),
        _buildResultDisplay(decision),
        SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: decision.isSpinning ? null : decision.makeDecision,
          icon: Icon(Icons.casino, size: 18),
          label: Text(decision.isSpinning ? "Spinning..." : "Make Decision"),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultDisplay(DecisionMakerModel decision) {
    final colorScheme = Theme.of(context).colorScheme;
    final options = decision.parseOptions();

    if (decision.isSpinning && options.isNotEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          options[decision.spinIndex],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    if (decision.selectedOption.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Tap to decide",
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    Color backgroundColor;
    IconData icon;
    if (decision.decisionType == DecisionType.coinToss) {
      backgroundColor = decision.selectedOption == "Heads"
          ? colorScheme.tertiaryContainer
          : colorScheme.secondaryContainer;
      icon = decision.selectedOption == "Heads"
          ? Icons.currency_bitcoin
          : Icons.currency_bitcoin;
    } else if (decision.decisionType == DecisionType.yesNo) {
      backgroundColor = decision.selectedOption == "Yes"
          ? colorScheme.primaryContainer
          : colorScheme.errorContainer;
      icon = decision.selectedOption == "Yes"
          ? Icons.check_circle
          : Icons.cancel;
    } else {
      backgroundColor = colorScheme.tertiaryContainer;
      icon = Icons.star;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          SizedBox(width: 8),
          Text(
            decision.selectedOption,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(DecisionMakerModel decision) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "History",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: decision.history.length,
              itemBuilder: (context, index) {
                final entry = decision.history[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getTypeIcon(entry.type),
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    entry.decision,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _formatTimeAgo(entry.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(DecisionType type) {
    switch (type) {
      case DecisionType.pick:
        return Icons.select_all;
      case DecisionType.coinToss:
        return Icons.paid;
      case DecisionType.yesNo:
        return Icons.question_answer;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all decision history?"),
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
      context.read<DecisionMakerModel>().clearHistory();
      setState(() => _showHistory = false);
    }
  }
}