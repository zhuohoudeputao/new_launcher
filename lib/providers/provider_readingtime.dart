import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

ReadingTimeModel readingTimeModel = ReadingTimeModel();
MyProvider providerReadingTime = MyProvider(
  name: "ReadingTime",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "ReadingTime",
        keywords: "reading, time, read, words, estimate, wpm, minutes, count, text, article, blog, content",
        action: () {
          Global.infoModel.addInfoWidget("ReadingTime", ReadingTimeCard(), title: "Reading Time Estimator");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    readingTimeModel.init();
    Global.infoModel.addInfoWidget("ReadingTime", ReadingTimeCard(), title: "Reading Time Estimator");
  },
  update: () {},
);

class ReadingTimeModel extends ChangeNotifier {
  String _text = "";
  int _wordsPerMinute = 250;
  bool _initialized = false;
  List<ReadingTimeHistoryEntry> _history = [];

  String get text => _text;
  int get wordsPerMinute => _wordsPerMinute;
  bool get initialized => _initialized;
  List<ReadingTimeHistoryEntry> get history => _history;

  int get wordCount {
    if (_text.isEmpty) return 0;
    return _text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  int get characterCount => _text.length;
  int get characterCountNoSpaces => _text.replaceAll(RegExp(r'\s'), '').length;

  int get sentenceCount {
    if (_text.isEmpty) return 0;
    return _text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
  }

  int get paragraphCount {
    if (_text.isEmpty) return 0;
    return _text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;
  }

  double get readingTimeMinutes {
    if (wordCount == 0) return 0;
    return wordCount / _wordsPerMinute;
  }

  int get readingTimeSeconds {
    return (readingTimeMinutes * 60).round();
  }

  String get formattedReadingTime {
    if (readingTimeMinutes < 1) {
      return "${readingTimeSeconds}s";
    }
    int minutes = readingTimeMinutes.floor();
    int seconds = ((readingTimeMinutes - minutes) * 60).round();
    if (seconds > 0) {
      return "${minutes}m ${seconds}s";
    }
    return "${minutes}m";
  }

  String get speakingTime {
    int speakingWpm = 150;
    double speakingMinutes = wordCount / speakingWpm;
    if (speakingMinutes < 1) {
      return "${(speakingMinutes * 60).round()}s";
    }
    int minutes = speakingMinutes.floor();
    int seconds = ((speakingMinutes - minutes) * 60).round();
    if (seconds > 0) {
      return "${minutes}m ${seconds}s";
    }
    return "${minutes}m";
  }

  void init() {
    _initialized = true;
    notifyListeners();
  }

  void setText(String value) {
    _text = value;
    notifyListeners();
  }

  void setWordsPerMinute(int value) {
    _wordsPerMinute = value.clamp(50, 500);
    notifyListeners();
  }

  void addToHistory() {
    if (_text.isEmpty) return;
    
    final entry = ReadingTimeHistoryEntry(
      textPreview: _text.length > 100 ? "${_text.substring(0, 100)}..." : _text,
      wordCount: wordCount,
      readingTime: formattedReadingTime,
      wpm: _wordsPerMinute,
      timestamp: DateTime.now(),
    );
    
    _history.insert(0, entry);
    if (_history.length > 10) {
      _history.removeLast();
    }
    
    Global.loggerModel.info("Added reading time analysis to history", source: "ReadingTime");
    notifyListeners();
  }

  void useHistoryEntry(ReadingTimeHistoryEntry entry) {
    _text = entry.textPreview.endsWith("...") 
        ? entry.textPreview.substring(0, entry.textPreview.length - 3)
        : entry.textPreview;
    _wordsPerMinute = entry.wpm;
    Global.loggerModel.info("Using history entry", source: "ReadingTime");
    notifyListeners();
  }

  void clearText() {
    _text = "";
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Reading time history cleared", source: "ReadingTime");
    notifyListeners();
  }
}

class ReadingTimeHistoryEntry {
  final String textPreview;
  final int wordCount;
  final String readingTime;
  final int wpm;
  final DateTime timestamp;

  ReadingTimeHistoryEntry({
    required this.textPreview,
    required this.wordCount,
    required this.readingTime,
    required this.wpm,
    required this.timestamp,
  });

  String getFormattedTime() {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

class ReadingTimeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Reading Time Estimator',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Consumer<ReadingTimeModel>(
              builder: (context, model, child) {
                if (!model.initialized) {
                  return Center(child: CircularProgressIndicator());
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter text to analyze...',
                        border: OutlineInputBorder(),
                        suffixIcon: model.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: model.clearText,
                              )
                            : null,
                      ),
                      onChanged: model.setText,
                    ),
                    SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Text('WPM: ${model.wordsPerMinute}', style: Theme.of(context).textTheme.bodyMedium),
                        SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: model.wordsPerMinute.toDouble(),
                            min: 50,
                            max: 500,
                            divisions: 45,
                            label: model.wordsPerMinute.toString(),
                            onChanged: (value) => model.setWordsPerMinute(value.round()),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(Icons.schedule, size: 16),
                          label: Text('Read: ${model.formattedReadingTime}'),
                        ),
                        Chip(
                          avatar: Icon(Icons.record_voice_over, size: 16),
                          label: Text('Speak: ${model.speakingTime}'),
                        ),
                        Chip(
                          avatar: Icon(Icons.text_fields, size: 16),
                          label: Text('${model.wordCount} words'),
                        ),
                        Chip(
                          avatar: Icon(Icons.short_text, size: 16),
                          label: Text('${model.characterCount} chars'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sentences: ${model.sentenceCount} | Paragraphs: ${model.paragraphCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (model.text.isNotEmpty)
                          TextButton.icon(
                            icon: Icon(Icons.save),
                            label: Text('Save to History'),
                            onPressed: model.addToHistory,
                          ),
                      ],
                    ),
                    
                    if (model.history.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('History (${model.history.length})', style: Theme.of(context).textTheme.titleSmall),
                          TextButton(
                            child: Text('Clear'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Clear History'),
                                  content: Text('Clear all reading time history?'),
                                  actions: [
                                    TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
                                    TextButton(
                                      child: Text('Clear'),
                                      onPressed: () {
                                        model.clearHistory();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...model.history.take(5).map((entry) => ListTile(
                        dense: true,
                        leading: Icon(Icons.history, size: 20),
                        title: Text(
                          entry.textPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${entry.wordCount} words - ${entry.readingTime} @ ${entry.wpm} WPM - ${entry.getFormattedTime()}'),
                        onTap: () => model.useHistoryEntry(entry),
                      )),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}