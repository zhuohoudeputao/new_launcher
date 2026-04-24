import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

DaysCalculatorModel daysCalculatorModel = DaysCalculatorModel();

MyProvider providerDaysCalculator = MyProvider(
    name: "DaysCalculator",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Days Calculator',
      keywords: 'days calculator date difference between add subtract calculate',
      action: () => daysCalculatorModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  daysCalculatorModel.init();
  Global.infoModel.addInfoWidget(
      "DaysCalculator",
      ChangeNotifierProvider.value(
          value: daysCalculatorModel,
          builder: (context, child) => DaysCalculatorCard()),
      title: "Days Calculator");
}

Future<void> _update() async {
  daysCalculatorModel.refresh();
}

class DaysCalculatorHistory {
  final String operation;
  final String startDate;
  final String endDate;
  final int days;
  final int weeks;
  final int months;
  final int years;
  final DateTime timestamp;

  DaysCalculatorHistory({
    required this.operation,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.weeks,
    required this.months,
    required this.years,
    required this.timestamp,
  });
}

class DaysCalculatorModel extends ChangeNotifier {
  String _operation = 'difference';
  DateTime? _startDate;
  DateTime? _endDate;
  int _daysToAdd = 0;
  int _calculatedDays = 0;
  int _calculatedWeeks = 0;
  int _calculatedMonths = 0;
  int _calculatedYears = 0;
  DateTime? _resultDate;
  List<DaysCalculatorHistory> _history = [];
  bool _isLoading = false;
  String? _error;

  static const int maxHistoryLength = 10;

  String get operation => _operation;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get daysToAdd => _daysToAdd;
  int get calculatedDays => _calculatedDays;
  int get calculatedWeeks => _calculatedWeeks;
  int get calculatedMonths => _calculatedMonths;
  int get calculatedYears => _calculatedYears;
  DateTime? get resultDate => _resultDate;
  List<DaysCalculatorHistory> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void init() {
    _isLoading = true;
    notifyListeners();
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

  void setOperation(String op) {
    _operation = op;
    _error = null;
    _calculate();
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    _error = null;
    _calculate();
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    _error = null;
    _calculate();
    notifyListeners();
  }

  void setDaysToAdd(int days) {
    _daysToAdd = days;
    _error = null;
    _calculate();
    notifyListeners();
  }

  void setStartDateToToday() {
    _startDate = DateTime.now();
    _error = null;
    _calculate();
    notifyListeners();
  }

  void setEndDateToToday() {
    _endDate = DateTime.now();
    _error = null;
    _calculate();
    notifyListeners();
  }

  void swapDates() {
    final temp = _startDate;
    _startDate = _endDate;
    _endDate = temp;
    _error = null;
    _calculate();
    notifyListeners();
  }

  void _calculate() {
    if (_startDate == null) {
      _error = 'Select start date';
      return;
    }

    if (_operation == 'difference') {
      if (_endDate == null) {
        _error = 'Select end date';
        return;
      }
      _calculateDifference();
    } else if (_operation == 'add') {
      _calculateAddDays();
    } else if (_operation == 'subtract') {
      _calculateSubtractDays();
    }
  }

  void _calculateDifference() {
    if (_startDate == null || _endDate == null) return;

    int days = _endDate!.difference(_startDate!).inDays;
    if (days < 0) {
      days = -days;
    }

    _calculatedDays = days;
    _calculatedWeeks = days ~/ 7;
    _calculatedMonths = _calculateMonthsDifference(_startDate!, _endDate!);
    _calculatedYears = _calculateYearsDifference(_startDate!, _endDate!);
    _resultDate = null;
    _error = null;
  }

  int _calculateMonthsDifference(DateTime start, DateTime end) {
    int months = (end.year - start.year) * 12 + (end.month - start.month);
    if (months < 0) months = -months;
    if (end.day < start.day) {
      months = months > 0 ? months - 1 : 0;
    }
    return months;
  }

  int _calculateYearsDifference(DateTime start, DateTime end) {
    int years = end.year - start.year;
    if (years < 0) years = -years;
    if (end.month < start.month || (end.month == start.month && end.day < start.day)) {
      years = years > 0 ? years - 1 : 0;
    }
    return years;
  }

  void _calculateAddDays() {
    if (_startDate == null) return;

    _resultDate = _startDate!.add(Duration(days: _daysToAdd));
    _calculatedDays = _daysToAdd;
    _calculatedWeeks = _daysToAdd ~/ 7;
    _calculatedMonths = _daysToAdd ~/ 30;
    _calculatedYears = _daysToAdd ~/ 365;
    _error = null;
  }

  void _calculateSubtractDays() {
    if (_startDate == null) return;

    _resultDate = _startDate!.subtract(Duration(days: _daysToAdd));
    _calculatedDays = _daysToAdd;
    _calculatedWeeks = _daysToAdd ~/ 7;
    _calculatedMonths = _daysToAdd ~/ 30;
    _calculatedYears = _daysToAdd ~/ 365;
    _error = null;
  }

  void addToHistory() {
    if (_startDate == null) return;
    if (_operation == 'difference' && _endDate == null) return;

    DaysCalculatorHistory entry = DaysCalculatorHistory(
      operation: _operation,
      startDate: _formatDate(_startDate!),
      endDate: _operation == 'difference' ? _formatDate(_endDate!) : '',
      days: _calculatedDays,
      weeks: _calculatedWeeks,
      months: _calculatedMonths,
      years: _calculatedYears,
      timestamp: DateTime.now(),
    );

    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void applyFromHistory(DaysCalculatorHistory entry) {
    _operation = entry.operation;
    _startDate = DateTime.tryParse(entry.startDate);
    if (entry.endDate.isNotEmpty) {
      _endDate = DateTime.tryParse(entry.endDate);
    }
    _daysToAdd = entry.days;
    _error = null;
    _calculate();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void reset() {
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _daysToAdd = 0;
    _operation = 'difference';
    _calculatedDays = 0;
    _calculatedWeeks = 0;
    _calculatedMonths = 0;
    _calculatedYears = 0;
    _resultDate = null;
    _error = null;
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void refresh() {
    notifyListeners();
  }
}

class DaysCalculatorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DaysCalculatorModel>(
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
                    Text('Days Calculator',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      onPressed: () => model.reset(),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Reset',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildOperationSelector(context, model),
                const SizedBox(height: 12),
                _buildInputSection(context, model),
                const SizedBox(height: 12),
                _buildResultSection(context, model),
                if (model.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      model.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (model.calculatedDays > 0 || model.resultDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton(
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
                      child: const Text('Add to History'),
                    ),
                  ),
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

  Widget _buildOperationSelector(BuildContext context, DaysCalculatorModel model) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'difference', label: Text('Difference')),
        ButtonSegment(value: 'add', label: Text('Add Days')),
        ButtonSegment(value: 'subtract', label: Text('Subtract Days')),
      ],
      selected: {model.operation},
      onSelectionChanged: (Set<String> newSelection) {
        model.setOperation(newSelection.first);
      },
    );
  }

  Widget _buildInputSection(BuildContext context, DaysCalculatorModel model) {
    if (model.operation == 'difference') {
      return Column(
        children: [
          _buildDateRow(
            context,
            label: 'Start Date',
            date: model.startDate,
            onDateSelected: (date) => model.setStartDate(date),
            onTodayPressed: () => model.setStartDateToToday(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => model.swapDates(),
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Swap dates',
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          _buildDateRow(
            context,
            label: 'End Date',
            date: model.endDate,
            onDateSelected: (date) => model.setEndDate(date),
            onTodayPressed: () => model.setEndDateToToday(),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildDateRow(
            context,
            label: 'Date',
            date: model.startDate,
            onDateSelected: (date) => model.setStartDate(date),
            onTodayPressed: () => model.setStartDateToToday(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Days:', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: model.daysToAdd.toDouble(),
                  min: 0,
                  max: 365,
                  divisions: 365,
                  label: model.daysToAdd.toString(),
                  onChanged: (value) => model.setDaysToAdd(value.round()),
                ),
              ),
              const SizedBox(width: 8),
              Text('${model.daysToAdd}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildDateRow(
    BuildContext context,
    {required String label,
    required DateTime? date,
    required void Function(DateTime) onDateSelected,
    required void Function() onTodayPressed,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (selected != null) {
                onDateSelected(selected);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date != null
                        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                        : 'Select date',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onTodayPressed,
          icon: const Icon(Icons.today),
          tooltip: 'Today',
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(BuildContext context, DaysCalculatorModel model) {
    if (model.operation == 'difference') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${model.calculatedDays} days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildResultChip(context, '${model.calculatedWeeks} weeks'),
                _buildResultChip(context, '${model.calculatedMonths} months'),
                _buildResultChip(context, '${model.calculatedYears} years'),
              ],
            ),
          ],
        ),
      );
    } else {
      if (model.resultDate == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Result Date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${model.resultDate!.year}-${model.resultDate!.month.toString().padLeft(2, '0')}-${model.resultDate!.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildResultChip(context, '${model.calculatedDays} days'),
                _buildResultChip(context, '${model.calculatedWeeks} weeks'),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildResultChip(BuildContext context, String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, DaysCalculatorModel model, DaysCalculatorHistory entry) {
    String description;
    if (entry.operation == 'difference') {
      description = '${entry.startDate} to ${entry.endDate}: ${entry.days} days';
    } else {
      description = '${entry.startDate} ${entry.operation} ${entry.days} days';
    }

    return InkWell(
      onTap: () => model.applyFromHistory(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmationDialog(BuildContext context, DaysCalculatorModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all calculation history?'),
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