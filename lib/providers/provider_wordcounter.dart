import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/logger.dart';
import 'package:provider/provider.dart';

class WordCounterModel extends ChangeNotifier {
  String _inputText = '';
  int _charCount = 0;
  int _charCountNoSpaces = 0;
  int _wordCount = 0;
  int _lineCount = 0;
  int _sentenceCount = 0;
  int _paragraphCount = 0;
  bool _isInitialized = false;

  String get inputText => _inputText;
  int get charCount => _charCount;
  int get charCountNoSpaces => _charCountNoSpaces;
  int get wordCount => _wordCount;
  int get lineCount => _lineCount;
  int get sentenceCount => _sentenceCount;
  int get paragraphCount => _paragraphCount;
  bool get isInitialized => _isInitialized;

  void init() {
    Global.loggerModel.info("WordCounter initialized", source: "WordCounter");
    _isInitialized = true;
    notifyListeners();
  }

  void setInputText(String value) {
    _inputText = value;
    _count();
    notifyListeners();
  }

  void _count() {
    _charCount = _inputText.length;
    _charCountNoSpaces = _inputText.replaceAll(RegExp(r'\s'), '').length;
    
    _wordCount = _inputText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    
    _lineCount = _inputText.isEmpty ? 0 : _inputText.split('\n').length;
    
    _sentenceCount = _inputText
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .length;
    
    _paragraphCount = _inputText
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .length;
  }

  void clearInput() {
    _inputText = '';
    _charCount = 0;
    _charCountNoSpaces = 0;
    _wordCount = 0;
    _lineCount = 0;
    _sentenceCount = 0;
    _paragraphCount = 0;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

WordCounterModel wordCounterModel = WordCounterModel();

class WordCounterCard extends StatelessWidget {
  const WordCounterCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WordCounterModel>();
    
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
                Icon(Icons.format_size, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Word Counter', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter text to count...',
                  border: OutlineInputBorder(),
                  suffixIcon: model.inputText.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => model.clearInput(),
                        )
                      : null,
                ),
                onChanged: (value) => model.setInputText(value),
                maxLines: 5,
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountChip(label: 'Characters', value: model.charCount, icon: Icons.text_fields),
                  _CountChip(label: 'Chars (no spaces)', value: model.charCountNoSpaces, icon: Icons.space_bar),
                  _CountChip(label: 'Words', value: model.wordCount, icon: Icons.short_text),
                  _CountChip(label: 'Lines', value: model.lineCount, icon: Icons.view_headline),
                  _CountChip(label: 'Sentences', value: model.sentenceCount, icon: Icons.format_quote),
                  _CountChip(label: 'Paragraphs', value: model.paragraphCount, icon: Icons.article),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _CountChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

MyProvider providerWordCounter = MyProvider(
  name: "WordCounter",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Word Counter",
        keywords: "wordcounter, word, count, character, char, line, sentence, paragraph, text, letter",
        action: () {
          Global.infoModel.addInfoWidget("WordCounterCard", WordCounterCard(), title: "Word Counter");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    wordCounterModel.init();
    Global.infoModel.addInfoWidget("WordCounterCard", WordCounterCard(), title: "Word Counter");
  },
  update: () {
    wordCounterModel.refresh();
  },
);