import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/logger.dart';
import 'package:provider/provider.dart';

class LoremIpsumModel extends ChangeNotifier {
  String _generatedText = '';
  int _wordCount = 50;
  int _paragraphCount = 1;
  bool _startWithClassic = true;
  bool _isInitialized = false;
  final List<String> _history = [];

  static const String _classicStart = "Lorem ipsum dolor sit amet, consectetur adipiscing elit";
  static const List<String> _loremWords = [
    "lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
    "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore",
    "magna", "aliqua", "enim", "ad", "minim", "veniam", "quis", "nostrud",
    "exercitation", "ullamco", "laboris", "nisi", "aliquip", "ex", "ea", "commodo",
    "consequat", "duis", "aute", "irure", "in", "reprehenderit", "voluptate",
    "velit", "esse", "cillum", "fugiat", "nulla", "pariatur", "excepteur", "sint",
    "occaecat", "cupidatat", "non", "proident", "sunt", "culpa", "qui", "officia",
    "deserunt", "mollit", "anim", "id", "est", "laborum", "perspiciatis", "unde",
    "omnis", "iste", "natus", "error", "voluptatem", "accusantium", "doloremque",
    "laudantium", "totam", "rem", "aperiam", "eaque", "ipsa", "quae", "ab", "illo",
    "inventore", "veritatis", "quasi", "architecto", "beatae", "vitae", "dicta",
    "explicabo", "emo", "ipsam", "quia", "voluptas", "aspernatur", "aut", "odit",
    "fugit", "consequuntur", "magni", "dolores", "eos", "ratione", "sequi",
    "nesciunt", "neque", "porro", "quisquam", "dolorem", "ipsum", "quia",
    "dolor", "amet", "consectetur", "adipisci", "velit", "quam", "numquam",
    "eius", "modi", "tempora", "magnam", "quaerat", "laboriosam",
  ];

  String get generatedText => _generatedText;
  int get wordCount => _wordCount;
  int get paragraphCount => _paragraphCount;
  bool get startWithClassic => _startWithClassic;
  bool get isInitialized => _isInitialized;
  List<String> get history => List.unmodifiable(_history);

  void init() {
    Global.loggerModel.info("LoremIpsum initialized", source: "LoremIpsum");
    _isInitialized = true;
    generate();
    notifyListeners();
  }

  void setWordCount(int value) {
    _wordCount = value.clamp(10, 500);
    notifyListeners();
  }

  void setParagraphCount(int value) {
    _paragraphCount = value.clamp(1, 10);
    notifyListeners();
  }

  void setStartWithClassic(bool value) {
    _startWithClassic = value;
    notifyListeners();
  }

  void generate() {
    final paragraphs = <String>[];
    
    for (int p = 0; p < _paragraphCount; p++) {
      final words = <String>[];
      
      if (p == 0 && _startWithClassic) {
        words.addAll(_classicStart.split(' '));
      }
      
      int wordsNeeded = p == 0 && _startWithClassic 
          ? _wordCount - words.length 
          : _wordCount;
      
      for (int i = 0; i < wordsNeeded; i++) {
        final wordIndex = (words.length + i) % _loremWords.length;
        words.add(_loremWords[wordIndex]);
      }
      
      String paragraph = words.join(' ');
      paragraph = _capitalizeFirst(paragraph);
      paragraph = _addPunctuation(paragraph);
      paragraphs.add(paragraph);
    }
    
    _generatedText = paragraphs.join('\n\n');
    notifyListeners();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _addPunctuation(String text) {
    if (text.isEmpty) return text;
    final words = text.split(' ');
    final punctuatedWords = <String>[];
    
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      
      if (i == words.length - 1) {
        word = word + '.';
      } else if ((i + 1) % 8 == 0 && (i + 1) < words.length - 1) {
        word = word + '.';
      } else if ((i + 1) % 15 == 0 && (i + 1) < words.length - 1) {
        word = word + ',';
      }
      
      punctuatedWords.add(word);
    }
    
    return punctuatedWords.join(' ');
  }

  void addToHistory() {
    if (_generatedText.isEmpty) return;
    if (_history.length >= 10) {
      _history.removeAt(0);
    }
    _history.add(_generatedText);
    notifyListeners();
  }

  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

LoremIpsumModel loremIpsumModel = LoremIpsumModel();

class LoremIpsumCard extends StatelessWidget {
  const LoremIpsumCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LoremIpsumModel>();
    
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
                Text('Lorem Ipsum Generator', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Words: ${model.wordCount}', style: TextStyle(fontSize: 12)),
                        Slider(
                          value: model.wordCount.toDouble(),
                          min: 10,
                          max: 500,
                          divisions: 49,
                          onChanged: (value) => model.setWordCount(value.round()),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paragraphs: ${model.paragraphCount}', style: TextStyle(fontSize: 12)),
                        Slider(
                          value: model.paragraphCount.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged: (value) => model.setParagraphCount(value.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  FilterChip(
                    label: Text('Start with classic'),
                    selected: model.startWithClassic,
                    onSelected: (selected) => model.setStartWithClassic(selected),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Generate'),
                    onPressed: () => model.generate(),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SelectableText(
                model.generatedText,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.copy),
                    label: Text('Copy'),
                    onPressed: model.generatedText.isNotEmpty
                        ? () {
                          model.addToHistory();
                        }
                        : null,
                  ),
                  SizedBox(width: 8),
                  if (model.history.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.history),
                      label: Text('History (${model.history.length})'),
                      onPressed: () => _showHistory(context, model),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, LoremIpsumModel model) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<LoremIpsumModel>(
          builder: (context, model, child) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      IconButton(
                        icon: Icon(Icons.delete_sweep),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Clear History'),
                              content: Text('Are you sure you want to clear all history?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    model.clearHistory();
                                    Navigator.pop(context);
                                  },
                                  child: Text('Clear'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: model.history.length,
                      itemBuilder: (context, index) {
                        return Card.outlined(
                          child: ListTile(
                            title: Text(
                              model.history[index].substring(0, 
                                model.history[index].length > 100 
                                    ? 100 
                                    : model.history[index].length) + '...',
                            ),
                            onTap: () {
                              Navigator.pop(context);
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => model.removeFromHistory(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

MyProvider providerLoremIpsum = MyProvider(
  name: "LoremIpsum",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Lorem Ipsum",
        keywords: "loremipsum, lorem, ipsum, placeholder, text, generate, dummy, sample",
        action: () {
          Global.infoModel.addInfoWidget("LoremIpsumCard", LoremIpsumCard(), title: "Lorem Ipsum Generator");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    loremIpsumModel.init();
    Global.infoModel.addInfoWidget("LoremIpsumCard", LoremIpsumCard(), title: "Lorem Ipsum Generator");
  },
  update: () {
    loremIpsumModel.refresh();
  },
);