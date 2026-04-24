import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

MorseCodeModel morseCodeModel = MorseCodeModel();

MyProvider providerMorseCode = MyProvider(
    name: "MorseCode",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Morse Encode',
      keywords: 'morse code encode text convert dot dash',
      action: () {
        morseCodeModel.setOperation('encode');
        Global.infoModel.addInfo(
            "MorseEncode",
            "Morse Encode",
            subtitle: "Convert text to Morse code",
            icon: Icon(Icons.signal_cellular_alt, size: 24),
            onTap: () => morseCodeModel.setOperation('encode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Morse Decode',
      keywords: 'morse code decode text convert dot dash',
      action: () {
        morseCodeModel.setOperation('decode');
        Global.infoModel.addInfo(
            "MorseDecode",
            "Morse Decode",
            subtitle: "Convert Morse code to text",
            icon: Icon(Icons.signal_cellular_alt, size: 24),
            onTap: () => morseCodeModel.setOperation('decode'));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  morseCodeModel.init();
  Global.infoModel.addInfoWidget(
      "MorseCode",
      ChangeNotifierProvider.value(
          value: morseCodeModel,
          builder: (context, child) => MorseCodeCard()),
      title: "Morse Code Encoder/Decoder");
}

Future<void> _update() async {
  morseCodeModel.refresh();
}

class MorseCodeModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputText = "";
  String _operation = "encode";
  String? _error;
  List<_MorseHistoryEntry> _history = [];
  
  bool get isInitialized => _isInitialized;
  String get inputText => _inputText;
  String get outputText => _outputText;
  String get operation => _operation;
  String? get error => _error;
  List<_MorseHistoryEntry> get history => _history;
  
  static const List<String> operations = ['encode', 'decode'];
  
  static const Map<String, String> morseCodeMap = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
    '.': '.-.-.-',
    ',': '--..--',
    '?': '..--..',
    "'": '.----.',
    '!': '-.-.--',
    '/': '-..-.',
    '(': '-.--.',
    ')': '-.--.-',
    '&': '.-...',
    ':': '---...',
    ';': '-.-.-.',
    '=': '-...-',
    '+': '.-.-.',
    '-': '-....-',
    '_': '..--.-',
    '"': '.-..-.',
    '\$': '...-..-',
    '@': '.--.-.',
    ' ': '/',
  };

  static Map<String, String> get reverseMorseCodeMap {
    final Map<String, String> reverse = {};
    for (final entry in morseCodeMap.entries) {
      reverse[entry.value] = entry.key;
    }
    return reverse;
  }

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("MorseCode initialized", source: "MorseCode");
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
    Global.loggerModel.info("Operation swapped to: $_operation", source: "MorseCode");
  }

  void clearInput() {
    _inputText = "";
    _outputText = "";
    _error = null;
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
        _outputText = _encodeToMorse(_inputText);
      } else {
        _outputText = _decodeFromMorse(_inputText);
      }
      Global.loggerModel.info("Processed morse $_operation", source: "MorseCode");
    } catch (e) {
      _error = "Error: ${e.toString()}";
      _outputText = "";
      Global.loggerModel.warning("Processing error: $e", source: "MorseCode");
    }
    notifyListeners();
  }

  String _encodeToMorse(String text) {
    final upperText = text.toUpperCase();
    final List<String> morseChars = [];
    
    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      if (morseCodeMap.containsKey(char)) {
        morseChars.add(morseCodeMap[char]!);
      } else {
        morseChars.add('?');
      }
    }
    
    return morseChars.join(' ');
  }

  String _decodeFromMorse(String morse) {
    final morseClean = morse.trim();
    final morseChars = morseClean.split(RegExp(r'\s+'));
    final List<String> textChars = [];
    
    final reverseMap = reverseMorseCodeMap;
    
    for (final morseChar in morseChars) {
      if (morseChar.isEmpty) continue;
      if (reverseMap.containsKey(morseChar)) {
        textChars.add(reverseMap[morseChar]!);
      } else {
        textChars.add('?');
      }
    }
    
    return textChars.join();
  }

  void addToHistory() {
    if (_outputText.isNotEmpty && _error == null) {
      _history.insert(0, _MorseHistoryEntry(
        input: _inputText,
        output: _outputText,
        operation: _operation,
        timestamp: DateTime.now(),
      ));
      if (_history.length > 10) {
        _history.removeLast();
      }
      Global.loggerModel.info("Added to history: morse $_operation", source: "MorseCode");
      notifyListeners();
    }
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _inputText = entry.input;
      _operation = entry.operation;
      _process();
      Global.loggerModel.info("Loaded from history: index $index", source: "MorseCode");
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "MorseCode");
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

class _MorseHistoryEntry {
  final String input;
  final String output;
  final String operation;
  final DateTime timestamp;

  _MorseHistoryEntry({
    required this.input,
    required this.output,
    required this.operation,
    required this.timestamp,
  });
}

class MorseCodeCard extends StatefulWidget {
  @override
  State<MorseCodeCard> createState() => _MorseCodeCardState();
}

class _MorseCodeCardState extends State<MorseCodeCard> {
  final TextEditingController _inputController = TextEditingController();
  bool _showHistory = false;
  
  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final model = context.watch<MorseCodeModel>();
    
    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 24),
              SizedBox(width: 12),
              Text("Morse Code: Loading..."),
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
            if (_showHistory && model.history.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildHistorySection(context, model),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, MorseCodeModel model) {
    return Row(
      children: [
        Icon(Icons.signal_cellular_alt, size: 20),
        SizedBox(width: 8),
        Text(
          "Morse Code",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Spacer(),
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
  
  Widget _buildOperationSelector(BuildContext context, MorseCodeModel model) {
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
  
  Widget _buildInputField(BuildContext context, MorseCodeModel model) {
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
                    ? "Enter text to encode..."
                    : "Enter Morse code (use spaces between characters)...",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 12),
              maxLines: 3,
              onChanged: (value) => model.setInputText(value),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildError(BuildContext context, MorseCodeModel model) {
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
  
  Widget _buildOutputField(BuildContext context, MorseCodeModel model) {
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
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context, MorseCodeModel model) {
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
  
  Widget _buildHistorySection(BuildContext context, MorseCodeModel model) {
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