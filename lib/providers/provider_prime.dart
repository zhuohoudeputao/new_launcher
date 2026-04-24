import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';

class PrimeModel extends ChangeNotifier {
  int _inputNumber = 0;
  bool _isPrime = false;
  List<int> _primeFactors = [];
  bool _showFactors = false;
  bool _isInitialized = false;
  List<Map<String, dynamic>> _history = [];
  static const int _maxHistoryLength = 10;

  int get inputNumber => _inputNumber;
  bool get isPrime => _isPrime;
  List<int> get primeFactors => _primeFactors;
  bool get showFactors => _showFactors;
  bool get isInitialized => _isInitialized;
  List<Map<String, dynamic>> get history => _history;

  static bool checkPrime(int n) {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    for (int i = 3; i <= sqrt(n).toInt(); i += 2) {
      if (n % i == 0) return false;
    }
    return true;
  }

  static List<int> findPrimeFactors(int n) {
    if (n < 2) return [];
    List<int> factors = [];
    int num = n;
    
    while (num % 2 == 0) {
      factors.add(2);
      num = num ~/ 2;
    }
    
    for (int i = 3; i <= sqrt(num).toInt(); i += 2) {
      while (num % i == 0) {
        factors.add(i);
        num = num ~/ i;
      }
    }
    
    if (num > 2) {
      factors.add(num);
    }
    
    return factors;
  }

  void init() {
    Global.loggerModel.info("Prime initialized", source: "Prime");
    _isInitialized = true;
    notifyListeners();
  }

  void setInputNumber(int value) {
    _inputNumber = value;
    _isPrime = checkPrime(value);
    _primeFactors = findPrimeFactors(value);
    notifyListeners();
  }

  void toggleShowFactors() {
    _showFactors = !_showFactors;
    notifyListeners();
  }

  void addToHistory() {
    if (_inputNumber < 2) return;
    
    final entry = {
      'number': _inputNumber,
      'isPrime': _isPrime,
      'factors': _primeFactors,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _history.insert(0, entry);
    
    if (_history.length > _maxHistoryLength) {
      _history.removeLast();
    }
    
    Global.settingsModel.saveValue('PrimeHistory', 
      _history.map((e) => jsonEncode(e)).toList());
    
    notifyListeners();
  }

  void loadFromHistory(Map<String, dynamic> entry) {
    _inputNumber = entry['number'] as int;
    _isPrime = entry['isPrime'] as bool;
    _primeFactors = (entry['factors'] as List).cast<int>();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    final saved = await Global.getValue('PrimeHistory', <String>[]);
    if (saved is List<String>) {
      _history = saved.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    }
    notifyListeners();
  }

  void clearInput() {
    _inputNumber = 0;
    _isPrime = false;
    _primeFactors = [];
    notifyListeners();
  }

  void clearHistory() {
    _history = [];
    Global.settingsModel.saveValue('PrimeHistory', <String>[]);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

PrimeModel primeModel = PrimeModel();

class PrimeCard extends StatelessWidget {
  const PrimeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PrimeModel>();
    
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
                Icon(Icons.calculate, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text('Prime Number Checker', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            if (!model.isInitialized)
              Center(child: CircularProgressIndicator())
            else ...[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter a number to check...',
                  border: OutlineInputBorder(),
                  suffixIcon: model.inputNumber > 0
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => model.clearInput(),
                        )
                      : null,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final num = int.tryParse(value) ?? 0;
                  model.setInputNumber(num);
                },
              ),
              SizedBox(height: 12),
              if (model.inputNumber > 0) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: model.isPrime 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        model.isPrime ? Icons.check_circle : Icons.cancel,
                        color: model.isPrime 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        model.isPrime 
                            ? '${model.inputNumber} is a prime number!' 
                            : '${model.inputNumber} is not prime',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: model.isPrime 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                if (!model.isPrime && model.primeFactors.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('Prime Factors: ',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Expanded(
                        child: Text(
                          model.primeFactors.join(' × '),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
                if (model.isPrime) ...[
                  Text('${model.inputNumber} has no factors other than 1 and itself.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ],
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Save to History'),
                    onPressed: model.inputNumber > 1 ? () => model.addToHistory() : null,
                  ),
                  if (model.history.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.history),
                      label: Text('History (${model.history.length})'),
                      onPressed: () => _showHistoryDialog(context, model),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(BuildContext context, PrimeModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('History'),
            TextButton(
              child: Text('Clear All'),
              onPressed: () {
                model.clearHistory();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: model.history.length,
            itemBuilder: (context, index) {
              final entry = model.history[index];
              final timestamp = DateTime.parse(entry['timestamp'] as String);
              final timeStr = _formatTime(timestamp);
              final factors = (entry['factors'] as List).cast<int>();
              
              return ListTile(
                leading: Icon(
                  entry['isPrime'] as bool ? Icons.check_circle : Icons.cancel,
                  color: entry['isPrime'] as bool 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                title: Text('${entry['number']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(timeStr),
                    if (!(entry['isPrime'] as bool) && factors.isNotEmpty)
                      Text('Factors: ${factors.join(' × ')}',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                isThreeLine: !(entry['isPrime'] as bool) && factors.isNotEmpty,
                onTap: () {
                  model.loadFromHistory(entry);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

MyProvider providerPrime = MyProvider(
  name: "Prime",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Prime Number Checker",
        keywords: "prime, number, check, factor, math, divisor, isprime, prime factor",
        action: () {
          Global.infoModel.addInfoWidget("PrimeCard", PrimeCard(), title: "Prime Number Checker");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    primeModel.init();
    primeModel.loadHistory();
    Global.infoModel.addInfoWidget("PrimeCard", PrimeCard(), title: "Prime Number Checker");
  },
  update: () {
    primeModel.refresh();
  },
);