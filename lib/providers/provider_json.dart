import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

class JsonModel extends ChangeNotifier {
  String _input = '';
  String _output = '';
  bool _isValid = false;
  String _errorMessage = '';
  int _indentSpaces = 2;
  List<JsonHistoryEntry> _history = [];
  bool _isInitialized = false;
  bool _showMinified = false;

  String get input => _input;
  String get output => _output;
  bool get isValid => _isValid;
  String get errorMessage => _errorMessage;
  int get indentSpaces => _indentSpaces;
  List<JsonHistoryEntry> get history => _history;
  bool get isInitialized => _isInitialized;
  bool get showMinified => _showMinified;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    notifyListeners();
  }

  void setInput(String value) {
    _input = value;
    _validateAndFormat();
  }

  void setIndentSpaces(int value) {
    _indentSpaces = value;
    _validateAndFormat();
  }

  void toggleMinified() {
    _showMinified = !_showMinified;
    _validateAndFormat();
  }

  void _validateAndFormat() {
    if (_input.isEmpty) {
      _output = '';
      _isValid = false;
      _errorMessage = '';
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(_input);
      _isValid = true;
      _errorMessage = '';
      
      if (_showMinified) {
        _output = jsonEncode(decoded);
      } else {
        final encoder = JsonEncoder.withIndent(' ' * _indentSpaces);
        _output = encoder.convert(decoded);
      }
    } catch (e) {
      _isValid = false;
      _errorMessage = e.toString();
      _output = '';
    }
    notifyListeners();
  }

  void addToHistory() {
    if (_input.isEmpty || !_isValid) return;
    
    _history.add(JsonHistoryEntry(
      input: _input,
      output: _output,
      timestamp: DateTime.now(),
    ));
    
    if (_history.length > 10) {
      _history.removeAt(0);
    }
    notifyListeners();
  }

  void loadFromHistory(int index) {
    if (index < 0 || index >= _history.length) return;
    final entry = _history[index];
    _input = entry.input;
    _validateAndFormat();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void clear() {
    _input = '';
    _output = '';
    _isValid = false;
    _errorMessage = '';
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class JsonHistoryEntry {
  final String input;
  final String output;
  final DateTime timestamp;

  JsonHistoryEntry({
    required this.input,
    required this.output,
    required this.timestamp,
  });
}

final JsonModel jsonModel = JsonModel();

MyProvider providerJsonFormatter = MyProvider(
  name: "JsonFormatter",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "JSON Formatter",
        keywords: "json format validate pretty minify indent parse",
        action: () {
          Global.infoModel.addInfoWidget("JsonFormatter", JsonFormatterCard(), title: "JSON Formatter");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    Global.infoModel.addInfoWidget("JsonFormatter", JsonFormatterCard(), title: "JSON Formatter");
  },
  update: () {},
);

class JsonFormatterCard extends StatefulWidget {
  @override
  State<JsonFormatterCard> createState() => _JsonFormatterCardState();
}

class _JsonFormatterCardState extends State<JsonFormatterCard> {
  @override
  void initState() {
    super.initState();
    jsonModel.init();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  "JSON Formatter",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildIndentSelector(context),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Minified:", style: TextStyle(fontSize: 12)),
                SizedBox(width: 8),
                Switch(
                  value: jsonModel.showMinified,
                  onChanged: (value) {
                    jsonModel.toggleMinified();
                    setState(() {});
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildInputField(context),
            SizedBox(height: 8),
            if (jsonModel.errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  jsonModel.errorMessage,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            if (jsonModel.isValid && jsonModel.output.isNotEmpty)
              SizedBox(height: 8),
            if (jsonModel.isValid && jsonModel.output.isNotEmpty)
              _buildOutputField(context),
            SizedBox(height: 8),
            _buildButtons(context),
            if (jsonModel.history.isNotEmpty) SizedBox(height: 12),
            if (jsonModel.history.isNotEmpty) _buildHistorySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIndentSelector(BuildContext context) {
    return Row(
      children: [
        Text("Indent: ", style: TextStyle(fontSize: 12)),
        SizedBox(width: 8),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 2, label: Text("2")),
            ButtonSegment(value: 4, label: Text("4")),
            ButtonSegment(value: 8, label: Text("8")),
          ],
          selected: {jsonModel.indentSpaces},
          onSelectionChanged: (Set<int> newSelection) {
            jsonModel.setIndentSpaces(newSelection.first);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context) {
    return TextField(
      maxLines: 5,
      decoration: InputDecoration(
        labelText: "Input JSON",
        border: OutlineInputBorder(),
        suffixIcon: jsonModel.input.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  jsonModel.clear();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        jsonModel.setInput(value);
        setState(() {});
      },
    );
  }

  Widget _buildOutputField(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          jsonModel.output,
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text("Save"),
          onPressed: jsonModel.isValid
              ? () {
                  jsonModel.addToHistory();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Saved to history")),
                  );
                }
              : null,
        ),
        SizedBox(width: 8),
        if (jsonModel.history.isNotEmpty)
          TextButton.icon(
            icon: Icon(Icons.delete),
            label: Text("Clear History"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Clear History"),
                  content: Text("Clear all ${jsonModel.history.length} saved entries?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        jsonModel.clearHistory();
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: Text("Clear"),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "History (${jsonModel.history.length})",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: jsonModel.history.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final timeDiff = DateTime.now().difference(item.timestamp);
            String timeStr;
            if (timeDiff.inMinutes < 1) {
              timeStr = "just now";
            } else if (timeDiff.inHours < 1) {
              timeStr = "${timeDiff.inMinutes}m ago";
            } else if (timeDiff.inDays < 1) {
              timeStr = "${timeDiff.inHours}h ago";
            } else {
              timeStr = "${timeDiff.inDays}d ago";
            }
            return ActionChip(
              label: Text(timeStr),
              onPressed: () {
                jsonModel.loadFromHistory(index);
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}