import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

VigenereCipherModel vigenereCipherModel = VigenereCipherModel();

MyProvider providerVigenereCipher = MyProvider(
    name: "VigenereCipher",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Vigenere Encrypt',
      keywords: 'vigenere cipher encrypt keyword polyalphabetic classic',
      action: () {
        vigenereCipherModel.setOperation('encrypt');
        Global.infoModel.addInfo(
            "VigenereEncrypt",
            "Vigenere Encrypt",
            subtitle: "Encrypt text using Vigenere cipher",
            icon: Icon(Icons.lock, size: 24),
            onTap: () => vigenereCipherModel.setOperation('encrypt'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Vigenere Decrypt',
      keywords: 'vigenere cipher decrypt keyword polyalphabetic classic',
      action: () {
        vigenereCipherModel.setOperation('decrypt');
        Global.infoModel.addInfo(
            "VigenereDecrypt",
            "Vigenere Decrypt",
            subtitle: "Decrypt text using Vigenere cipher",
            icon: Icon(Icons.lock_open, size: 24),
            onTap: () => vigenereCipherModel.setOperation('decrypt'));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  vigenereCipherModel.init();
  Global.infoModel.addInfoWidget(
      "VigenereCipher",
      ChangeNotifierProvider.value(
          value: vigenereCipherModel,
          builder: (context, child) => VigenereCipherCard()),
      title: "Vigenere Cipher Encoder/Decoder");
}

Future<void> _update() async {
  vigenereCipherModel.refresh();
}

class VigenereCipherModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputText = "";
  String _keyword = "";
  String _operation = "encrypt";
  String? _keywordError;
  String? _inputError;
  List<_VigenereHistoryEntry> _history = [];

  bool get isInitialized => _isInitialized;
  String get inputText => _inputText;
  String get outputText => _outputText;
  String get keyword => _keyword;
  String get operation => _operation;
  String? get keywordError => _keywordError;
  String? get inputError => _inputError;
  List<_VigenereHistoryEntry> get history => _history;

  static const List<String> operations = ['encrypt', 'decrypt'];

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("VigenereCipher initialized", source: "VigenereCipher");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setInputText(String text) {
    _inputText = text;
    _process();
  }

  void setKeyword(String keyword) {
    _keyword = keyword.toUpperCase();
    _validateKeyword();
    _process();
  }

  void setOperation(String operation) {
    if (operations.contains(operation)) {
      _operation = operation;
      _process();
    }
  }

  void swapOperation() {
    _operation = _operation == 'encrypt' ? 'decrypt' : 'encrypt';
    _process();
    Global.loggerModel.info("Operation swapped to: $_operation", source: "VigenereCipher");
  }

  void clearInput() {
    _inputText = "";
    _outputText = "";
    _inputError = null;
    notifyListeners();
  }

  void clearAll() {
    _inputText = "";
    _keyword = "";
    _outputText = "";
    _keywordError = null;
    _inputError = null;
    notifyListeners();
  }

  void _validateKeyword() {
    if (_keyword.isEmpty) {
      _keywordError = null;
      return;
    }
    for (int i = 0; i < _keyword.length; i++) {
      final code = _keyword.codeUnitAt(i);
      if (code < 65 || code > 90) {
        _keywordError = "Keyword must contain only letters";
        return;
      }
    }
    _keywordError = null;
  }

  void _process() {
    if (_inputText.isEmpty) {
      _outputText = "";
      _inputError = null;
      notifyListeners();
      return;
    }

    if (_keyword.isEmpty) {
      _outputText = "";
      _keywordError = "Keyword required";
      notifyListeners();
      return;
    }

    if (_keywordError != null) {
      _outputText = "";
      notifyListeners();
      return;
    }

    try {
      _inputError = null;
      if (_operation == 'encrypt') {
        _outputText = _vigenereEncrypt(_inputText, _keyword);
      } else {
        _outputText = _vigenereDecrypt(_inputText, _keyword);
      }
      Global.loggerModel.info("Processed vigenere $_operation with keyword '$_keyword'", source: "VigenereCipher");
    } catch (e) {
      _inputError = "Error: ${e.toString()}";
      _outputText = "";
      Global.loggerModel.warning("Processing error: $e", source: "VigenereCipher");
    }
    notifyListeners();
  }

  String _vigenereEncrypt(String text, String keyword) {
    final List<String> result = [];
    int keywordIndex = 0;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (_isLetter(char)) {
        final base = _isUpperCase(char) ? 65 : 97;
        final code = char.codeUnitAt(0);
        final keyChar = keyword[keywordIndex % keyword.length];
        final keyShift = keyChar.codeUnitAt(0) - 65;
        final shiftedCode = ((code - base + keyShift) % 26) + base;
        result.add(String.fromCharCode(shiftedCode));
        keywordIndex++;
      } else {
        result.add(char);
      }
    }
    return result.join();
  }

  String _vigenereDecrypt(String text, String keyword) {
    final List<String> result = [];
    int keywordIndex = 0;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (_isLetter(char)) {
        final base = _isUpperCase(char) ? 65 : 97;
        final code = char.codeUnitAt(0);
        final keyChar = keyword[keywordIndex % keyword.length];
        final keyShift = keyChar.codeUnitAt(0) - 65;
        final shiftedCode = ((code - base - keyShift + 26) % 26) + base;
        result.add(String.fromCharCode(shiftedCode));
        keywordIndex++;
      } else {
        result.add(char);
      }
    }
    return result.join();
  }

  bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isUpperCase(String char) {
    final code = char.codeUnitAt(0);
    return code >= 65 && code <= 90;
  }

  void addToHistory() {
    if (_outputText.isNotEmpty && _keywordError == null && _inputError == null) {
      _history.insert(0, _VigenereHistoryEntry(
        input: _inputText,
        output: _outputText,
        keyword: _keyword,
        operation: _operation,
        timestamp: DateTime.now(),
      ));
      if (_history.length > 10) {
        _history.removeLast();
      }
      Global.loggerModel.info("Added to history: vigenere $_operation", source: "VigenereCipher");
      notifyListeners();
    }
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _inputText = entry.input;
      _keyword = entry.keyword;
      _operation = entry.operation;
      _validateKeyword();
      _process();
      Global.loggerModel.info("Loaded from history: index $index", source: "VigenereCipher");
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "VigenereCipher");
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
    return operation == 'encrypt' ? 'Encrypt' : 'Decrypt';
  }
}

class _VigenereHistoryEntry {
  final String input;
  final String output;
  final String keyword;
  final String operation;
  final DateTime timestamp;

  _VigenereHistoryEntry({
    required this.input,
    required this.output,
    required this.keyword,
    required this.operation,
    required this.timestamp,
  });
}

class VigenereCipherCard extends StatefulWidget {
  @override
  State<VigenereCipherCard> createState() => _VigenereCipherCardState();
}

class _VigenereCipherCardState extends State<VigenereCipherCard> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  bool _showHistory = false;

  @override
  void dispose() {
    _inputController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<VigenereCipherModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.lock, size: 24),
              SizedBox(width: 12),
              Text("Vigenere Cipher: Loading..."),
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
            _buildKeywordField(context, model),
            SizedBox(height: 12),
            _buildInputField(context, model),
            if (model.keywordError != null) _buildKeywordError(context, model),
            if (model.inputError != null) _buildInputError(context, model),
            if (model.keywordError == null && model.inputError == null) _buildOutputField(context, model),
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

  Widget _buildHeader(BuildContext context, VigenereCipherModel model) {
    return Row(
      children: [
        Icon(Icons.vpn_key, size: 20),
        SizedBox(width: 8),
        Text(
          "Vigenere Cipher",
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

  Widget _buildOperationSelector(BuildContext context, VigenereCipherModel model) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'encrypt', label: Text("Encrypt")),
        ButtonSegment(value: 'decrypt', label: Text("Decrypt")),
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

  Widget _buildKeywordField(BuildContext context, VigenereCipherModel model) {
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
                Icon(Icons.vpn_key_outlined, size: 14),
                SizedBox(width: 4),
                Text("Keyword:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                hintText: "Enter keyword (letters only)...",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 12),
              onChanged: (value) => model.setKeyword(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordError(BuildContext context, VigenereCipherModel model) {
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
                model.keywordError!,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, VigenereCipherModel model) {
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
                hintText: model.operation == 'encrypt'
                    ? "Enter text to encrypt..."
                    : "Enter text to decrypt...",
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

  Widget _buildInputError(BuildContext context, VigenereCipherModel model) {
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
                model.inputError!,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputField(BuildContext context, VigenereCipherModel model) {
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

  Widget _buildActionButtons(BuildContext context, VigenereCipherModel model) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.swap_horiz, size: 18),
          onPressed: () => model.swapOperation(),
          tooltip: "Swap Encrypt/Decrypt",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        IconButton(
          icon: Icon(Icons.clear_all, size: 18),
          onPressed: () {
            _inputController.clear();
            _keywordController.clear();
            model.clearAll();
          },
          tooltip: "Clear All",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
        if (model.outputText.isNotEmpty && model.keywordError == null && model.inputError == null)
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

  Widget _buildHistorySection(BuildContext context, VigenereCipherModel model) {
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
                  "${model.getOperationLabel(historyItem.operation)} (key: ${historyItem.keyword})",
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  historyItem.input.length > 30 ? "${historyItem.input.substring(0, 30)}..." : historyItem.input,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {
                  model.loadFromHistory(index);
                  _inputController.text = model.inputText;
                  _keywordController.text = model.keyword;
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}