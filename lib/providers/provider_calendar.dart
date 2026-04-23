import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

CalendarModel calendarModel = CalendarModel();

MyProvider providerCalendar = MyProvider(
  name: "Calendar",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: "Show Calendar",
      keywords: "calendar month date day week schedule",
      action: _showCalendar,
      times: List.generate(24, (_) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  calendarModel.init();
  Global.infoModel.addInfoWidget(
      "Calendar",
      ChangeNotifierProvider.value(
          value: calendarModel,
          builder: (context, child) => CalendarCard()),
      title: "Calendar");
}

Future<void> _update() async {
  calendarModel.refresh();
}

void _showCalendar() {
  Global.infoModel.addInfoWidget("Calendar", CalendarCard(), title: "Calendar");
}

class CalendarModel extends ChangeNotifier {
  DateTime _currentMonth = DateTime.now();
  Timer? _dayUpdateTimer;
  bool _disposed = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  DateTime get currentMonth => _currentMonth;

  void init() {
    _currentMonth = DateTime.now();
    _isInitialized = true;
    _scheduleDayUpdate();
    Global.loggerModel.info("Calendar initialized", source: "Calendar");
    notifyListeners();
  }

  void _scheduleDayUpdate() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final delay = midnight.difference(now);
    _dayUpdateTimer?.cancel();
    _dayUpdateTimer = Timer(delay, () {
      if (!_disposed) {
        _currentMonth = DateTime.now();
        notifyListeners();
        _dayUpdateTimer?.cancel();
        _dayUpdateTimer = Timer.periodic(const Duration(hours: 1), (_) {
          if (!_disposed) {
            _currentMonth = DateTime.now();
            notifyListeners();
          }
        });
      }
    });
  }

  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    notifyListeners();
  }

  void goToToday() {
    _currentMonth = DateTime.now();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _dayUpdateTimer?.cancel();
    super.dispose();
  }
}

class CalendarCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final currentMonth = calendar.currentMonth;
    final days = _getDaysInMonth(currentMonth);
    final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
    final weekNumber = _getWeekNumber(now);

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: calendar.previousMonth,
                ),
                GestureDetector(
                  onTap: calendar.goToToday,
                  child: Column(
                    children: [
                      Text(
                        '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (!isCurrentMonth)
                        Text(
                          'Tap to go to today',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: calendar.nextMonth,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              )).toList(),
            ),
            SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                final isCurrentMonthDay = day.month == currentMonth.month;
                final isSunday = day.weekday == 7;

                return Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: isToday
                        ? BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          )
                        : null,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? colorScheme.onPrimary
                              : isCurrentMonthDay
                                  ? isSunday ? colorScheme.error : colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 16, color: colorScheme.primary),
                SizedBox(width: 4),
                Text(
                  'Week $weekNumber',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];

    final startWeekday = firstDay.weekday % 7;
    for (int i = 0; i < startWeekday; i++) {
      days.add(DateTime(month.year, month.month, 1 - (startWeekday - i)));
    }

    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    final endWeekday = lastDay.weekday % 7;
    for (int i = 1; i < 7 - endWeekday; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }

    return days;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}