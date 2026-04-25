import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownPreviewModel extends ChangeNotifier {
  String _inputText = '';
  bool _isInitialized = false;
  List<MarkdownHistoryEntry> _history = [];
  int _maxHistoryLength = 10;

  String get inputText => _inputText;
  bool get isInitialized => _isInitialized;
  List<MarkdownHistoryEntry> get history => _history;

  void init() {
    Global.loggerModel.info("MarkdownPreview initialized", source: "MarkdownPreview");
    _isInitialized = true;
    notifyListeners();
  }

  void setInputText(String value) {
    _inputText = value;
    notifyListeners();
  }

  void addToHistory() {
    if (_inputText.trim().isEmpty) return;
    
    _history.insert(0, MarkdownHistoryEntry(
      text: _inputText,
      timestamp: DateTime.now(),
    ));
    
    if (_history.length > _maxHistoryLength) {
      _history.removeLast();
    }
    
    Global.loggerModel.info("Markdown added to history", source: "MarkdownPreview");
    notifyListeners();
  }

  void loadFromHistory(MarkdownHistoryEntry entry) {
    _inputText = entry.text;
    notifyListeners();
  }

  void clearInput() {
    _inputText = '';
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("Markdown history cleared", source: "MarkdownPreview");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class MarkdownHistoryEntry {
  final String text;
  final DateTime timestamp;

  MarkdownHistoryEntry({
    required this.text,
    required this.timestamp,
  });

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

MarkdownPreviewModel markdownPreviewModel = MarkdownPreviewModel();

class MarkdownPreviewCard extends StatelessWidget {
  const MarkdownPreviewCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MarkdownPreviewModel>();
    
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
                Icon(Icons.article, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Markdown Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                if (model.history.isNotEmpty)
                  TextButton(
                    onPressed: () => _showClearHistoryDialog(context),
                    child: Text('Clear History'),
                  ),
              ],
            ),
            SizedBox(height: 12),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter markdown text...',
                        border: OutlineInputBorder(),
                        suffixIcon: model.inputText.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () => model.clearInput(),
                              )
                            : null,
                      ),
                      onChanged: (value) => model.setInputText(value),
                      maxLines: 6,
                    ),
                  ),
                  if (model.inputText.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: IconButton(
                        icon: Icon(Icons.save),
                        tooltip: 'Save to history',
                        onPressed: () => model.addToHistory(),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              if (model.inputText.isNotEmpty) ...[
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Markdown(
                    data: model.inputText,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      h2: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      h3: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      p: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                      code: TextStyle(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      blockquote: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      blockquoteDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text('Preview', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
              if (model.history.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: model.history.length,
                    itemBuilder: (context, index) {
                      final entry = model.history[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          entry.text.split('\n').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(entry.formattedTime),
                        onTap: () => model.loadFromHistory(entry),
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

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear History'),
        content: Text('Are you sure you want to clear all markdown history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              markdownPreviewModel.clearHistory();
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}

MyProvider providerMarkdownPreview = MyProvider(
  name: "MarkdownPreview",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Markdown Preview",
        keywords: "markdown, preview, md, text, format, render, document",
        action: () {
          Global.infoModel.addInfoWidget("MarkdownPreviewCard", MarkdownPreviewCard(), title: "Markdown Preview");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    markdownPreviewModel.init();
    Global.infoModel.addInfoWidget("MarkdownPreviewCard", MarkdownPreviewCard(), title: "Markdown Preview");
  },
  update: () {
    markdownPreviewModel.refresh();
  },
);