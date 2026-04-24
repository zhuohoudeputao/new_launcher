import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class PalindromeModel extends ChangeNotifier {
  String _inputText = '';
  bool _isPalindrome = false;
  String _reversedText = '';
  bool _ignoreSpaces = true;
  bool _ignorePunctuation = true;
  bool _ignoreCase = true;
  bool _isInitialized = false;
  List<Map<String, dynamic>> _history = [];
  static const int _maxHistoryLength = 10;

  String get inputText => _inputText;
  bool get isPalindrome => _isPalindrome;
  String get reversedText => _reversedText;
  bool get ignoreSpaces => _ignoreSpaces;
  bool get ignorePunctuation => _ignorePunctuation;
  bool get ignoreCase => _ignoreCase;
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get history => _history;

  void init() {
    Global.loggerModel.info("Palindrome initialized", source: "Palindrome");
    _isInitialized = true;
    notifyListeners();
  }

  void setInputText(String value) {
    _inputText = value;
    _checkPalindrome();
    notifyListeners();
  }

  void setIgnoreSpaces(bool value) {
    _ignoreSpaces = value;
    _checkPalindrome();
    notifyListeners();
  }

  void setIgnorePunctuation(bool value) {
    _ignorePunctuation = value;
    _checkPalindrome();
    notifyListeners();
  }

  void setIgnoreCase(bool value) {
    _ignoreCase = value;
    _checkPalindrome();
    notifyListeners();
  }

  String _normalizeText(String text) {
    String normalized = text;
    
    if (_ignoreCase) {
      normalized = normalized.toLowerCase();
    }
    
    if (_ignoreSpaces) {
      normalized = normalized.replaceAll(' ', '');
    }
    
    if (_ignorePunctuation) {
      normalized = normalized.replaceAll(RegExp(r'[^\w\s]'), '');
    }
    
    return normalized;
  }

  void _checkPalindrome() {
    if (_inputText.isEmpty) {
      _isPalindrome = false;
      _reversedText = '';
      return;
    }
    
    String normalized = _normalizeText(_inputText);
    _reversedText = normalized.split('').reversed.join('');
    _isPalindrome = normalized == _reversedText;
  }

  void addToHistory() {
    if (_inputText.isEmpty) return;
    
    final entry = {
      'text': _inputText,
      'isPalindrome': _isPalindrome,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _history.insert(0, entry);
    
    if (_history.length > _maxHistoryLength) {
      _history.removeLast();
    }
    
    Global.settingsModel.saveValue('PalindromeHistory', 
      _history.map((e) => jsonEncode(e)).toList());
    
    notifyListeners();
  }

  void loadFromHistory(Map<String, dynamic> entry) {
    _inputText = entry['text'] as String;
    _checkPalindrome();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    final saved = await Global.getValue('PalindromeHistory', <String>[]);
    if (saved is List<String>) {
      _history = saved.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    }
    notifyListeners();
  }

  void clearInput() {
    _inputText = '';
    _isPalindrome = false;
    _reversedText = '';
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    Global.settingsModel.saveValue('PalindromeHistory', <String>[]);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

PalindromeModel palindromeModel = PalindromeModel();

class PalindromeCard extends StatelessWidget {
  const PalindromeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PalindromeModel>();
    
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
                Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Palindrome Checker', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter text to check...',
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('Ignore spaces'),
                    selected: model.ignoreSpaces,
                    onSelected: (value) => model.setIgnoreSpaces(value),
                  ),
                  FilterChip(
                    label: Text('Ignore punctuation'),
                    selected: model.ignorePunctuation,
                    onSelected: (value) => model.setIgnorePunctuation(value),
                  ),
                  FilterChip(
                    label: Text('Ignore case'),
                    selected: model.ignoreCase,
                    onSelected: (value) => model.setIgnoreCase(value),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (model.inputText.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: model.isPalindrome 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        model.isPalindrome ? Icons.check_circle : Icons.cancel,
                        color: model.isPalindrome 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        model.isPalindrome ? 'Yes, it\'s a palindrome!' : 'Not a palindrome',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: model.isPalindrome 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text('Reversed: ${model.reversedText}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Save to History'),
                    onPressed: model.inputText.isNotEmpty ? () => model.addToHistory() : null,
                  ),
                  if (model.history.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.history),
                      label: Text('History (${model.history.length})'),
                      onPressed: () => _showHistoryDialog(context, model),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, PalindromeModel model) {
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
                leading: Icon(
                  entry['isPalindrome'] as bool ? Icons.check_circle : Icons.cancel,
                  color: entry['isPalindrome'] as bool 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                title: Text(entry['text'] as String),
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

MyProvider providerPalindrome = MyProvider(
  name: "Palindrome",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Palindrome Checker",
        keywords: "palindrome, check, text, reverse, word, phrase, mirror, backwards",
        action: () {
          Global.infoModel.addInfoWidget("PalindromeCard", PalindromeCard(), title: "Palindrome Checker");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    palindromeModel.init();
    palindromeModel.loadHistory();
    Global.infoModel.addInfoWidget("PalindromeCard", PalindromeCard(), title: "Palindrome Checker");
  },
  update: () {
    palindromeModel.refresh();
  },
);