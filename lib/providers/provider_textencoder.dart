import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

TextEncoderModel textEncoderModel = TextEncoderModel();

MyProvider providerTextEncoder = MyProvider(
    name: "TextEncoder",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Base64 Encode',
      keywords: 'base64 encode text string convert',
      action: () {
        textEncoderModel.setMode('base64');
        textEncoderModel.setOperation('encode');
        Global.infoModel.addInfo(
            "Base64Encode",
            "Base64 Encode",
            subtitle: "Encode text to Base64",
            icon: Icon(Icons.code, size: 24),
            onTap: () => textEncoderModel.setOperation('encode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'Base64 Decode',
      keywords: 'base64 decode text string convert',
      action: () {
        textEncoderModel.setMode('base64');
        textEncoderModel.setOperation('decode');
        Global.infoModel.addInfo(
            "Base64Decode",
            "Base64 Decode",
            subtitle: "Decode Base64 to text",
            icon: Icon(Icons.code, size: 24),
            onTap: () => textEncoderModel.setOperation('decode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'URL Encode',
      keywords: 'url encode uri text string percent',
      action: () {
        textEncoderModel.setMode('url');
        textEncoderModel.setOperation('encode');
        Global.infoModel.addInfo(
            "URLEncode",
            "URL Encode",
            subtitle: "Encode text for URLs",
            icon: Icon(Icons.link, size: 24),
            onTap: () => textEncoderModel.setOperation('encode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'URL Decode',
      keywords: 'url decode uri text string percent',
      action: () {
        textEncoderModel.setMode('url');
        textEncoderModel.setOperation('decode');
        Global.infoModel.addInfo(
            "URLDecode",
            "URL Decode",
            subtitle: "Decode URL-encoded text",
            icon: Icon(Icons.link, size: 24),
            onTap: () => textEncoderModel.setOperation('decode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'HTML Encode',
      keywords: 'html encode escape text string entity',
      action: () {
        textEncoderModel.setMode('html');
        textEncoderModel.setOperation('encode');
        Global.infoModel.addInfo(
            "HTMLEncode",
            "HTML Encode",
            subtitle: "Encode text for HTML",
            icon: Icon(Icons.html, size: 24),
            onTap: () => textEncoderModel.setOperation('encode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'HTML Decode',
      keywords: 'html decode unescape text string entity',
      action: () {
        textEncoderModel.setMode('html');
        textEncoderModel.setOperation('decode');
        Global.infoModel.addInfo(
            "HTMLDecode",
            "HTML Decode",
            subtitle: "Decode HTML-escaped text",
            icon: Icon(Icons.html, size: 24),
            onTap: () => textEncoderModel.setOperation('decode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'JSON Escape',
      keywords: 'json escape encode text string quote',
      action: () {
        textEncoderModel.setMode('json');
        textEncoderModel.setOperation('encode');
        Global.infoModel.addInfo(
            "JSONEscape",
            "JSON Escape",
            subtitle: "Escape text for JSON",
            icon: Icon(Icons.data_object, size: 24),
            onTap: () => textEncoderModel.setOperation('encode'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'JSON Unescape',
      keywords: 'json unescape decode text string quote',
      action: () {
        textEncoderModel.setMode('json');
        textEncoderModel.setOperation('decode');
        Global.infoModel.addInfo(
            "JSONUnescape",
            "JSON Unescape",
            subtitle: "Unescape JSON text",
            icon: Icon(Icons.data_object, size: 24),
            onTap: () => textEncoderModel.setOperation('decode'));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  textEncoderModel.init();
  Global.infoModel.addInfoWidget(
      "TextEncoder",
      ChangeNotifierProvider.value(
          value: textEncoderModel,
          builder: (context, child) => TextEncoderCard()),
      title: "Text Encoder/Decoder");
}

Future<void> _update() async {
  textEncoderModel.refresh();
}

class TextEncoderModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputText = "";
  String _mode = "base64";
  String _operation = "encode";
  String? _error;
  List<_HistoryEntry> _history = [];
  
  bool get isInitialized => _isInitialized;
  String get inputText => _inputText;
  String get outputText => _outputText;
  String get mode => _mode;
  String get operation => _operation;
  String? get error => _error;
  List<_HistoryEntry> get history => _history;
  
  static const List<String> modes = ['base64', 'url', 'html', 'json'];
  static const List<String> operations = ['encode', 'decode'];

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("TextEncoder initialized", source: "TextEncoder");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setInputText(String text) {
    _inputText = text;
    _process();
  }

  void setMode(String mode) {
    if (modes.contains(mode)) {
      _mode = mode;
      _process();
    }
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
    Global.loggerModel.info("Operation swapped to: $_operation", source: "TextEncoder");
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
      switch (_mode) {
        case 'base64':
          _outputText = _processBase64();
          break;
        case 'url':
          _outputText = _processUrl();
          break;
        case 'html':
          _outputText = _processHtml();
          break;
        case 'json':
          _outputText = _processJson();
          break;
      }
      Global.loggerModel.info("Processed $_mode $_operation", source: "TextEncoder");
    } catch (e) {
      _error = "Error: ${e.toString()}";
      _outputText = "";
      Global.loggerModel.warning("Processing error: $e", source: "TextEncoder");
    }
    notifyListeners();
  }

  String _processBase64() {
    if (_operation == 'encode') {
      final bytes = utf8.encode(_inputText);
      return base64.encode(bytes);
    } else {
      final bytes = base64.decode(_inputText);
      return utf8.decode(bytes);
    }
  }

  String _processUrl() {
    if (_operation == 'encode') {
      return Uri.encodeComponent(_inputText);
    } else {
      return Uri.decodeComponent(_inputText);
    }
  }

  String _processHtml() {
    if (_operation == 'encode') {
      return _htmlEncode(_inputText);
    } else {
      return _htmlDecode(_inputText);
    }
  }

  String _htmlEncode(String text) {
    final Map<String, String> htmlEntities = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&apos;',
      ' ': '&nbsp;',
      '©': '&copy;',
      '®': '&reg;',
      '€': '&euro;',
      '£': '&pound;',
      '¥': '&yen;',
      '¢': '&cent;',
      '§': '&sect;',
      '¶': '&para;',
      '°': '&deg;',
      '±': '&plusmn;',
      '×': '&times;',
      '÷': '&divide;',
      '™': '&trade;',
    };
    
    String result = text;
    for (final entry in htmlEntities.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  String _htmlDecode(String text) {
    final Map<String, String> htmlEntities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&nbsp;': ' ',
      '&copy;': '©',
      '&reg;': '®',
      '&euro;': '€',
      '&pound;': '£',
      '&yen;': '¥',
      '&cent;': '¢',
      '&sect;': '§',
      '&para;': '¶',
      '&deg;': '°',
      '&plusmn;': '±',
      '&times;': '×',
      '&divide;': '÷',
      '&trade;': '™',
    };
    
    String result = text;
    for (final entry in htmlEntities.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!)),
    );
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
    return result;
  }

  String _processJson() {
    if (_operation == 'encode') {
      return _jsonEscape(_inputText);
    } else {
      return _jsonUnescape(_inputText);
    }
  }

  String _jsonEscape(String text) {
    String result = text;
    result = result.replaceAll('\\', '\\\\');
    result = result.replaceAll('"', '\\"');
    result = result.replaceAll('\n', '\\n');
    result = result.replaceAll('\r', '\\r');
    result = result.replaceAll('\t', '\\t');
    result = result.replaceAll('\b', '\\b');
    result = result.replaceAll('\f', '\\f');
    return result;
  }

  String _jsonUnescape(String text) {
    String result = text;
    result = result.replaceAll('\\n', '\n');
    result = result.replaceAll('\\r', '\r');
    result = result.replaceAll('\\t', '\t');
    result = result.replaceAll('\\b', '\b');
    result = result.replaceAll('\\f', '\f');
    result = result.replaceAll('\\"', '"');
    result = result.replaceAll('\\\\', '\\');
    return result;
  }

  void addToHistory() {
    if (_outputText.isNotEmpty && _error == null) {
      _history.insert(0, _HistoryEntry(
        input: _inputText,
        output: _outputText,
        mode: _mode,
        operation: _operation,
        timestamp: DateTime.now(),
      ));
      if (_history.length > 10) {
        _history.removeLast();
      }
      Global.loggerModel.info("Added to history: $_mode $_operation", source: "TextEncoder");
      notifyListeners();
    }
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _inputText = entry.input;
      _mode = entry.mode;
      _operation = entry.operation;
      _process();
      Global.loggerModel.info("Loaded from history: index $index", source: "TextEncoder");
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "TextEncoder");
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

  String getModeLabel(String mode) {
    switch (mode) {
      case 'base64': return 'Base64';
      case 'url': return 'URL';
      case 'html': return 'HTML';
      case 'json': return 'JSON';
      default: return mode;
    }
  }

  String getOperationLabel(String operation) {
    return operation == 'encode' ? 'Encode' : 'Decode';
  }
}

class _HistoryEntry {
  final String input;
  final String output;
  final String mode;
  final String operation;
  final DateTime timestamp;

  _HistoryEntry({
    required this.input,
    required this.output,
    required this.mode,
    required this.operation,
    required this.timestamp,
  });
}

class TextEncoderCard extends StatefulWidget {
  @override
  State<TextEncoderCard> createState() => _TextEncoderCardState();
}

class _TextEncoderCardState extends State<TextEncoderCard> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  bool _showHistory = false;
  
  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final model = context.watch<TextEncoderModel>();
    
    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.code, size: 24),
              SizedBox(width: 12),
              Text("Text Encoder: Loading..."),
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
            _buildModeSelector(context, model),
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
  
  Widget _buildHeader(BuildContext context, TextEncoderModel model) {
    return Row(
      children: [
        Icon(Icons.code, size: 20),
        SizedBox(width: 8),
        Text(
          "Text Encoder/Decoder",
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
  
  Widget _buildModeSelector(BuildContext context, TextEncoderModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<String>(
          segments: TextEncoderModel.modes.map((mode) => 
            ButtonSegment(
              value: mode,
              label: Text(model.getModeLabel(mode)),
            )
          ).toList(),
          selected: {model.mode},
          onSelectionChanged: (Set<String> newSelection) {
            model.setMode(newSelection.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.comfortable,
          ),
        ),
        SizedBox(height: 8),
        SegmentedButton<String>(
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
        ),
      ],
    );
  }
  
  Widget _buildInputField(BuildContext context, TextEncoderModel model) {
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
                hintText: "Enter text to ${model.getOperationLabel(model.operation).toLowerCase()}...",
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
  
  Widget _buildError(BuildContext context, TextEncoderModel model) {
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
  
  Widget _buildOutputField(BuildContext context, TextEncoderModel model) {
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
  
  Widget _buildActionButtons(BuildContext context, TextEncoderModel model) {
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
  
  Widget _buildHistorySection(BuildContext context, TextEncoderModel model) {
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
                  "${model.getModeLabel(historyItem.mode)} ${model.getOperationLabel(historyItem.operation)}",
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