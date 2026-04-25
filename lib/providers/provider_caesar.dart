import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

CaesarCipherModel caesarCipherModel = CaesarCipherModel();

MyProvider providerCaesarCipher = MyProvider(
    name: "CaesarCipher",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Caesar Encrypt',
      keywords: 'caesar cipher encrypt shift rotate classic',
      action: () {
        caesarCipherModel.setOperation('encrypt');
        Global.infoModel.addInfo(
            "CaesarEncrypt",
            "Caesar Encrypt",
            subtitle: "Encrypt text using Caesar cipher",
            icon: Icon(Icons.lock, size: 24),
            onTap: () => caesarCipherModel.setOperation('encrypt'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Caesar Decrypt',
      keywords: 'caesar cipher decrypt shift rotate classic',
      action: () {
        caesarCipherModel.setOperation('decrypt');
        Global.infoModel.addInfo(
            "CaesarDecrypt",
            "Caesar Decrypt",
            subtitle: "Decrypt text using Caesar cipher",
            icon: Icon(Icons.lock_open, size: 24),
            onTap: () => caesarCipherModel.setOperation('decrypt'));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  caesarCipherModel.init();
  Global.infoModel.addInfoWidget(
      "CaesarCipher",
      ChangeNotifierProvider.value(
          value: caesarCipherModel,
          builder: (context, child) => CaesarCipherCard()),
      title: "Caesar Cipher Encoder/Decoder");
}

Future<void> _update() async {
  caesarCipherModel.refresh();
}

class CaesarCipherModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputText = "";
  String _operation = "encrypt";
  int _shift = 3;
  String? _error;
  List<_CaesarHistoryEntry> _history = [];

  bool get isInitialized => _isInitialized;
  String get inputText => _inputText;
  String get outputText => _outputText;
  String get operation => _operation;
  int get shift => _shift;
  String? get error => _error;
  List<_CaesarHistoryEntry> get history => _history;

  static const List<String> operations = ['encrypt', 'decrypt'];

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("CaesarCipher initialized", source: "CaesarCipher");
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

  void setShift(int value) {
    _shift = value % 26;
    _process();
  }

  void swapOperation() {
    _operation = _operation == 'encrypt' ? 'decrypt' : 'encrypt';
    _process();
    Global.loggerModel.info("Operation swapped to: $_operation", source: "CaesarCipher");
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
      if (_operation == 'encrypt') {
        _outputText = _caesarEncrypt(_inputText, _shift);
      } else {
        _outputText = _caesarDecrypt(_inputText, _shift);
      }
      Global.loggerModel.info("Processed caesar $_operation with shift $_shift", source: "CaesarCipher");
    } catch (e) {
      _error = "Error: ${e.toString()}";
      _outputText = "";
      Global.loggerModel.warning("Processing error: $e", source: "CaesarCipher");
    }
    notifyListeners();
  }

  String _caesarEncrypt(String text, int shift) {
    final List<String> result = [];
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (_isLetter(char)) {
        final base = _isUpperCase(char) ? 65 : 97;
        final code = char.codeUnitAt(0);
        final shiftedCode = ((code - base + shift) % 26) + base;
        result.add(String.fromCharCode(shiftedCode));
      } else {
        result.add(char);
      }
    }
    return result.join();
  }

  String _caesarDecrypt(String text, int shift) {
    return _caesarEncrypt(text, 26 - shift);
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
    if (_outputText.isNotEmpty && _error == null) {
      _history.insert(0, _CaesarHistoryEntry(
        input: _inputText,
        output: _outputText,
        operation: _operation,
        shift: _shift,
        timestamp: DateTime.now(),
      ));
      if (_history.length > 10) {
        _history.removeLast();
      }
      Global.loggerModel.info("Added to history: caesar $_operation", source: "CaesarCipher");
      notifyListeners();
    }
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _inputText = entry.input;
      _operation = entry.operation;
      _shift = entry.shift;
      _process();
      Global.loggerModel.info("Loaded from history: index $index", source: "CaesarCipher");
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "CaesarCipher");
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

class _CaesarHistoryEntry {
  final String input;
  final String output;
  final String operation;
  final int shift;
  final DateTime timestamp;

  _CaesarHistoryEntry({
    required this.input,
    required this.output,
    required this.operation,
    required this.shift,
    required this.timestamp,
  });
}

class CaesarCipherCard extends StatefulWidget {
  @override
  State<CaesarCipherCard> createState() => _CaesarCipherCardState();
}

class _CaesarCipherCardState extends State<CaesarCipherCard> {
  final TextEditingController _inputController = TextEditingController();
  bool _showHistory = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CaesarCipherModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.lock, size: 24),
              SizedBox(width: 12),
              Text("Caesar Cipher: Loading..."),
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
            _buildShiftSelector(context, model),
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

  Widget _buildHeader(BuildContext context, CaesarCipherModel model) {
    return Row(
      children: [
        Icon(Icons.lock, size: 20),
        SizedBox(width: 8),
        Text(
          "Caesar Cipher",
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

  Widget _buildOperationSelector(BuildContext context, CaesarCipherModel model) {
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

  Widget _buildShiftSelector(BuildContext context, CaesarCipherModel model) {
    return Row(
      children: [
        Text("Shift: ", style: TextStyle(fontSize: 12)),
        SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: model.shift.toDouble(),
            min: 0,
            max: 25,
            divisions: 25,
            label: model.shift.toString(),
            onChanged: (value) => model.setShift(value.toInt()),
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            model.shift.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context, CaesarCipherModel model) {
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

  Widget _buildError(BuildContext context, CaesarCipherModel model) {
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

  Widget _buildOutputField(BuildContext context, CaesarCipherModel model) {
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

  Widget _buildActionButtons(BuildContext context, CaesarCipherModel model) {
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

  Widget _buildHistorySection(BuildContext context, CaesarCipherModel model) {
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
                  "${model.getOperationLabel(historyItem.operation)} (shift ${historyItem.shift})",
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