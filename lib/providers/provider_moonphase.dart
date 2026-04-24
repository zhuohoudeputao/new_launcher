import 'dart:math';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

MoonPhaseModel moonPhaseModel = MoonPhaseModel();

MyProvider providerMoonPhase = MyProvider(
    name: "MoonPhase",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Moon Phase',
      keywords: 'moon phase lunar cycle full new crescent gibbous waxing waning quarter',
      action: () {
        Global.infoModel.addInfo(
            "MoonPhase",
            "Moon Phase",
            subtitle: "Current lunar phase",
            icon: Icon(Icons.nightlight_round),
            onTap: () {});
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  moonPhaseModel.init();
  Global.infoModel.addInfoWidget(
      "MoonPhase",
      ChangeNotifierProvider.value(
          value: moonPhaseModel,
          builder: (context, child) => MoonPhaseCard()),
      title: "Moon Phase");
}

Future<void> _update() async {
  moonPhaseModel.refresh();
}

class MoonPhaseModel extends ChangeNotifier {
  bool _isInitialized = false;
  DateTime _currentDate = DateTime.now();
  double _moonAge = 0;
  double _illumination = 0;
  String _phaseName = "";
  String _phaseEmoji = "";
  DateTime _nextNewMoon = DateTime.now();
  DateTime _nextFullMoon = DateTime.now();

  bool get isInitialized => _isInitialized;
  DateTime get currentDate => _currentDate;
  double get moonAge => _moonAge;
  double get illumination => _illumination;
  String get phaseName => _phaseName;
  String get phaseEmoji => _phaseEmoji;
  DateTime get nextNewMoon => _nextNewMoon;
  DateTime get nextFullMoon => _nextFullMoon;

  static const double _synodicMonth = 29.53058867;
  static final DateTime _knownNewMoon = DateTime(2000, 1, 6, 18, 14);

  void init() {
    _isInitialized = true;
    _calculateMoonPhase(DateTime.now());
    Global.loggerModel.info("MoonPhase initialized", source: "MoonPhase");
    notifyListeners();
  }

  void refresh() {
    _calculateMoonPhase(DateTime.now());
    notifyListeners();
  }

  void setDate(DateTime date) {
    _currentDate = date;
    _calculateMoonPhase(date);
    notifyListeners();
  }

  void _calculateMoonPhase(DateTime date) {
    _currentDate = date;
    
    double daysSinceKnownNewMoon = date.difference(_knownNewMoon).inMinutes / (24 * 60);
    double moonCycles = daysSinceKnownNewMoon / _synodicMonth;
    _moonAge = (moonCycles % 1) * _synodicMonth;
    
    if (_moonAge < 0) {
      _moonAge += _synodicMonth;
    }
    
    _illumination = _calculateIllumination(_moonAge);
    _phaseName = _getPhaseName(_moonAge);
    _phaseEmoji = _getPhaseEmoji(_moonAge);
    
    double daysToNextNewMoon = _synodicMonth - _moonAge;
    _nextNewMoon = date.add(Duration(days: daysToNextNewMoon.floor(), hours: ((daysToNextNewMoon % 1) * 24).floor()));
    
    double daysToNextFullMoon;
    if (_moonAge < _synodicMonth / 2) {
      daysToNextFullMoon = (_synodicMonth / 2) - _moonAge;
    } else {
      daysToNextFullMoon = (_synodicMonth * 1.5) - _moonAge;
    }
    _nextFullMoon = date.add(Duration(days: daysToNextFullMoon.floor(), hours: ((daysToNextFullMoon % 1) * 24).floor()));
  }

  double _calculateIllumination(double moonAge) {
    double angle = (moonAge / _synodicMonth) * 2 * pi;
    double illumination = (1 - cos(angle)) / 2;
    return illumination * 100;
  }

  String _getPhaseName(double moonAge) {
    double phasePosition = moonAge / _synodicMonth;
    
    if (phasePosition < 0.03 || phasePosition >= 0.97) {
      return "New Moon";
    } else if (phasePosition < 0.22) {
      return "Waxing Crescent";
    } else if (phasePosition < 0.28) {
      return "First Quarter";
    } else if (phasePosition < 0.47) {
      return "Waxing Gibbous";
    } else if (phasePosition < 0.53) {
      return "Full Moon";
    } else if (phasePosition < 0.72) {
      return "Waning Gibbous";
    } else if (phasePosition < 0.78) {
      return "Last Quarter";
    } else {
      return "Waning Crescent";
    }
  }

  String _getPhaseEmoji(double moonAge) {
    double phasePosition = moonAge / _synodicMonth;
    
    if (phasePosition < 0.03 || phasePosition >= 0.97) {
      return "🌑";
    } else if (phasePosition < 0.22) {
      return "🌒";
    } else if (phasePosition < 0.28) {
      return "🌓";
    } else if (phasePosition < 0.47) {
      return "🌔";
    } else if (phasePosition < 0.53) {
      return "🌕";
    } else if (phasePosition < 0.72) {
      return "🌖";
    } else if (phasePosition < 0.78) {
      return "🌗";
    } else {
      return "🌘";
    }
  }

  String formatDaysUntil(DateTime target) {
    int days = target.difference(_currentDate).inDays;
    if (days < 0) days = 0;
    if (days == 0) return "Today";
    if (days == 1) return "Tomorrow";
    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    return "${(days / 30).floor()} months";
  }

  String formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }
}

class MoonPhaseCard extends StatefulWidget {
  @override
  State<MoonPhaseCard> createState() => _MoonPhaseCardState();
}

class _MoonPhaseCardState extends State<MoonPhaseCard> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MoonPhaseModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.nightlight_round, size: 24),
              SizedBox(width: 12),
              Text("Moon Phase: Loading..."),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight_round, size: 20),
                SizedBox(width: 8),
                Text(
                  "Moon Phase",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                ActionChip(
                  label: Text("Today", style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    _selectedDate = DateTime.now();
                    model.setDate(_selectedDate);
                  },
                  avatar: Icon(Icons.today, size: 14),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildPhaseDisplay(context, model),
            SizedBox(height: 12),
            _buildDateSelector(context, model),
            SizedBox(height: 12),
            _buildUpcomingEvents(context, model),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseDisplay(BuildContext context, MoonPhaseModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  model.phaseEmoji,
                  style: TextStyle(fontSize: 48),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  model.phaseName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.brightness_6, size: 16, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 4),
                Text(
                  "${model.illumination.toStringAsFixed(1)}% illuminated",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 16, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 4),
                Text(
                  "Day ${model.moonAge.toStringAsFixed(1)} of cycle",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, MoonPhaseModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(
              model.formatDate(model.currentDate),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit_calendar, size: 18),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _selectedDate = picked;
                  model.setDate(picked);
                }
              },
              tooltip: "Select date",
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, MoonPhaseModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text("Upcoming Events", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("🌑", style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Next New Moon: ${model.formatDaysUntil(model.nextNewMoon)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text("🌕", style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Next Full Moon: ${model.formatDaysUntil(model.nextFullMoon)}",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}