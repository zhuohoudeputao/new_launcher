import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

NatoPhoneticModel natoPhoneticModel = NatoPhoneticModel();

MyProvider providerNatoPhonetic = MyProvider(
    name: "NatoPhonetic",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'NATO Phonetic',
      keywords: 'nato phonetic alphabet radio spelling alpha bravo charlie',
      action: () {
        Global.infoModel.addInfo(
            "NatoPhonetic",
            "NATO Phonetic Alphabet",
            subtitle: "Convert text to NATO phonetic code",
            icon: Icon(Icons.record_voice_over, size: 24),
            onTap: () {});
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  natoPhoneticModel.init();
  Global.infoModel.addInfoWidget(
      "NatoPhonetic",
      ChangeNotifierProvider.value(
          value: natoPhoneticModel,
          builder: (context, child) => NatoPhoneticCard()),
      title: "NATO Phonetic Alphabet");
}

Future<void> _update() async {
  natoPhoneticModel.refresh();
}

class NatoPhoneticModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputText = "";
  String _operation = "encode";
  String? _error;
  bool _showReference = false;
  List<_NatoHistoryEntry> _history = [];

  bool get isInitialized => _isInitialized;
  String get inputText => _inputText;
  String get outputText => _outputText;
  String get operation => _operation;
  String? get error => _error;
  bool get showReference => _showReference;
  List<_NatoHistoryEntry> get history => _history;

  static const List<String> operations = ['encode', 'decode'];

  static const Map<String, String> natoMap = {
    'A': 'Alpha',
    'B': 'Bravo',
    'C': 'Charlie',
    'D': 'Delta',
    'E': 'Echo',
    'F': 'Foxtrot',
    'G': 'Golf',
    'H': 'Hotel',
    'I': 'India',
    'J': 'Juliet',
    'K': 'Kilo',
    'L': 'Lima',
    'M': 'Mike',
    'N': 'November',
    'O': 'Oscar',
    'P': 'Papa',
    'Q': 'Quebec',
    'R': 'Romeo',
    'S': 'Sierra',
    'T': 'Tango',
    'U': 'Uniform',
    'V': 'Victor',
    'W': 'Whiskey',
    'X': 'X-ray',
    'Y': 'Yankee',
    'Z': 'Zulu',
    '0': 'Zero',
    '1': 'One',
    '2': 'Two',
    '3': 'Three',
    '4': 'Four',
    '5': 'Five',
    '6': 'Six',
    '7': 'Seven',
    '8': 'Eight',
    '9': 'Nine',
  };

  static Map<String, String> get reverseNatoMap {
    final Map<String, String> reverse = {};
    for (final entry in natoMap.entries) {
      reverse[entry.value.toLowerCase()] = entry.key;
    }
    return reverse;
  }

  static List<MapEntry<String, String>> get natoList {
    return natoMap.entries.toList();
  }

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("NatoPhonetic initialized", source: "NatoPhonetic");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setInputText(String text) {
    _inputText = text;
    _process();
  }

  void setOperation(String operation) {
    if (operations.contains(operation)) {
      _operation = operation;
      _process();
    }
  }

  void swapOperation() {
    _operation = _operation == 'encode' ? 'decode' : 'encode';
    _process();
    Global.loggerModel.info("Operation swapped to: $_operation", source: "NatoPhonetic");
  }

  void clearInput() {
    _inputText = "";
    _outputText = "";
    _error = null;
    notifyListeners();
  }

  void toggleReference() {
    _showReference = !_showReference;
    notifyListeners();
  }

  void _process() {
    if (_inputText.isEmpty) {
      _outputText = "";
      _error = null;
      notifyListeners();
      return;
    }

    try {
      _error = null;
      if (_operation == 'encode') {
        _outputText = _encodeToNato(_inputText);
      } else {
        _outputText = _decodeFromNato(_inputText);
      }
      Global.loggerModel.info("Processed nato $_operation", source: "NatoPhonetic");
    } catch (e) {
      _error = "Error: ${e.toString()}";
      _outputText = "";
      Global.loggerModel.warning("Processing error: $e", source: "NatoPhonetic");
    }
    notifyListeners();
  }

  String _encodeToNato(String text) {
    final upperText = text.toUpperCase();
    final List<String> natoWords = [];

    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      if (natoMap.containsKey(char)) {
        natoWords.add(natoMap[char]!);
      } else if (char == ' ') {
        natoWords.add('(space)');
      } else {
        natoWords.add(char);
      }
    }

    return natoWords.join(' ');
  }

  String _decodeFromNato(String nato) {
    final natoClean = nato.trim();
    final natoWords = natoClean.split(RegExp(r'\s+'));
    final List<String> textChars = [];

    final reverseMap = reverseNatoMap;

    for (final natoWord in natoWords) {
      if (natoWord.isEmpty) continue;
      if (natoWord.toLowerCase() == '(space)') {
        textChars.add(' ');
      } else if (reverseMap.containsKey(natoWord.toLowerCase())) {
        textChars.add(reverseMap[natoWord.toLowerCase()]!);
      } else if (natoWord.length == 1) {
        textChars.add(natoWord.toUpperCase());
      } else {
        textChars.add('?');
      }
    }

    return textChars.join();
  }

  void addToHistory() {
    if (_outputText.isNotEmpty && _error == null) {
      _history.insert(0, _NatoHistoryEntry(
        input: _inputText,
        output: _outputText,
        operation: _operation,
        timestamp: DateTime.now(),
      ));
      if (_history.length > 10) {
        _history.removeLast();
      }
      Global.loggerModel.info("Added to history: nato $_operation", source: "NatoPhonetic");
      notifyListeners();
    }
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _inputText = entry.input;
      _operation = entry.operation;
      _process();
      Global.loggerModel.info("Loaded from history: index $index", source: "NatoPhonetic");
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "NatoPhonetic");
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

  String getOperationLabel(String operation) {
    return operation == 'encode' ? 'Encode' : 'Decode';
  }
}

class _NatoHistoryEntry {
  final String input;
  final String output;
  final String operation;
  final DateTime timestamp;

  _NatoHistoryEntry({
    required this.input,
    required this.output,
    required this.operation,
    required this.timestamp,
  });
}

class NatoPhoneticCard extends StatefulWidget {
  @override
  State<NatoPhoneticCard> createState() => _NatoPhoneticCardState();
}

class _NatoPhoneticCardState extends State<NatoPhoneticCard> {
  final TextEditingController _inputController = TextEditingController();
  bool _showHistory = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<NatoPhoneticModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.record_voice_over, size: 24),
              SizedBox(width: 12),
              Text("NATO Phonetic: Loading..."),
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
            _buildHeader(context, model),
            SizedBox(height: 12),
            _buildOperationSelector(context, model),
            SizedBox(height: 12),
            _buildInputField(context, model),
            if (model.error != null) _buildError(context, model),
            if (model.error == null) _buildOutputField(context, model),
            SizedBox(height: 8),
            _buildActionButtons(context, model),
            if (model.showReference) ...[
              SizedBox(height: 12),
              _buildReferenceSection(context, model),
            ],
            if (_showHistory && model.history.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildHistorySection(context, model),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NatoPhoneticModel model) {
    return Row(
      children: [
        Icon(Icons.record_voice_over, size: 20),
        SizedBox(width: 8),
        Text(
          "NATO Phonetic Alphabet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Spacer(),
        IconButton(
          icon: Icon(model.showReference ? Icons.book : Icons.book_outlined, size: 18),
          onPressed: () => model.toggleReference(),
          tooltip: "Reference",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (model.history.isNotEmpty)
          IconButton(
            icon: Icon(_showHistory ? Icons.history : Icons.history_outlined, size: 18),
            onPressed: () {
              setState(() => _showHistory = !_showHistory);
            },
            tooltip: "History",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildOperationSelector(BuildContext context, NatoPhoneticModel model) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'encode', label: Text("Encode")),
        ButtonSegment(value: 'decode', label: Text("Decode")),
      ],
      selected: {model.operation},
      onSelectionChanged: (Set<String> newSelection) {
        model.setOperation(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }

  Widget _buildInputField(BuildContext context, NatoPhoneticModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Input:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: model.operation == 'encode'
                    ? "Enter text to convert..."
                    : "Enter NATO words (separated by spaces)...",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 12),
              maxLines: 2,
              onChanged: (value) => model.setInputText(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, NatoPhoneticModel model) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: Theme.of(context).colorScheme.error),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                model.error!,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputField(BuildContext context, NatoPhoneticModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text("Output:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, size: 14),
                  onPressed: () => model.copyToClipboard(model.outputText, context),
                  tooltip: "Copy",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: Size(24, 24),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SelectableText(
              model.outputText,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, NatoPhoneticModel model) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.swap_horiz, size: 18),
          onPressed: () => model.swapOperation(),
          tooltip: "Swap Encode/Decode",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        IconButton(
          icon: Icon(Icons.clear, size: 18),
          onPressed: () {
            _inputController.clear();
            model.clearInput();
          },
          tooltip: "Clear",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
        if (model.outputText.isNotEmpty && model.error == null)
          IconButton(
            icon: Icon(Icons.save_outlined, size: 18),
            onPressed: () => model.addToHistory(),
            tooltip: "Save to history",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildReferenceSection(BuildContext context, NatoPhoneticModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.book, size: 16),
                SizedBox(width: 8),
                Text("NATO Phonetic Reference", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: NatoPhoneticModel.natoList.map((entry) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${entry.key}: ${entry.value}",
                    style: TextStyle(fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, NatoPhoneticModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 16),
                SizedBox(width: 8),
                Text("History (${model.history.length})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 14),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Clear History"),
                        content: Text("Clear all ${model.history.length} history entries?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              model.clearHistory();
                              Navigator.pop(context);
                            },
                            child: Text("Clear"),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: "Clear history",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: Size(24, 24),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...model.history.asMap().entries.map((entry) {
              final index = entry.key;
              final historyItem = entry.value;
              return ListTile(
                dense: true,
                leading: Text("${index + 1}", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.secondary)),
                title: Text(
                  model.getOperationLabel(historyItem.operation),
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  historyItem.input.length > 30 ? "${historyItem.input.substring(0, 30)}..." : historyItem.input,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {
                  model.loadFromHistory(index);
                  _inputController.text = model.inputText;
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}