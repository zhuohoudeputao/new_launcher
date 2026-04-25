import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';

class CronModel extends ChangeNotifier {
  String _expression = '';
  String _description = '';
  bool _isValid = true;
  String _errorMessage = '';
  List<DateTime> _nextRuns = [];
  List<CronHistoryEntry> _history = [];
  bool _isInitialized = false;

  String get expression => _expression;
  String get description => _description;
  bool get isValid => _isValid;
  String get errorMessage => _errorMessage;
  List<DateTime> get nextRuns => _nextRuns;
  List<CronHistoryEntry> get history => _history;
  bool get isInitialized => _isInitialized;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    Global.loggerModel.info("CronExpressionParser initialized", source: "CronExpressionParser");
    notifyListeners();
  }

  void setExpression(String value) {
    _expression = value.trim();
    _parseExpression();
  }

  void _parseExpression() {
    _description = '';
    _errorMessage = '';
    _nextRuns.clear();

    if (_expression.isEmpty) {
      _isValid = true;
      notifyListeners();
      return;
    }

    final parts = _expression.split(' ');
    if (parts.length != 5) {
      _isValid = false;
      _errorMessage = 'Cron expression must have 5 fields (minute hour day month weekday)';
      Global.loggerModel.warning("Invalid cron: wrong number of fields", source: "CronExpressionParser");
      notifyListeners();
      return;
    }

    try {
      final minuteField = _parseField(parts[0], 0, 59, 'minute');
      final hourField = _parseField(parts[1], 0, 23, 'hour');
      final dayField = _parseField(parts[2], 1, 31, 'day');
      final monthField = _parseField(parts[3], 1, 12, 'month');
      final weekdayField = _parseField(parts[4], 0, 6, 'weekday');

      _description = _generateDescription(
        minuteField,
        hourField,
        dayField,
        monthField,
        weekdayField,
      );

      _nextRuns = _calculateNextRuns(
        minuteField,
        hourField,
        dayField,
        monthField,
        weekdayField,
      );

      _isValid = true;
      Global.loggerModel.info("Parsed cron expression successfully", source: "CronExpressionParser");
    } catch (e) {
      _isValid = false;
      _errorMessage = e.toString();
      Global.loggerModel.warning("Invalid cron: $e", source: "CronExpressionParser");
    }
    notifyListeners();
  }

  List<int> _parseField(String field, int min, int max, String name) {
    if (field == '*') {
      return List.generate(max - min + 1, (i) => min + i);
    }

    final values = <int>[];

    for (final part in field.split(',')) {
      if (part.contains('/')) {
        final stepParts = part.split('/');
        if (stepParts.length != 2) {
          throw Exception('Invalid step format in $name field');
        }

        String rangePart = stepParts[0];
        int step = int.parse(stepParts[1]);

        List<int> rangeValues;
        if (rangePart == '*') {
          rangeValues = List.generate(max - min + 1, (i) => min + i);
        } else if (rangePart.contains('-')) {
          final rangeParts = rangePart.split('-');
          final rangeStart = int.parse(rangeParts[0]);
          final rangeEnd = int.parse(rangeParts[1]);
          if (rangeStart < min || rangeEnd > max) {
            throw Exception('$name range out of bounds: $rangeStart-$rangeEnd');
          }
          rangeValues = List.generate(rangeEnd - rangeStart + 1, (i) => rangeStart + i);
        } else {
          final singleValue = int.parse(rangePart);
          if (singleValue < min || singleValue > max) {
            throw Exception('$name value out of bounds: $singleValue');
          }
          rangeValues = [singleValue];
        }

        for (int i = 0; i < rangeValues.length; i++) {
          if (i % step == 0) {
            values.add(rangeValues[i]);
          }
        }
      } else if (part.contains('-')) {
        final rangeParts = part.split('-');
        final rangeStart = int.parse(rangeParts[0]);
        final rangeEnd = int.parse(rangeParts[1]);
        if (rangeStart < min || rangeEnd > max) {
          throw Exception('$name range out of bounds: $rangeStart-$rangeEnd');
        }
        for (int i = rangeStart; i <= rangeEnd; i++) {
          values.add(i);
        }
      } else {
        final value = int.parse(part);
        if (value < min || value > max) {
          throw Exception('$name value out of bounds: $value');
        }
        values.add(value);
      }
    }

    values.sort();
    return values;
  }

  String _generateDescription(
    List<int> minutes,
    List<int> hours,
    List<int> days,
    List<int> months,
    List<int> weekdays,
  ) {
    final parts = <String>[];

    parts.add(_describeField(minutes, 0, 59, 'minute', 'every minute'));
    parts.add(_describeField(hours, 0, 23, 'hour', 'every hour'));
    parts.add(_describeField(days, 1, 31, 'day', 'every day'));
    parts.add(_describeFieldMonths(months));
    parts.add(_describeFieldWeekdays(weekdays));

    final allValues = minutes.length == 60 && hours.length == 24 && 
                       days.length == 31 && months.length == 12 && 
                       weekdays.length == 7;
    if (allValues) {
      return 'Every minute';
    }

    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  String _describeField(List<int> values, int min, int max, String name, String everyText) {
    if (values.length == max - min + 1) {
      return '';
    }

    if (values.length == 1) {
      return 'at ${name} ${values[0]}';
    }

    if (_isConsecutive(values)) {
      return '${name}s ${values.first}-${values.last}';
    }

    return '${name}s ${values.join(',')}';
  }

  String _describeFieldMonths(List<int> values) {
    if (values.length == 12) return '';

    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    if (values.length == 1) {
      return 'in ${monthNames[values[0]]}';
    }

    final names = values.map((v) => monthNames[v]).toList();
    return 'in ${names.join(',')}';
  }

  String _describeFieldWeekdays(List<int> values) {
    if (values.length == 7) return '';

    final weekdayNames = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];

    if (values.length == 1) {
      return 'on ${weekdayNames[values[0]]}';
    }

    final names = values.map((v) => weekdayNames[v]).toList();
    return 'on ${names.join(',')}';
  }

  bool _isConsecutive(List<int> values) {
    if (values.isEmpty) return false;
    for (int i = 1; i < values.length; i++) {
      if (values[i] != values[i - 1] + 1) return false;
    }
    return true;
  }

  List<DateTime> _calculateNextRuns(
    List<int> minutes,
    List<int> hours,
    List<int> days,
    List<int> months,
    List<int> weekdays,
  ) {
    final runs = <DateTime>[];
    final now = DateTime.now();
    DateTime current = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    int attempts = 0;
    const maxAttempts = 500000;
    const maxRuns = 5;

    while (runs.length < maxRuns && attempts < maxAttempts) {
      attempts++;
      current = current.add(Duration(minutes: 1));

      if (!minutes.contains(current.minute)) continue;
      if (!hours.contains(current.hour)) continue;
      if (!days.contains(current.day)) continue;
      if (!months.contains(current.month)) continue;
      if (!weekdays.contains(current.weekday % 7)) continue;

      runs.add(current);
    }

    return runs;
  }

  void addToHistory() {
    if (_expression.isEmpty || !_isValid) return;

    _history.add(CronHistoryEntry(
      expression: _expression,
      description: _description,
      timestamp: DateTime.now(),
    ));

    if (_history.length > 10) {
      _history.removeAt(0);
    }
    Global.loggerModel.info("Added to history: $_expression", source: "CronExpressionParser");
    notifyListeners();
  }

  void loadFromHistory(int index) {
    if (index < 0 || index >= _history.length) return;
    final entry = _history[index];
    _expression = entry.expression;
    _parseExpression();
    Global.loggerModel.info("Loaded from history: index $index", source: "CronExpressionParser");
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "CronExpressionParser");
    notifyListeners();
  }

  void clearExpression() {
    _expression = '';
    _description = '';
    _errorMessage = '';
    _nextRuns.clear();
    _isValid = true;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class CronHistoryEntry {
  final String expression;
  final String description;
  final DateTime timestamp;

  CronHistoryEntry({
    required this.expression,
    required this.description,
    required this.timestamp,
  });
}

final CronModel cronModel = CronModel();

MyProvider providerCronExpressionParser = MyProvider(
  name: "CronExpressionParser",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Cron Expression Parser",
        keywords: "cron expression schedule parser time crontab job",
        action: () {
          Global.infoModel.addInfoWidget("CronExpressionParser", CronExpressionParserCard(), title: "Cron Expression Parser");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    Global.infoModel.addInfoWidget("CronExpressionParser", CronExpressionParserCard(), title: "Cron Expression Parser");
  },
  update: () {},
);

class CronExpressionParserCard extends StatefulWidget {
  @override
  State<CronExpressionParserCard> createState() => _CronExpressionParserCardState();
}

class _CronExpressionParserCardState extends State<CronExpressionParserCard> {
  @override
  void initState() {
    super.initState();
    cronModel.init();
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
                Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  "Cron Expression Parser",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildExpressionField(context),
            if (cronModel.errorMessage.isNotEmpty) SizedBox(height: 8),
            if (cronModel.errorMessage.isNotEmpty) _buildErrorDisplay(context),
            if (cronModel.isValid && cronModel.description.isNotEmpty) SizedBox(height: 8),
            if (cronModel.isValid && cronModel.description.isNotEmpty) _buildDescription(context),
            if (cronModel.isValid && cronModel.nextRuns.isNotEmpty) SizedBox(height: 8),
            if (cronModel.isValid && cronModel.nextRuns.isNotEmpty) _buildNextRuns(context),
            SizedBox(height: 8),
            _buildButtons(context),
            if (cronModel.history.isNotEmpty) SizedBox(height: 12),
            if (cronModel.history.isNotEmpty) _buildHistorySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: "Cron Expression",
        hintText: "* * * * * (minute hour day month weekday)",
        border: OutlineInputBorder(),
        errorText: cronModel.isValid ? null : "Invalid expression",
        suffixIcon: cronModel.expression.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  cronModel.clearExpression();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (value) {
        cronModel.setExpression(value);
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
        cronModel.errorMessage,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Human-readable description:",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          SelectableText(
            cronModel.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextRuns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Next scheduled runs:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        ...cronModel.nextRuns.asMap().entries.map((entry) {
          final index = entry.key;
          final run = entry.value;
          final timeStr = _formatDateTime(run);
          final relativeTime = _formatRelativeTime(run);

          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        relativeTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return "${weekdayNames[dt.weekday % 7]}, ${monthNames[dt.month - 1]} ${dt.day}, ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = dt.difference(DateTime.now());

    if (diff.inMinutes < 1) {
      return "in less than a minute";
    } else if (diff.inMinutes < 60) {
      return "in ${diff.inMinutes} minutes";
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (minutes == 0) {
        return "in $hours hours";
      }
      return "in $hours hours, $minutes minutes";
    } else {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      if (hours == 0) {
        return "in $days days";
      }
      return "in $days days, $hours hours";
    }
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text("Save"),
          onPressed: cronModel.isValid && cronModel.expression.isNotEmpty
              ? () {
                  cronModel.addToHistory();
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
          label: Text("Clear"),
          onPressed: () {
            cronModel.clearExpression();
            setState(() {});
          },
        ),
        if (cronModel.history.isNotEmpty) SizedBox(width: 8),
        if (cronModel.history.isNotEmpty)
          TextButton.icon(
            icon: Icon(Icons.delete),
            label: Text("Clear History"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Clear History"),
                  content: Text("Clear all ${cronModel.history.length} saved entries?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        cronModel.clearHistory();
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
          "History (${cronModel.history.length})",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cronModel.history.asMap().entries.map((entry) {
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
              label: Text("${item.expression} ($timeStr)"),
              onPressed: () {
                cronModel.loadFromHistory(index);
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}