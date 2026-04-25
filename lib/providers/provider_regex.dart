import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

class RegexModel extends ChangeNotifier {
  String _pattern = '';
  String _testString = '';
  List<RegexMatch> _matches = [];
  bool _isValid = true;
  String _errorMessage = '';
  bool _caseSensitive = true;
  bool _multiline = false;
  bool _dotAll = false;
  List<RegexHistoryEntry> _history = [];
  bool _isInitialized = false;

  String get pattern => _pattern;
  String get testString => _testString;
  List<RegexMatch> get matches => _matches;
  bool get isValid => _isValid;
  String get errorMessage => _errorMessage;
  bool get caseSensitive => _caseSensitive;
  bool get multiline => _multiline;
  bool get dotAll => _dotAll;
  List<RegexHistoryEntry> get history => _history;
  bool get isInitialized => _isInitialized;
  int get matchCount => _matches.length;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    Global.loggerModel.info("RegexTester initialized", source: "RegexTester");
    notifyListeners();
  }

  void setPattern(String value) {
    _pattern = value;
    _findMatches();
  }

  void setTestString(String value) {
    _testString = value;
    _findMatches();
  }

  void toggleCaseSensitive() {
    _caseSensitive = !_caseSensitive;
    _findMatches();
  }

  void toggleMultiline() {
    _multiline = !_multiline;
    _findMatches();
  }

  void toggleDotAll() {
    _dotAll = !_dotAll;
    _findMatches();
  }

  void _findMatches() {
    _matches.clear();
    _errorMessage = '';
    
    if (_pattern.isEmpty || _testString.isEmpty) {
      _isValid = true;
      notifyListeners();
      return;
    }

    try {
      final regex = RegExp(
        _pattern,
        caseSensitive: _caseSensitive,
        multiLine: _multiline,
        dotAll: _dotAll,
      );
      _isValid = true;
      
      final allMatches = regex.allMatches(_testString);
      for (final match in allMatches) {
        final groups = <String?>[];
        for (int i = 1; i <= match.groupCount; i++) {
          groups.add(match.group(i));
        }
        _matches.add(RegexMatch(
          start: match.start,
          end: match.end,
          matched: match.group(0) ?? '',
          groups: groups,
        ));
      }
      Global.loggerModel.info("Found ${_matches.length} matches", source: "RegexTester");
    } catch (e) {
      _isValid = false;
      _errorMessage = e.toString();
      Global.loggerModel.warning("Invalid regex: $e", source: "RegexTester");
    }
    notifyListeners();
  }

  void addToHistory() {
    if (_pattern.isEmpty) return;
    
    _history.add(RegexHistoryEntry(
      pattern: _pattern,
      testString: _testString,
      matchCount: _matches.length,
      timestamp: DateTime.now(),
    ));
    
    if (_history.length > 10) {
      _history.removeAt(0);
    }
    Global.loggerModel.info("Added to history: $_pattern", source: "RegexTester");
    notifyListeners();
  }

  void loadFromHistory(int index) {
    if (index < 0 || index >= _history.length) return;
    final entry = _history[index];
    _pattern = entry.pattern;
    _testString = entry.testString;
    _findMatches();
    Global.loggerModel.info("Loaded from history: index $index", source: "RegexTester");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "RegexTester");
    notifyListeners();
  }

  void clearPattern() {
    _pattern = '';
    _matches.clear();
    _errorMessage = '';
    _isValid = true;
    notifyListeners();
  }

  void clearTestString() {
    _testString = '';
    _matches.clear();
    notifyListeners();
  }

  void clearAll() {
    _pattern = '';
    _testString = '';
    _matches.clear();
    _errorMessage = '';
    _isValid = true;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class RegexMatch {
  final int start;
  final int end;
  final String matched;
  final List<String?> groups;

  RegexMatch({
    required this.start,
    required this.end,
    required this.matched,
    required this.groups,
  });
}

class RegexHistoryEntry {
  final String pattern;
  final String testString;
  final int matchCount;
  final DateTime timestamp;

  RegexHistoryEntry({
    required this.pattern,
    required this.testString,
    required this.matchCount,
    required this.timestamp,
  });
}

final RegexModel regexModel = RegexModel();

MyProvider providerRegexTester = MyProvider(
  name: "RegexTester",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Regex Tester",
        keywords: "regex regular expression test match pattern",
        action: () {
          Global.infoModel.addInfoWidget("RegexTester", RegexTesterCard(), title: "Regex Tester");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    Global.infoModel.addInfoWidget("RegexTester", RegexTesterCard(), title: "Regex Tester");
  },
  update: () {},
);

class RegexTesterCard extends StatefulWidget {
  @override
  State<RegexTesterCard> createState() => _RegexTesterCardState();
}

class _RegexTesterCardState extends State<RegexTesterCard> {
  @override
  void initState() {
    super.initState();
    regexModel.init();
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
                Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  "Regex Tester",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildOptionsRow(context),
            SizedBox(height: 8),
            _buildPatternField(context),
            SizedBox(height: 8),
            _buildTestStringField(context),
            if (regexModel.errorMessage.isNotEmpty) SizedBox(height: 8),
            if (regexModel.errorMessage.isNotEmpty) _buildErrorDisplay(context),
            if (regexModel.isValid && regexModel.matches.isNotEmpty) SizedBox(height: 8),
            if (regexModel.isValid && regexModel.matches.isNotEmpty) _buildMatchesInfo(context),
            if (regexModel.isValid && regexModel.testString.isNotEmpty) SizedBox(height: 8),
            if (regexModel.isValid && regexModel.testString.isNotEmpty) _buildHighlightedOutput(context),
            SizedBox(height: 8),
            _buildButtons(context),
            if (regexModel.history.isNotEmpty) SizedBox(height: 12),
            if (regexModel.history.isNotEmpty) _buildHistorySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: Text("Case Sensitive"),
          selected: regexModel.caseSensitive,
          onSelected: (value) {
            regexModel.toggleCaseSensitive();
            setState(() {});
          },
        ),
        FilterChip(
          label: Text("Multiline"),
          selected: regexModel.multiline,
          onSelected: (value) {
            regexModel.toggleMultiline();
            setState(() {});
          },
        ),
        FilterChip(
          label: Text("Dot All"),
          selected: regexModel.dotAll,
          onSelected: (value) {
            regexModel.toggleDotAll();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildPatternField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: "Regex Pattern",
        hintText: "Enter regular expression pattern",
        border: OutlineInputBorder(),
        errorText: regexModel.isValid ? null : "Invalid pattern",
        suffixIcon: regexModel.pattern.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  regexModel.clearPattern();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        regexModel.setPattern(value);
        setState(() {});
      },
    );
  }

  Widget _buildTestStringField(BuildContext context) {
    return TextField(
      maxLines: 5,
      decoration: InputDecoration(
        labelText: "Test String",
        hintText: "Enter text to test against",
        border: OutlineInputBorder(),
        suffixIcon: regexModel.testString.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  regexModel.clearTestString();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        regexModel.setTestString(value);
        setState(() {});
      },
    );
  }

  Widget _buildErrorDisplay(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        regexModel.errorMessage,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMatchesInfo(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 16),
        SizedBox(width: 4),
        Text(
          "${regexModel.matchCount} matches found",
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedOutput(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: _buildRichText(context),
      ),
    );
  }

  Widget _buildRichText(BuildContext context) {
    final textSpans = <TextSpan>[];
    final testString = regexModel.testString;
    final matches = regexModel.matches;
    
    if (matches.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: SelectableText(
          testString,
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    int lastEnd = 0;
    final highlightColor = Theme.of(context).colorScheme.primaryContainer;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final highlightTextColor = Theme.of(context).colorScheme.onPrimaryContainer;

    for (final match in matches) {
      if (match.start > lastEnd) {
        textSpans.add(TextSpan(
          text: testString.substring(lastEnd, match.start),
          style: TextStyle(color: textColor, fontSize: 14),
        ));
      }
      
      textSpans.add(TextSpan(
        text: match.matched,
        style: TextStyle(
          color: highlightTextColor,
          backgroundColor: highlightColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastEnd = match.end;
    }

    if (lastEnd < testString.length) {
      textSpans.add(TextSpan(
        text: testString.substring(lastEnd),
        style: TextStyle(color: textColor, fontSize: 14),
      ));
    }

    return Padding(
      padding: EdgeInsets.all(8),
      child: RichText(
        text: TextSpan(children: textSpans),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text("Save"),
          onPressed: regexModel.pattern.isNotEmpty
              ? () {
                  regexModel.addToHistory();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Saved to history")),
                  );
                }
              : null,
        ),
        SizedBox(width: 8),
        TextButton.icon(
          icon: Icon(Icons.clear_all),
          label: Text("Clear All"),
          onPressed: () {
            regexModel.clearAll();
            setState(() {});
          },
        ),
        if (regexModel.history.isNotEmpty) SizedBox(width: 8),
        if (regexModel.history.isNotEmpty)
          TextButton.icon(
            icon: Icon(Icons.delete),
            label: Text("Clear History"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Clear History"),
                  content: Text("Clear all ${regexModel.history.length} saved entries?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        regexModel.clearHistory();
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
          "History (${regexModel.history.length})",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: regexModel.history.asMap().entries.map((entry) {
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
              label: Text("$timeStr (${item.matchCount} matches)"),
              onPressed: () {
                regexModel.loadFromHistory(index);
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}