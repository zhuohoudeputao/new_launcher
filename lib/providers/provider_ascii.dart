import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class AsciiModel extends ChangeNotifier {
  String _inputText = '';
  String _outputText = '';
  String _mode = 'encode';
  bool _showReference = false;
  bool _isInitialized = false;
  List<Map<String, dynamic>> _history = [];
  static const int _maxHistoryLength = 10;

  String get inputText => _inputText;
  String get outputText => _outputText;
  String get mode => _mode;
  bool get showReference => _showReference;
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get history => _history;

  static String textToAscii(String text) {
    return text.codeUnits.map((c) => c.toString()).join(' ');
  }

  static String asciiToText(String ascii) {
    try {
      final codes = ascii.trim().split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .map((s) => int.parse(s))
          .where((c) => c >= 0 && c <= 255)
          .toList();
      return String.fromCharCodes(codes);
    } catch (e) {
      return 'Invalid ASCII codes';
    }
  }

  void init() {
    Global.loggerModel.info("Ascii initialized", source: "Ascii");
    _isInitialized = true;
    notifyListeners();
  }

  void setInputText(String value) {
    _inputText = value;
    if (_mode == 'encode') {
      _outputText = textToAscii(value);
    } else {
      _outputText = asciiToText(value);
    }
    notifyListeners();
  }

  void swapMode() {
    _mode = _mode == 'encode' ? 'decode' : 'encode';
    final temp = _inputText;
    _inputText = _outputText;
    _outputText = temp;
    if (_inputText.isNotEmpty) {
      if (_mode == 'encode') {
        _outputText = textToAscii(_inputText);
      } else {
        _outputText = asciiToText(_inputText);
      }
    }
    notifyListeners();
  }

  void toggleReference() {
    _showReference = !_showReference;
    notifyListeners();
  }

  void addToHistory() {
    if (_inputText.isEmpty || _outputText.isEmpty) return;
    
    final entry = {
      'input': _inputText,
      'output': _outputText,
      'mode': _mode,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _history.insert(0, entry);
    
    if (_history.length > _maxHistoryLength) {
      _history.removeLast();
    }
    
    Global.settingsModel.saveValue('AsciiHistory', 
      _history.map((e) => jsonEncode(e)).toList());
    
    notifyListeners();
  }

  void loadFromHistory(Map<String, dynamic> entry) {
    _inputText = entry['input'] as String;
    _outputText = entry['output'] as String;
    _mode = entry['mode'] as String;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    final saved = await Global.getValue('AsciiHistory', <String>[]);
    if (saved is List<String>) {
      _history = saved.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    }
    notifyListeners();
  }

  void clearInput() {
    _inputText = '';
    _outputText = '';
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    Global.settingsModel.saveValue('AsciiHistory', <String>[]);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  static List<Map<String, String>> getAsciiTable() {
    List<Map<String, String>> table = [];
    for (int i = 32; i <= 126; i++) {
      table.add({
        'code': i.toString(),
        'char': String.fromCharCode(i),
        'name': _getCharName(i),
      });
    }
    return table;
  }

  static String _getCharName(int code) {
    const names = {
      32: 'Space', 33: 'Exclamation', 34: 'Quote', 35: 'Hash',
      36: 'Dollar', 37: 'Percent', 38: 'Ampersand', 39: 'Apostrophe',
      40: 'LParen', 41: 'RParen', 42: 'Star', 43: 'Plus',
      44: 'Comma', 45: 'Hyphen', 46: 'Period', 47: 'Slash',
      48: '0', 49: '1', 50: '2', 51: '3', 52: '4', 53: '5', 54: '6', 55: '7',
      56: '8', 57: '9', 58: 'Colon', 59: 'Semicolon', 60: 'LT', 61: 'Equals',
      62: 'GT', 63: 'Question', 64: 'At',
      65: 'A', 66: 'B', 67: 'C', 68: 'D', 69: 'E', 70: 'F', 71: 'G',
      72: 'H', 73: 'I', 74: 'J', 75: 'K', 76: 'L', 77: 'M', 78: 'N',
      79: 'O', 80: 'P', 81: 'Q', 82: 'R', 83: 'S', 84: 'T', 85: 'U',
      86: 'V', 87: 'W', 88: 'X', 89: 'Y', 90: 'Z',
      91: 'LBracket', 92: 'Backslash', 93: 'RBracket', 94: 'Caret',
      95: 'Underscore', 96: 'Backtick',
      97: 'a', 98: 'b', 99: 'c', 100: 'd', 101: 'e', 102: 'f', 103: 'g',
      104: 'h', 105: 'i', 106: 'j', 107: 'k', 108: 'l', 109: 'm', 110: 'n',
      111: 'o', 112: 'p', 113: 'q', 114: 'r', 115: 's', 116: 't', 117: 'u',
      118: 'v', 119: 'w', 120: 'x', 121: 'y', 122: 'z',
      123: 'LBrace', 124: 'Pipe', 125: 'RBrace', 126: 'Tilde',
    };
    return names[code] ?? '';
  }
}

AsciiModel asciiModel = AsciiModel();

class AsciiCard extends StatelessWidget {
  const AsciiCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AsciiModel>();
    
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('ASCII Converter', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'encode', label: Text('Text → ASCII')),
                  ButtonSegment(value: 'decode', label: Text('ASCII → Text')),
                ],
                selected: {model.mode},
                onSelectionChanged: (Set<String> newSelection) {
                  if (newSelection.first != model.mode) {
                    model.swapMode();
                  }
                },
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: model.mode == 'encode' 
                      ? 'Enter text to convert...' 
                      : 'Enter ASCII codes (space-separated)...',
                  border: OutlineInputBorder(),
                  suffixIcon: model.inputText.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => model.clearInput(),
                        )
                      : null,
                ),
                onChanged: (value) => model.setInputText(value),
              ),
              SizedBox(height: 12),
              if (model.outputText.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    model.outputText,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text('Save to History'),
                      onPressed: model.inputText.isNotEmpty && model.outputText.isNotEmpty
                          ? () => model.addToHistory()
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.swap_horiz),
                      tooltip: 'Swap input/output',
                      onPressed: () => model.swapMode(),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (model.history.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.history),
                      label: Text('History (${model.history.length})'),
                      onPressed: () => _showHistoryDialog(context, model),
                    ),
                  TextButton.icon(
                    icon: Icon(Icons.table_chart),
                    label: Text('ASCII Table'),
                    onPressed: () => model.toggleReference(),
                  ),
                ],
              ),
              if (model.showReference) ...[
                SizedBox(height: 12),
                Text('ASCII Reference (Printable Characters 32-126):',
                  style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: AsciiModel.getAsciiTable().length,
                    itemBuilder: (context, index) {
                      final entry = AsciiModel.getAsciiTable()[index];
                      return InkWell(
                        onTap: () {
                          if (model.mode == 'encode') {
                            final current = model.inputText;
                            model.setInputText(current + entry['char']!);
                          } else {
                            final current = model.inputText;
                            final sep = current.isEmpty ? '' : ' ';
                            model.setInputText(current + sep + entry['code']!);
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withAlpha(50),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(entry['char']!, style: TextStyle(fontSize: 14)),
                              Text(entry['code']!, 
                                style: TextStyle(fontSize: 10, 
                                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, AsciiModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('History'),
            TextButton(
              child: Text('Clear All'),
              onPressed: () {
                model.clearHistory();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: model.history.length,
            itemBuilder: (context, index) {
              final entry = model.history[index];
              final timestamp = DateTime.parse(entry['timestamp'] as String);
              final timeStr = _formatTime(timestamp);
              
              return ListTile(
                leading: Icon(Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.primary),
                title: Text(
                  entry['mode'] == 'encode' 
                    ? '${entry['input']} → ${entry['output']}'
                    : '${entry['input']} → ${entry['output']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(timeStr),
                onTap: () {
                  model.loadFromHistory(entry);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

MyProvider providerAsciiConverter = MyProvider(
  name: "Ascii",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "ASCII Converter",
        keywords: "ascii, converter, encode, decode, character, code, text, char, table",
        action: () {
          Global.infoModel.addInfoWidget("AsciiCard", AsciiCard(), title: "ASCII Converter");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    asciiModel.init();
    asciiModel.loadHistory();
    Global.infoModel.addInfoWidget("AsciiCard", AsciiCard(), title: "ASCII Converter");
  },
  update: () {
    asciiModel.refresh();
  },
);