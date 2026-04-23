import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

RandomModel randomModel = RandomModel();

MyProvider providerRandom = MyProvider(
    name: "Random",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Coin Flip',
      keywords: 'coin flip heads tails random toss',
      action: () {
        randomModel.flipCoin();
        Global.infoModel.addInfo(
            "CoinFlip",
            "Coin Flip",
            subtitle: "Tap to flip again",
            icon: Icon(Icons.currency_exchange),
            onTap: () => randomModel.flipCoin());
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Dice Roll',
      keywords: 'dice roll d6 d20 random die',
      action: () {
        randomModel.rollDice(6);
        Global.infoModel.addInfo(
            "DiceRoll",
            "Dice Roll",
            subtitle: "Tap to roll again",
            icon: Icon(Icons.casino),
            onTap: () => randomModel.rollDice(6));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Random Password',
      keywords: 'password random generate secure',
      action: () {
        randomModel.generatePassword(12);
        Global.infoModel.addInfo(
            "RandomPassword",
            "Random Password",
            subtitle: "Tap to generate new password",
            icon: Icon(Icons.password),
            onTap: () => randomModel.generatePassword(12));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  randomModel.init();
  Global.infoModel.addInfoWidget(
      "Random",
      ChangeNotifierProvider.value(
          value: randomModel,
          builder: (context, child) => RandomCard()),
      title: "Random Generator");
}

Future<void> _update() async {
  randomModel.refresh();
}

class RandomModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;
  
  String _coinResult = "";
  String _diceResult = "";
  int _diceSides = 6;
  String _randomNumberResult = "";
  int _randomNumberMin = 1;
  int _randomNumberMax = 100;
  String _passwordResult = "";
  int _passwordLength = 12;
  bool _passwordIncludeLower = true;
  bool _passwordIncludeUpper = true;
  bool _passwordIncludeNumbers = true;
  bool _passwordIncludeSymbols = true;
  
  bool get isInitialized => _isInitialized;
  String get coinResult => _coinResult;
  String get diceResult => _diceResult;
  int get diceSides => _diceSides;
  String get randomNumberResult => _randomNumberResult;
  int get randomNumberMin => _randomNumberMin;
  int get randomNumberMax => _randomNumberMax;
  String get passwordResult => _passwordResult;
  int get passwordLength => _passwordLength;
  bool get passwordIncludeLower => _passwordIncludeLower;
  bool get passwordIncludeUpper => _passwordIncludeUpper;
  bool get passwordIncludeNumbers => _passwordIncludeNumbers;
  bool get passwordIncludeSymbols => _passwordIncludeSymbols;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("Random initialized", source: "Random");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  String flipCoin() {
    _coinResult = _random.nextBool() ? "Heads" : "Tails";
    notifyListeners();
    Global.loggerModel.info("Coin flipped: $_coinResult", source: "Random");
    return _coinResult;
  }

  String rollDice(int sides) {
    _diceSides = sides;
    _diceResult = "${_random.nextInt(sides) + 1}";
    notifyListeners();
    Global.loggerModel.info("D$sides rolled: $_diceResult", source: "Random");
    return _diceResult;
  }

  String generateRandomNumber(int min, int max) {
    _randomNumberMin = min;
    _randomNumberMax = max;
    _randomNumberResult = "${min + _random.nextInt(max - min + 1)}";
    notifyListeners();
    Global.loggerModel.info("Random number: $_randomNumberResult (range: $min-$max)", source: "Random");
    return _randomNumberResult;
  }

  String generatePassword(int length, {bool? lower, bool? upper, bool? numbers, bool? symbols}) {
    _passwordLength = length;
    if (lower != null) _passwordIncludeLower = lower;
    if (upper != null) _passwordIncludeUpper = upper;
    if (numbers != null) _passwordIncludeNumbers = numbers;
    if (symbols != null) _passwordIncludeSymbols = symbols;
    
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String nums = '0123456789';
    const String syms = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    String charset = '';
    if (_passwordIncludeLower) charset += lowercase;
    if (_passwordIncludeUpper) charset += uppercase;
    if (_passwordIncludeNumbers) charset += nums;
    if (_passwordIncludeSymbols) charset += syms;
    
    if (charset.isEmpty) {
      charset = lowercase;
      _passwordIncludeLower = true;
    }
    
    _passwordResult = List.generate(length, (_) => charset[_random.nextInt(charset.length)]).join();
    notifyListeners();
    Global.loggerModel.info("Password generated: ${_passwordResult.length} chars", source: "Random");
    return _passwordResult;
  }

  void setPasswordLength(int length) {
    _passwordLength = length.clamp(4, 64);
    notifyListeners();
  }

  void setPasswordOptions({required bool lower, required bool upper, required bool numbers, required bool symbols}) {
    _passwordIncludeLower = lower;
    _passwordIncludeUpper = upper;
    _passwordIncludeNumbers = numbers;
    _passwordIncludeSymbols = symbols;
    notifyListeners();
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class RandomCard extends StatefulWidget {
  @override
  State<RandomCard> createState() => _RandomCardState();
}

class _RandomCardState extends State<RandomCard> {
  int _selectedDiceIndex = 1;
  final List<int> _diceOptions = [4, 6, 8, 10, 12, 20, 100];
  
  final TextEditingController _minController = TextEditingController(text: '1');
  final TextEditingController _maxController = TextEditingController(text: '100');
  
  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final random = context.watch<RandomModel>();
    
    if (!random.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.shuffle, size: 24),
              SizedBox(width: 12),
              Text("Random: Loading..."),
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
                Icon(Icons.shuffle, size: 20),
                SizedBox(width: 8),
                Text(
                  "Random Generator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildCoinFlipSection(context, random),
            SizedBox(height: 12),
            _buildDiceSection(context, random),
            SizedBox(height: 12),
            _buildRandomNumberSection(context, random),
            SizedBox(height: 12),
            _buildPasswordSection(context, random),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoinFlipSection(BuildContext context, RandomModel random) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.currency_exchange, size: 20, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                random.coinResult.isEmpty ? "Tap to flip" : random.coinResult,
                style: TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 18),
              onPressed: () => random.flipCoin(),
              tooltip: "Flip coin",
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiceSection(BuildContext context, RandomModel random) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.casino, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Dice Roll", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: _diceOptions.map((sides) => ButtonSegment(
                      value: _diceOptions.indexOf(sides),
                      label: Text("D$sides", style: TextStyle(fontSize: 10)),
                    )).toList(),
                    selected: {_selectedDiceIndex},
                    onSelectionChanged: (Set<int> selection) {
                      setState(() {
                        _selectedDiceIndex = selection.first;
                      });
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 50,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    random.diceResult.isEmpty ? "-" : random.diceResult,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 18),
                  onPressed: () => random.rollDice(_diceOptions[_selectedDiceIndex]),
                  tooltip: "Roll dice",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRandomNumberSection(BuildContext context, RandomModel random) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pin, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Random Number", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _minController,
                    decoration: InputDecoration(
                      labelText: "Min",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(signed: true),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(width: 8),
                Text("-", style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _maxController,
                    decoration: InputDecoration(
                      labelText: "Max",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(signed: true),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    random.randomNumberResult.isEmpty ? "-" : random.randomNumberResult,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    final min = int.tryParse(_minController.text) ?? 1;
                    final max = int.tryParse(_maxController.text) ?? 100;
                    if (min <= max) {
                      random.generateRandomNumber(min, max);
                    }
                  },
                  tooltip: "Generate number",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPasswordSection(BuildContext context, RandomModel random) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.password, size: 20, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Password Generator", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Length:", style: TextStyle(fontSize: 12)),
                SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: random.passwordLength.toDouble(),
                    min: 4,
                    max: 64,
                    divisions: 60,
                    label: "${random.passwordLength}",
                    onChanged: (value) => random.setPasswordLength(value.round()),
                  ),
                ),
                Text("${random.passwordLength}", style: TextStyle(fontSize: 12)),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.refresh, size: 18),
                  onPressed: () => random.generatePassword(random.passwordLength),
                  tooltip: "Generate password",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 4,
              children: [
                _buildPasswordOptionChip(context, random, "a-z", random.passwordIncludeLower, (v) => 
                  random.setPasswordOptions(lower: v, upper: random.passwordIncludeUpper, numbers: random.passwordIncludeNumbers, symbols: random.passwordIncludeSymbols)),
                _buildPasswordOptionChip(context, random, "A-Z", random.passwordIncludeUpper, (v) => 
                  random.setPasswordOptions(lower: random.passwordIncludeLower, upper: v, numbers: random.passwordIncludeNumbers, symbols: random.passwordIncludeSymbols)),
                _buildPasswordOptionChip(context, random, "0-9", random.passwordIncludeNumbers, (v) => 
                  random.setPasswordOptions(lower: random.passwordIncludeLower, upper: random.passwordIncludeUpper, numbers: v, symbols: random.passwordIncludeSymbols)),
                _buildPasswordOptionChip(context, random, "!@#", random.passwordIncludeSymbols, (v) => 
                  random.setPasswordOptions(lower: random.passwordIncludeLower, upper: random.passwordIncludeUpper, numbers: random.passwordIncludeNumbers, symbols: v)),
              ],
            ),
            if (random.passwordResult.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      random.passwordResult,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 16),
                    onPressed: () => random.copyToClipboard(random.passwordResult, context),
                    tooltip: "Copy password",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPasswordOptionChip(BuildContext context, RandomModel random, String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: onChanged,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
      ),
    );
  }
}