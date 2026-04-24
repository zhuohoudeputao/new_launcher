import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class TextCaseModel extends ChangeNotifier {
  String _inputText = '';
  String _outputText = '';
  String _caseType = 'uppercase';
  List<Map<String, String>> _history = [];
  bool _isInitialized = false;

  String get inputText => _inputText;
  String get outputText => _outputText;
  String get caseType => _caseType;
  List<Map<String, String>> get history => _history;
  bool get isInitialized => _isInitialized;

  static const List<Map<String, String>> caseTypes = [
    {'name': 'UPPERCASE', 'value': 'uppercase'},
    {'name': 'lowercase', 'value': 'lowercase'},
    {'name': 'Title Case', 'value': 'title'},
    {'name': 'Sentence case', 'value': 'sentence'},
    {'name': 'camelCase', 'value': 'camel'},
    {'name': 'PascalCase', 'value': 'pascal'},
    {'name': 'snake_case', 'value': 'snake'},
    {'name': 'kebab-case', 'value': 'kebab'},
    {'name': 'CONSTANT_CASE', 'value': 'constant'},
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = prefs.getStringList('textcase_history') ?? [];
    _history = savedHistory.map((e) {
      final parts = e.split('|');
      return {
        'input': parts.length > 0 ? parts[0] : '',
        'output': parts.length > 1 ? parts[1] : '',
        'caseType': parts.length > 2 ? parts[2] : 'uppercase',
      };
    }).toList();
    _isInitialized = true;
    notifyListeners();
  }

  void setInputText(String value) {
    _inputText = value;
    _convert();
    notifyListeners();
  }

  void setCaseType(String value) {
    _caseType = value;
    _convert();
    notifyListeners();
  }

  void _convert() {
    if (_inputText.isEmpty) {
      _outputText = '';
      return;
    }

    switch (_caseType) {
      case 'uppercase':
        _outputText = _inputText.toUpperCase();
        break;
      case 'lowercase':
        _outputText = _inputText.toLowerCase();
        break;
      case 'title':
        _outputText = _toTitleCase(_inputText);
        break;
      case 'sentence':
        _outputText = _toSentenceCase(_inputText);
        break;
      case 'camel':
        _outputText = _toCamelCase(_inputText);
        break;
      case 'pascal':
        _outputText = _toPascalCase(_inputText);
        break;
      case 'snake':
        _outputText = _toSnakeCase(_inputText);
        break;
      case 'kebab':
        _outputText = _toKebabCase(_inputText);
        break;
      case 'constant':
        _outputText = _toConstantCase(_inputText);
        break;
      default:
        _outputText = _inputText;
    }
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _toCamelCase(String text) {
    final words = _splitWords(text);
    if (words.isEmpty) return '';
    return words.first.toLowerCase() + 
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join();
  }

  String _toPascalCase(String text) {
    final words = _splitWords(text);
    if (words.isEmpty) return '';
    return words.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join();
  }

  String _toSnakeCase(String text) {
    final words = _splitWords(text);
    return words.map((w) => w.toLowerCase()).join('_');
  }

  String _toKebabCase(String text) {
    final words = _splitWords(text);
    return words.map((w) => w.toLowerCase()).join('-');
  }

  String _toConstantCase(String text) {
    final words = _splitWords(text);
    return words.map((w) => w.toUpperCase()).join('_');
  }

  List<String> _splitWords(String text) {
    return text
        .replaceAll(RegExp(r'[-_]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  void addToHistory() {
    if (_inputText.isEmpty || _outputText.isEmpty) return;
    
    _history.add({
      'input': _inputText,
      'output': _outputText,
      'caseType': _caseType,
    });

    if (_history.length > 10) {
      _history.removeAt(0);
    }

    _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = _history.map((e) => '${e['input']}|${e['output']}|${e['caseType']}').toList();
    await prefs.setStringList('textcase_history', savedHistory);
  }

  void applyFromHistory(int index) {
    if (index < 0 || index >= _history.length) return;
    final entry = _history[index];
    _inputText = entry['input'] ?? '';
    _caseType = entry['caseType'] ?? 'uppercase';
    _convert();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('textcase_history');
    notifyListeners();
  }

  void clearInput() {
    _inputText = '';
    _outputText = '';
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

TextCaseModel textCaseModel = TextCaseModel();

class TextCaseCard extends StatelessWidget {
  const TextCaseCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TextCaseModel>();
    
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
                Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Text Case Converter', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              SegmentedButton<String>(
                segments: TextCaseModel.caseTypes.map((c) => 
                  ButtonSegment(value: c['value']!, label: Text(c['name']!))
                ).toList(),
                selected: {model.caseType},
                onSelectionChanged: (Set<String> selection) {
                  model.setCaseType(selection.first);
                  model.addToHistory();
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter text to convert...',
                  border: OutlineInputBorder(),
                  suffixIcon: model.inputText.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => model.clearInput(),
                        )
                      : null,
                ),
                onChanged: (value) => model.setInputText(value),
                controller: TextEditingController(text: model.inputText),
              ),
              if (model.outputText.isNotEmpty) ...[
                SizedBox(height: 12),
                SelectableText(
                  model.outputText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
              if (model.history.isNotEmpty) ...[
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Clear History'),
                            content: Text('Clear all conversion history?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  model.clearHistory();
                                  Navigator.pop(ctx);
                                },
                                child: Text('Clear'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Clear history',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...model.history.reversed.map((entry) => ListTile(
                  dense: true,
                  title: Text(entry['output'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(entry['caseType'] ?? ''),
                  onTap: () {
                    final index = model.history.length - 1 - model.history.reversed.toList().indexOf(entry);
                    model.applyFromHistory(index);
                  },
                )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

MyProvider providerTextCase = MyProvider(
  name: "TextCase",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Text Case Converter",
        keywords: "textcase, case, uppercase, lowercase, title, sentence, camel, pascal, snake, kebab, constant, convert, text",
        action: () {
          Global.infoModel.addInfoWidget("TextCaseCard", TextCaseCard(), title: "Text Case Converter");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    textCaseModel.init();
    Global.infoModel.addInfoWidget("TextCaseCard", TextCaseCard(), title: "Text Case Converter");
  },
  update: () {
    textCaseModel.refresh();
  },
);