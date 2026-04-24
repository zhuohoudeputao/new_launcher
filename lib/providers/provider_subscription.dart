import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SubscriptionModel subscriptionModel = SubscriptionModel();

MyProvider providerSubscription = MyProvider(
    name: "Subscription",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Track subscriptions',
      keywords: 'subscription subscribe bill recurring payment netflix spotify membership fee monthly yearly',
      action: () {
        Global.infoModel.addInfo("AddSubscription", "Add Subscription",
            subtitle: "Tap to add a new subscription",
            icon: Icon(Icons.subscriptions),
            onTap: () => _showAddDialog(null));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await subscriptionModel.init();
  Global.infoModel.addInfoWidget(
      "Subscription",
      ChangeNotifierProvider.value(
          value: subscriptionModel,
          builder: (context, child) => SubscriptionCard()),
      title: "Subscription Tracker");
}

Future<void> _update() async {
  await subscriptionModel.refresh();
}

void _showAddDialog(SubscriptionEntry? existing) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  final nameController = TextEditingController(text: existing?.name ?? '');
  final costController = TextEditingController(text: existing?.cost.toString() ?? '');
  String frequency = existing?.frequency ?? 'monthly';
  DateTime renewalDate = existing?.renewalDate ?? DateTime.now().add(Duration(days: 30));

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? "Add Subscription" : "Edit Subscription"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Subscription name",
                  hintText: "e.g., Netflix, Spotify",
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Cost",
                  hintText: "e.g., 9.99",
                  suffixText: "\$",
                ),
              ),
              SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'weekly', label: Text("Weekly")),
                  ButtonSegment(value: 'monthly', label: Text("Monthly")),
                  ButtonSegment(value: 'yearly', label: Text("Yearly")),
                ],
                selected: {frequency},
                onSelectionChanged: (Set<String> newSelection) {
                  setDialogState(() {
                    frequency = newSelection.first;
                  });
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text("Next renewal"),
                subtitle: Text("${renewalDate.year}-${renewalDate.month}-${renewalDate.day}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: renewalDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      renewalDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel"),
          ),
          if (existing != null)
            TextButton(
              onPressed: () {
                subscriptionModel.deleteSubscription(existing.id);
                Navigator.pop(dialogContext);
              },
              child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final cost = double.tryParse(costController.text);
              if (name.isNotEmpty && cost != null && cost > 0) {
                if (existing == null) {
                  subscriptionModel.addSubscription(name, cost, frequency, renewalDate);
                } else {
                  subscriptionModel.updateSubscription(existing.id, name, cost, frequency, renewalDate);
                }
                Navigator.pop(dialogContext);
              }
            },
            child: Text(existing == null ? "Add" : "Save"),
          ),
        ],
      ),
    ),
  );
}

class SubscriptionEntry {
  final String id;
  final String name;
  final double cost;
  final String frequency;
  final DateTime renewalDate;
  final DateTime createdAt;

  SubscriptionEntry({
    required this.id,
    required this.name,
    required this.cost,
    required this.frequency,
    required this.renewalDate,
    required this.createdAt,
  });

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'cost': cost,
      'frequency': frequency,
      'renewalDate': renewalDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static SubscriptionEntry fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return SubscriptionEntry(
      id: map['id'] as String,
      name: map['name'] as String,
      cost: (map['cost'] as num).toDouble(),
      frequency: map['frequency'] as String,
      renewalDate: DateTime.parse(map['renewalDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  int daysUntilRenewal() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewal = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    return renewal.difference(today).inDays;
  }

  bool isExpired() {
    return daysUntilRenewal() < 0;
  }

  double monthlyEquivalent() {
    switch (frequency) {
      case 'weekly':
        return cost * 4.33;
      case 'monthly':
        return cost;
      case 'yearly':
        return cost / 12;
      default:
        return cost;
    }
  }

  double yearlyEquivalent() {
    switch (frequency) {
      case 'weekly':
        return cost * 52;
      case 'monthly':
        return cost * 12;
      case 'yearly':
        return cost;
      default:
        return cost;
    }
  }
}

class SubscriptionModel extends ChangeNotifier {
  static const int maxSubscriptions = 15;
  static const String _storageKey = 'subscription_entries';

  List<SubscriptionEntry> _subscriptions = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<SubscriptionEntry> get subscriptions => _subscriptions;
  int get count => _subscriptions.length;

  double get totalMonthly {
    return _subscriptions.fold(0.0, (sum, s) => sum + s.monthlyEquivalent());
  }

  double get totalYearly {
    return _subscriptions.fold(0.0, (sum, s) => sum + s.yearlyEquivalent());
  }

  List<SubscriptionEntry> get upcomingRenewals {
    final sorted = List<SubscriptionEntry>.from(_subscriptions);
    sorted.sort((a, b) => a.daysUntilRenewal().compareTo(b.daysUntilRenewal()));
    return sorted.where((s) => !s.isExpired()).toList();
  }

  SubscriptionEntry? get nextRenewal {
    if (upcomingRenewals.isEmpty) return null;
    return upcomingRenewals.first;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = prefs.getStringList(_storageKey) ?? [];
    _subscriptions = entryStrings.map((s) => SubscriptionEntry.fromJson(s)).toList();
    _sortSubscriptions();
    _isInitialized = true;
    Global.loggerModel.info("Subscription initialized with ${_subscriptions.length} subscriptions", source: "Subscription");
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  void _sortSubscriptions() {
    _subscriptions.sort((a, b) => a.daysUntilRenewal().compareTo(b.daysUntilRenewal()));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final entryStrings = _subscriptions.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, entryStrings);
  }

  void addSubscription(String name, double cost, String frequency, DateTime renewalDate) {
    if (_subscriptions.length >= maxSubscriptions) {
      _subscriptions.removeAt(0);
    }

    final id = '${DateTime.now().microsecondsSinceEpoch}_${_subscriptions.length}';
    _subscriptions.add(SubscriptionEntry(
      id: id,
      name: name,
      cost: cost,
      frequency: frequency,
      renewalDate: renewalDate,
      createdAt: DateTime.now(),
    ));

    _sortSubscriptions();
    Global.loggerModel.info("Added subscription: $name (\$${cost.toStringAsFixed(2)} $frequency)", source: "Subscription");
    _save();
    notifyListeners();
  }

  void updateSubscription(String id, String name, double cost, String frequency, DateTime renewalDate) {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index >= 0) {
      _subscriptions[index] = SubscriptionEntry(
        id: id,
        name: name,
        cost: cost,
        frequency: frequency,
        renewalDate: renewalDate,
        createdAt: _subscriptions[index].createdAt,
      );
      _sortSubscriptions();
      Global.loggerModel.info("Updated subscription: $name", source: "Subscription");
      _save();
      notifyListeners();
    }
  }

  void deleteSubscription(String id) {
    _subscriptions.removeWhere((s) => s.id == id);
    Global.loggerModel.info("Deleted subscription", source: "Subscription");
    _save();
    notifyListeners();
  }

  void renewSubscription(String id) {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index >= 0) {
      final existing = _subscriptions[index];
      DateTime newRenewalDate;
      switch (existing.frequency) {
        case 'weekly':
          newRenewalDate = existing.renewalDate.add(Duration(days: 7));
          break;
        case 'monthly':
          newRenewalDate = DateTime(
            existing.renewalDate.year,
            existing.renewalDate.month + 1,
            existing.renewalDate.day,
          );
          break;
        case 'yearly':
          newRenewalDate = DateTime(
            existing.renewalDate.year + 1,
            existing.renewalDate.month,
            existing.renewalDate.day,
          );
          break;
        default:
          newRenewalDate = existing.renewalDate.add(Duration(days: 30));
      }

      _subscriptions[index] = SubscriptionEntry(
        id: id,
        name: existing.name,
        cost: existing.cost,
        frequency: existing.frequency,
        renewalDate: newRenewalDate,
        createdAt: existing.createdAt,
      );
      _sortSubscriptions();
      Global.loggerModel.info("Renewed subscription: ${existing.name}", source: "Subscription");
      _save();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _subscriptions.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    Global.loggerModel.info("Cleared all subscriptions", source: "Subscription");
    notifyListeners();
  }
}

class SubscriptionCard extends StatefulWidget {
  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionModel>();

    if (!subscription.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.subscriptions, size: 24),
              SizedBox(width: 12),
              Text("Subscription Tracker: Loading..."),
            ],
          ),
        ),
      );
    }

    if (subscription.subscriptions.isEmpty) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.subscriptions, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Subscription Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                "No subscriptions tracked",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.add, size: 18),
                label: Text("Add Subscription"),
                onPressed: () => _showAddDialog(null),
              ),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.subscriptions, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Subscription Tracker",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    "${subscription.count} items",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "Monthly: \$${subscription.totalMonthly.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "Yearly: \$${subscription.totalYearly.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (subscription.nextRenewal != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, size: 16, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Next: ${subscription.nextRenewal!.name} in ${_formatDays(subscription.nextRenewal!.daysUntilRenewal())}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 8),
              ...subscription.subscriptions.map((s) => _buildSubscriptionItem(context, s, subscription)),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 20),
                    onPressed: () => _showAddDialog(null),
                    tooltip: "Add subscription",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_sweep, size: 20),
                    onPressed: () => _showClearDialog(context, subscription),
                    tooltip: "Clear all",
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionItem(BuildContext context, SubscriptionEntry s, SubscriptionModel model) {
    final days = s.daysUntilRenewal();
    final urgencyColor = days <= 7
        ? Theme.of(context).colorScheme.error
        : days <= 30
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.tertiary;

    return ListTile(
      dense: true,
      leading: Icon(Icons.payment, size: 20, color: urgencyColor),
      title: Text(s.name, style: TextStyle(fontSize: 14)),
      subtitle: Text(
        "\$${s.cost.toStringAsFixed(2)} / ${s.frequency}",
        style: TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (days < 0)
            Text(
              "Expired",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            )
          else
            Text(
              _formatDays(days),
              style: TextStyle(fontSize: 12, color: urgencyColor),
            ),
          SizedBox(width: 8),
          if (days < 0)
            IconButton(
              icon: Icon(Icons.refresh, size: 18),
              onPressed: () => model.renewSubscription(s.id),
              tooltip: "Renew",
            ),
        ],
      ),
      onTap: () => _showAddDialog(s),
    );
  }

  String _formatDays(int days) {
    if (days < 0) return "Expired";
    if (days == 0) return "Today";
    if (days == 1) return "Tomorrow";
    if (days < 7) return "$days days";
    if (days < 30) return "${(days / 7).floor()} weeks";
    return "${(days / 30).floor()} months";
  }

  void _showClearDialog(BuildContext context, SubscriptionModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Subscriptions"),
        content: Text("Are you sure you want to delete all ${model.count} subscriptions?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              model.clearAll();
              Navigator.pop(context);
            },
            child: Text("Clear All", style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}