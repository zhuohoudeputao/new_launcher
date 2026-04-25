import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

DiffCheckerModel diffCheckerModel = DiffCheckerModel();

MyProvider providerDiffChecker = MyProvider(
    name: "DiffChecker",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Diff Checker',
      keywords: 'diff compare text difference checker compare lines',
      action: () => diffCheckerModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  diffCheckerModel.init();
  Global.infoModel.addInfoWidget(
      "DiffChecker",
      ChangeNotifierProvider.value(
          value: diffCheckerModel,
          builder: (context, child) => DiffCheckerCard()),
      title: "Diff Checker");
}

Future<void> _update() async {
  diffCheckerModel.refresh();
}

enum DiffType { addition, deletion, unchanged }

class DiffLine {
  final String text;
  final DiffType type;
  final int? originalLine;
  final int? modifiedLine;
  final List<DiffWord>? wordDiffs;

  DiffLine({
    required this.text,
    required this.type,
    this.originalLine,
    this.modifiedLine,
    this.wordDiffs,
  });
}

class DiffWord {
  final String text;
  final DiffType type;

  DiffWord({required this.text, required this.type});
}

class DiffHistory {
  final String original;
  final String modified;
  final int additions;
  final int deletions;
  final DateTime timestamp;

  DiffHistory({
    required this.original,
    required this.modified,
    required this.additions,
    required this.deletions,
    required this.timestamp,
  });

  String get summary {
    if (additions == 0 && deletions == 0) {
      return 'No changes';
    }
    return '+$additions -$deletions';
  }
}

class DiffCheckerModel extends ChangeNotifier {
  String _originalText = '';
  String _modifiedText = '';
  List<DiffLine> _diffLines = [];
  List<DiffHistory> _history = [];
  bool _isLoading = false;
  bool _showWordDiff = false;

  static const int maxHistoryLength = 10;

  String get originalText => _originalText;
  String get modifiedText => _modifiedText;
  List<DiffLine> get diffLines => _diffLines;
  List<DiffHistory> get history => _history;
  bool get isLoading => _isLoading;
  bool get showWordDiff => _showWordDiff;
  int get additions => _diffLines.where((d) => d.type == DiffType.addition).length;
  int get deletions => _diffLines.where((d) => d.type == DiffType.deletion).length;
  bool get hasChanges => additions > 0 || deletions > 0;

  void init() {
    _isLoading = true;
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  void setOriginalText(String text) {
    _originalText = text;
    _computeDiff();
    notifyListeners();
  }

  void setModifiedText(String text) {
    _modifiedText = text;
    _computeDiff();
    notifyListeners();
  }

  void toggleWordDiff() {
    _showWordDiff = !_showWordDiff;
    _computeDiff();
    notifyListeners();
  }

  void _computeDiff() {
    _diffLines.clear();

    List<String> originalLines = _originalText.split('\n');
    List<String> modifiedLines = _modifiedText.split('\n');

    int maxLines = originalLines.length > modifiedLines.length 
        ? originalLines.length : modifiedLines.length;

    for (int i = 0; i < maxLines; i++) {
      String? origLine = i < originalLines.length ? originalLines[i] : null;
      String? modLine = i < modifiedLines.length ? modifiedLines[i] : null;

      if (origLine == null && modLine != null) {
        _diffLines.add(DiffLine(
          text: modLine,
          type: DiffType.addition,
          modifiedLine: i + 1,
          wordDiffs: _showWordDiff 
            ? [DiffWord(text: modLine, type: DiffType.addition)] 
            : null,
        ));
      } else if (origLine != null && modLine == null) {
        _diffLines.add(DiffLine(
          text: origLine,
          type: DiffType.deletion,
          originalLine: i + 1,
          wordDiffs: _showWordDiff 
            ? [DiffWord(text: origLine, type: DiffType.deletion)] 
            : null,
        ));
      } else if (origLine != null && modLine != null) {
        if (origLine == modLine) {
          _diffLines.add(DiffLine(
            text: origLine,
            type: DiffType.unchanged,
            originalLine: i + 1,
            modifiedLine: i + 1,
          ));
        } else {
          List<DiffWord>? wordDiffs = null;
          if (_showWordDiff) {
            wordDiffs = _computeWordDiff(origLine, modLine);
          }
          _diffLines.add(DiffLine(
            text: modLine,
            type: DiffType.addition,
            originalLine: i + 1,
            modifiedLine: i + 1,
            wordDiffs: wordDiffs,
          ));
          if (!_showWordDiff || wordDiffs == null) {
            _diffLines.add(DiffLine(
              text: origLine,
              type: DiffType.deletion,
              originalLine: i + 1,
              modifiedLine: i + 1,
            ));
          }
        }
      }
    }
  }

  List<DiffWord> _computeWordDiff(String original, String modified) {
    List<DiffWord> result = [];
    List<String> origWords = original.split(RegExp(r'\s+'));
    List<String> modWords = modified.split(RegExp(r'\s+'));
    
    Set<String> origSet = Set.from(origWords);
    Set<String> modSet = Set.from(modWords);
    
    for (String word in modWords) {
      if (origSet.contains(word)) {
        result.add(DiffWord(text: word, type: DiffType.unchanged));
      } else {
        result.add(DiffWord(text: word, type: DiffType.addition));
      }
    }
    
    for (String word in origWords) {
      if (!modSet.contains(word)) {
        result.add(DiffWord(text: word, type: DiffType.deletion));
      }
    }
    
    return result;
  }

  void addToHistory() {
    if (_originalText.isEmpty && _modifiedText.isEmpty) return;

    DiffHistory entry = DiffHistory(
      original: _originalText,
      modified: _modifiedText,
      additions: additions,
      deletions: deletions,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void applyFromHistory(DiffHistory entry) {
    _originalText = entry.original;
    _modifiedText = entry.modified;
    _computeDiff();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void clearTexts() {
    _originalText = '';
    _modifiedText = '';
    _diffLines.clear();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class DiffCheckerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DiffCheckerModel>(
      builder: (context, model, child) {
        return Card.filled(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Diff Checker',
                        style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        FilterChip(
                          label: Text('Word Diff'),
                          selected: model.showWordDiff,
                          onSelected: (_) => model.toggleWordDiff(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInputFields(context, model),
                if (model.diffLines.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDiffView(context, model),
                  _buildStatsBar(context, model),
                ],
                if (model.hasChanges) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          model.addToHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to history'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        child: const Text('Save to History'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => model.clearTexts(),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
                if (model.history.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('History',
                          style: Theme.of(context).textTheme.titleSmall),
                      TextButton(
                        onPressed: () => _showClearConfirmationDialog(context, model),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...model.history.map((entry) => _buildHistoryItem(context, model, entry)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputFields(BuildContext context, DiffCheckerModel model) {
    return Column(
      children: [
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Original Text',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () => model.setOriginalText(''),
              tooltip: 'Clear original',
            ),
          ),
          controller: TextEditingController(text: model.originalText),
          onChanged: (text) => model.setOriginalText(text),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Modified Text',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () => model.setModifiedText(''),
              tooltip: 'Clear modified',
            ),
          ),
          controller: TextEditingController(text: model.modifiedText),
          onChanged: (text) => model.setModifiedText(text),
        ),
      ],
    );
  }

  Widget _buildDiffView(BuildContext context, DiffCheckerModel model) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: model.diffLines.length,
        itemBuilder: (context, index) {
          final diffLine = model.diffLines[index];
          return _buildDiffLine(context, diffLine);
        },
      ),
    );
  }

  Widget _buildDiffLine(BuildContext context, DiffLine diffLine) {
    Color bgColor;
    Color textColor;
    String prefix;

    switch (diffLine.type) {
      case DiffType.addition:
        bgColor = Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3);
        textColor = Theme.of(context).colorScheme.primary;
        prefix = '+ ';
        break;
      case DiffType.deletion:
        bgColor = Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3);
        textColor = Theme.of(context).colorScheme.error;
        prefix = '- ';
        break;
      case DiffType.unchanged:
        bgColor = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
        textColor = Theme.of(context).colorScheme.onSurface;
        prefix = '  ';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bgColor),
      child: diffLine.wordDiffs != null
        ? _buildWordDiffLine(context, prefix, diffLine.wordDiffs!)
        : Text(
          '$prefix${diffLine.text}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
        ),
    );
  }

  Widget _buildWordDiffLine(BuildContext context, String prefix, List<DiffWord> words) {
    List<InlineSpan> spans = [
      TextSpan(
        text: prefix,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];

    for (DiffWord word in words) {
      Color wordColor;
      switch (word.type) {
        case DiffType.addition:
          wordColor = Theme.of(context).colorScheme.primary;
          break;
        case DiffType.deletion:
          wordColor = Theme.of(context).colorScheme.error;
          break;
        case DiffType.unchanged:
          wordColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
          break;
      }
      spans.add(TextSpan(
        text: '${word.text} ',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: wordColor),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildStatsBar(BuildContext context, DiffCheckerModel model) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${model.additions}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${model.deletions}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, DiffCheckerModel model, DiffHistory entry) {
    return InkWell(
      onTap: () => model.applyFromHistory(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.summary,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatTimestamp(entry.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showClearConfirmationDialog(BuildContext context, DiffCheckerModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all diff history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              model.clearHistory();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}