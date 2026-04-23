import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

CurrencyModel currencyModel = CurrencyModel();

MyProvider providerCurrency = MyProvider(
    name: "Currency",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Currency Converter',
      keywords: 'currency exchange rate money convert dollar euro pound yen yuan usd eur gbp jpy cny',
      action: () => currencyModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  currencyModel.init();
  Global.infoModel.addInfoWidget(
      "Currency",
      ChangeNotifierProvider.value(
          value: currencyModel,
          builder: (context, child) => CurrencyCard()),
      title: "Currency Converter");
}

Future<void> _update() async {
  currencyModel.refresh();
}

const Map<String, String> currencyInfo = {
  'USD': 'US Dollar',
  'EUR': 'Euro',
  'GBP': 'British Pound',
  'JPY': 'Japanese Yen',
  'CNY': 'Chinese Yuan',
  'AUD': 'Australian Dollar',
  'CAD': 'Canadian Dollar',
  'CHF': 'Swiss Franc',
  'INR': 'Indian Rupee',
  'MXN': 'Mexican Peso',
  'KRW': 'South Korean Won',
  'SGD': 'Singapore Dollar',
  'HKD': 'Hong Kong Dollar',
  'NOK': 'Norwegian Krone',
  'SEK': 'Swedish Krona',
  'DKK': 'Danish Krone',
  'NZD': 'New Zealand Dollar',
  'ZAR': 'South African Rand',
  'RUB': 'Russian Ruble',
  'BRL': 'Brazilian Real',
};

List<String> getCommonCurrencies() {
  return currencyInfo.keys.toList();
}

class CurrencyConversionHistory {
  final double inputValue;
  final String inputCurrency;
  final double outputValue;
  final String outputCurrency;
  final DateTime timestamp;

  CurrencyConversionHistory({
    required this.inputValue,
    required this.inputCurrency,
    required this.outputValue,
    required this.outputCurrency,
    required this.timestamp,
  });
  
  String get inputName => currencyInfo[inputCurrency] ?? inputCurrency;
  String get outputName => currencyInfo[outputCurrency] ?? outputCurrency;
}

class CurrencyModel extends ChangeNotifier {
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  String _inputValue = '1';
  String _outputValue = '';
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  Map<String, double> _rates = {};
  DateTime? _ratesTimestamp;
  final List<CurrencyConversionHistory> _history = [];
  static const int maxHistory = 10;
  static const Duration cacheValidity = Duration(hours: 1);

  String get fromCurrency => _fromCurrency;
  String get toCurrency => _toCurrency;
  String get inputValue => _inputValue;
  String get outputValue => _outputValue;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double> get rates => Map.unmodifiable(_rates);
  List<CurrencyConversionHistory> get history => List.unmodifiable(_history);
  bool get hasHistory => _history.isNotEmpty;
  List<String> get availableCurrencies => getCommonCurrencies();
  DateTime? get ratesTimestamp => _ratesTimestamp;

  Future<void> init() async {
    _isInitialized = true;
    Global.loggerModel.info("Currency initialized", source: "Currency");
    await fetchRates();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
    Global.loggerModel.info("Currency refreshed", source: "Currency");
  }

  Future<void> fetchRates() async {
    if (_rates.isNotEmpty && _ratesTimestamp != null) {
      final age = DateTime.now().difference(_ratesTimestamp!);
      if (age < cacheValidity) {
        Global.loggerModel.info("Using cached rates (age: ${age.inMinutes} min)", source: "Currency");
        _convert();
        return;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.frankfurter.app/latest?from=${_fromCurrency}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _rates = Map<String, double>.from(data['rates']);
        _rates[_fromCurrency] = 1.0;
        _ratesTimestamp = DateTime.now();
        _convert();
        Global.loggerModel.info("Rates fetched successfully", source: "Currency");
      } else {
        _error = 'Failed to fetch rates: ${response.statusCode}';
        Global.loggerModel.error(_error!, source: "Currency");
      }
    } catch (e) {
      _error = 'Network error: $e';
      Global.loggerModel.error(_error!, source: "Currency");
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFromCurrency(String currency) {
    _fromCurrency = currency;
    if (_fromCurrency == _toCurrency) {
      final currencies = availableCurrencies;
      final other = currencies.firstWhere((c) => c != currency, orElse: () => currency);
      _toCurrency = other;
    }
    fetchRates();
    notifyListeners();
  }

  void setToCurrency(String currency) {
    _toCurrency = currency;
    if (_toCurrency == _fromCurrency) {
      final currencies = availableCurrencies;
      final other = currencies.firstWhere((c) => c != currency, orElse: () => currency);
      _fromCurrency = other;
      fetchRates();
    } else {
      _convert();
    }
    notifyListeners();
  }

  void setInputValue(String value) {
    _inputValue = value;
    _convert();
    notifyListeners();
  }

  void swapCurrencies() {
    final temp = _fromCurrency;
    _fromCurrency = _toCurrency;
    _toCurrency = temp;
    
    final tempValue = _outputValue;
    _inputValue = tempValue.isNotEmpty ? tempValue : '1';
    
    fetchRates();
    Global.loggerModel.info("Currencies swapped", source: "Currency");
  }

  void clear() {
    _inputValue = '1';
    _convert();
    notifyListeners();
    Global.loggerModel.info("Currency cleared", source: "Currency");
  }

  void _convert() {
    final input = double.tryParse(_inputValue);
    if (input == null) {
      _outputValue = '';
      return;
    }
    
    if (_rates.isEmpty) {
      _outputValue = '';
      return;
    }
    
    final rate = _rates[_toCurrency];
    if (rate == null) {
      _outputValue = '';
      return;
    }
    
    final result = input * rate;
    _outputValue = _formatResult(result);
  }

  String _formatResult(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    String result = value.toStringAsFixed(4);
    result = result.replaceAll(RegExp(r'0+$'), '');
    result = result.replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  void addToHistory() {
    final input = double.tryParse(_inputValue);
    if (input == null || input == 0) return;
    
    final output = double.tryParse(_outputValue);
    if (output == null) return;
    
    _history.insert(0, CurrencyConversionHistory(
      inputValue: input,
      inputCurrency: _fromCurrency,
      outputValue: output,
      outputCurrency: _toCurrency,
      timestamp: DateTime.now(),
    ));
    
    while (_history.length > maxHistory) {
      _history.removeLast();
    }
    
    notifyListeners();
    Global.loggerModel.info("Conversion added to history", source: "Currency");
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("Currency history cleared", source: "Currency");
  }

  void useHistoryEntry(CurrencyConversionHistory entry) {
    _fromCurrency = entry.inputCurrency;
    _toCurrency = entry.outputCurrency;
    _inputValue = entry.inputValue.toString();
    fetchRates();
  }

  double? getRate(String currency) {
    return _rates[currency];
  }
}

class CurrencyCard extends StatefulWidget {
  @override
  State<CurrencyCard> createState() => _CurrencyCardState();
}

class _CurrencyCardState extends State<CurrencyCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyModel>();
    final colorScheme = Theme.of(context).colorScheme;
    
    if (!currency.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.attach_money, size: 24),
              SizedBox(width: 12),
              Text("Currency Converter: Loading..."),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Currency Converter",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh, size: 18),
                      onPressed: currency.isLoading ? null : () => currency.fetchRates(),
                      tooltip: "Refresh rates",
                      style: IconButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (currency.hasHistory)
                      IconButton(
                        icon: Icon(_showHistory ? Icons.attach_money : Icons.history, size: 18),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        tooltip: _showHistory ? "Converter" : "History",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (currency.hasHistory)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearHistoryConfirmation(context),
                        tooltip: "Clear history",
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (currency.isLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (currency.error != null)
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  currency.error!,
                  style: TextStyle(color: colorScheme.error),
                ),
              )
            else if (_showHistory)
              _buildHistoryView(currency)
            else
              _buildConverterView(currency),
          ],
        ),
      ),
    );
  }

  Widget _buildConverterView(CurrencyModel currency) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildConversionRow(currency),
        if (currency.ratesTimestamp != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Rates updated: ${_formatTimestamp(currency.ratesTimestamp!)}",
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _buildConversionRow(CurrencyModel currency) {
    return Row(
      children: [
        Expanded(child: _buildFromSection(currency)),
        IconButton(
          icon: Icon(Icons.swap_horiz),
          onPressed: currency.swapCurrencies,
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        Expanded(child: _buildToSection(currency)),
      ],
    );
  }

  Widget _buildFromSection(CurrencyModel currency) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCurrencyDropdown(currency, currency.fromCurrency, true),
        SizedBox(height: 4),
        _buildValueField(currency, true),
      ],
    );
  }

  Widget _buildToSection(CurrencyModel currency) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCurrencyDropdown(currency, currency.toCurrency, false),
        SizedBox(height: 4),
        _buildValueField(currency, false),
      ],
    );
  }

  Widget _buildCurrencyDropdown(CurrencyModel currency, String currentCurrency, bool isFrom) {
    final currencies = currency.availableCurrencies;
    
    return DropdownButton<String>(
      value: currentCurrency,
      isExpanded: true,
      underline: Container(),
      items: currencies.map((code) {
        return DropdownMenuItem(
          value: code,
          child: Text(
            code,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          if (isFrom) {
            currency.setFromCurrency(value);
          } else {
            currency.setToCurrency(value);
          }
        }
      },
    );
  }

  Widget _buildValueField(CurrencyModel currency, bool isInput) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (isInput) {
      return TextField(
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
        ),
        controller: TextEditingController(text: currency.inputValue),
        onChanged: (value) => currency.setInputValue(value),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Text(
          currency.outputValue.isNotEmpty ? currency.outputValue : '0',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildHistoryView(CurrencyModel currency) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: currency.history.length,
        itemBuilder: (context, index) {
          final entry = currency.history[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text('${entry.inputValue} ${entry.inputCurrency}'),
            subtitle: Text(
              '= ${entry.outputValue} ${entry.outputCurrency}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              currency.useHistoryEntry(entry);
              setState(() => _showHistory = false);
            },
          );
        },
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

  Future<void> _showClearHistoryConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear History"),
        content: Text("Clear all conversion history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear"),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      context.read<CurrencyModel>().clearHistory();
    }
  }
}