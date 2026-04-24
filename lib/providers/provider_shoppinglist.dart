import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ShoppingListModel shoppingListModel = ShoppingListModel();

MyProvider providerShoppingList = MyProvider(
    name: "ShoppingList",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Quick item',
      keywords: 'shopping list shop buy grocery market item add cart',
      action: () {
        Global.infoModel.addInfo("AddShoppingItem", "Add Shopping Item",
            subtitle: "Tap to add a new item",
            icon: Icon(Icons.add_shopping_cart),
            onTap: () => _showAddShoppingItemDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await shoppingListModel.init();
  Global.infoModel.addInfoWidget(
      "ShoppingList",
      ChangeNotifierProvider.value(
          value: shoppingListModel,
          builder: (context, child) => ShoppingListCard()),
      title: "Shopping List");
}

Future<void> _update() async {
  await shoppingListModel.refresh();
}

void _showAddShoppingItemDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddShoppingItemDialog(),
  );
}

void _showEditShoppingItemDialog(BuildContext context, int index, ShoppingItem item) {
  showDialog(
    context: context,
    builder: (context) => EditShoppingItemDialog(index: index, item: item),
  );
}

enum ShoppingCategory {
  groceries,
  household,
  electronics,
  clothing,
  health,
  other,
}

class ShoppingItem {
  final String name;
  final bool purchased;
  final ShoppingCategory category;
  final int? quantity;
  final DateTime createdAt;

  ShoppingItem({
    required this.name,
    this.purchased = false,
    this.category = ShoppingCategory.groceries,
    this.quantity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String toJson() {
    return jsonEncode({
      'name': name,
      'purchased': purchased,
      'category': category.index,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static ShoppingItem fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ShoppingItem(
      name: map['name'] as String,
      purchased: map['purchased'] as bool,
      category: ShoppingCategory.values[map['category'] as int],
      quantity: map['quantity'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ShoppingItem copyWith({
    String? name,
    bool? purchased,
    ShoppingCategory? category,
    int? quantity,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      name: name ?? this.name,
      purchased: purchased ?? this.purchased,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ShoppingListModel extends ChangeNotifier {
  List<ShoppingItem> _items = [];
  static const int maxItems = 30;
  static const String _itemsKey = 'ShoppingList.Items';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<ShoppingItem> get items => List.unmodifiable(_items);
  List<ShoppingItem> get unpurchasedItems => _items.where((i) => !i.purchased).toList();
  List<ShoppingItem> get purchasedItems => _items.where((i) => i.purchased).toList();
  int get length => _items.length;
  int get unpurchasedCount => unpurchasedItems.length;
  int get purchasedCount => purchasedItems.length;
  bool get isInitialized => _isInitialized;
  bool get hasItems => _items.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadItems();
    _isInitialized = true;
    Global.loggerModel.info("Shopping List initialized with ${_items.length} items", source: "ShoppingList");
    notifyListeners();
  }

  Future<void> _loadItems() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final itemsData = prefs.getStringList(_itemsKey);
    if (itemsData != null) {
      _items = itemsData.map((json) => ShoppingItem.fromJson(json)).toList();
    }
  }

  Future<void> _saveItems() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    try {
      final itemsData = _items.map((i) => i.toJson()).toList();
      await prefs.setStringList(_itemsKey, itemsData);
      Global.loggerModel.info("Saved ${_items.length} shopping items", source: "ShoppingList");
    } catch (e) {
      Global.loggerModel.error("Failed to save shopping items: $e", source: "ShoppingList");
    }
  }

  Future<void> refresh() async {
    await _loadItems();
    notifyListeners();
    Global.loggerModel.info("Shopping List refreshed", source: "ShoppingList");
  }

  void addItem(String name, ShoppingCategory category, int? quantity) {
    if (name.trim().isEmpty) return;
    
    _items.insert(0, ShoppingItem(
      name: name.trim(),
      category: category,
      quantity: quantity,
    ));
    
    if (_items.length > maxItems) {
      _items.removeLast();
    }
    
    notifyListeners();
    _saveItems();
    final preview = name.trim().length > 20 ? name.trim().substring(0, 20) : name.trim();
    Global.loggerModel.info("Added shopping item: $preview...", source: "ShoppingList");
  }

  void updateItem(int index, String name, ShoppingCategory category, int? quantity) {
    if (index < 0 || index >= _items.length) return;
    if (name.trim().isEmpty) {
      deleteItem(index);
      return;
    }
    
    _items[index] = _items[index].copyWith(
      name: name.trim(),
      category: category,
      quantity: quantity,
    );
    notifyListeners();
    _saveItems();
    Global.loggerModel.info("Updated shopping item at index $index", source: "ShoppingList");
  }

  void togglePurchased(int index) {
    if (index < 0 || index >= _items.length) return;
    
    _items[index] = _items[index].copyWith(
      purchased: !_items[index].purchased,
    );
    notifyListeners();
    _saveItems();
    Global.loggerModel.info("Toggled shopping item purchase at index $index", source: "ShoppingList");
  }

  void deleteItem(int index) {
    if (index < 0 || index >= _items.length) return;
    
    _items.removeAt(index);
    notifyListeners();
    _saveItems();
    Global.loggerModel.info("Deleted shopping item at index $index", source: "ShoppingList");
  }

  void clearPurchased() {
    _items = _items.where((i) => !i.purchased).toList();
    notifyListeners();
    _saveItems();
    Global.loggerModel.info("Cleared purchased shopping items", source: "ShoppingList");
  }

  void clearAllItems() {
    _items.clear();
    notifyListeners();
    _saveItems();
    Global.loggerModel.info("Cleared all shopping items", source: "ShoppingList");
  }
}

class ShoppingListCard extends StatefulWidget {
  @override
  State<ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<ShoppingListCard> {
  @override
  Widget build(BuildContext context) {
    final shoppingList = context.watch<ShoppingListModel>();
    
    if (!shoppingList.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, size: 24),
              SizedBox(width: 12),
              Text("Shopping List: Loading..."),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Shopping List",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (shoppingList.purchasedCount > 0)
                      IconButton(
                        icon: Icon(Icons.cleaning_services, size: 18),
                        onPressed: () => _showClearPurchasedConfirmation(context),
                        tooltip: "Clear purchased",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (shoppingList.hasItems)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearAllConfirmation(context),
                        tooltip: "Clear all",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddShoppingItemDialog(context),
                      tooltip: "Add item",
                    ),
                  ],
                ),
              ],
            ),
            if (shoppingList.unpurchasedCount > 0 || shoppingList.purchasedCount > 0)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "${shoppingList.unpurchasedCount} to buy, ${shoppingList.purchasedCount} done",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            SizedBox(height: 8),
            if (!shoppingList.hasItems)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No items yet. Tap + to add.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: shoppingList.length,
                itemBuilder: (context, index) {
                  final item = shoppingList.items[index];
                  return _buildShoppingItem(context, index, item);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShoppingItem(BuildContext context, int index, ShoppingItem item) {
    final displayText = item.name.length > 40 ? '${item.name.substring(0, 40)}...' : item.name;
    final categoryColor = _getCategoryColor(context, item.category);
    final categoryIcon = _getCategoryIcon(item.category);
    final qty = item.quantity;
    final quantityText = qty != null && qty > 1 ? ' ($qty)' : '';
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              item.purchased ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: item.purchased 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => context.read<ShoppingListModel>().togglePurchased(index),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Icon(categoryIcon, size: 16, color: categoryColor),
        ],
      ),
      title: Text(
        displayText + quantityText,
        style: TextStyle(
          fontSize: 13,
          color: item.purchased 
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
            : null,
          decoration: item.purchased ? TextDecoration.lineThrough : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showEditShoppingItemDialog(context, index, item),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 16),
        onPressed: () => context.read<ShoppingListModel>().deleteItem(index),
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  
  Color _getCategoryColor(BuildContext context, ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return Theme.of(context).colorScheme.primary;
      case ShoppingCategory.household:
        return Theme.of(context).colorScheme.secondary;
      case ShoppingCategory.electronics:
        return Theme.of(context).colorScheme.tertiary;
      case ShoppingCategory.clothing:
        return Theme.of(context).colorScheme.error;
      case ShoppingCategory.health:
        return Colors.teal;
      case ShoppingCategory.other:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
  
  IconData _getCategoryIcon(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return Icons.local_grocery_store;
      case ShoppingCategory.household:
        return Icons.home;
      case ShoppingCategory.electronics:
        return Icons.devices;
      case ShoppingCategory.clothing:
        return Icons.checkroom;
      case ShoppingCategory.health:
        return Icons.medical_services;
      case ShoppingCategory.other:
        return Icons.more_horiz;
    }
  }
  
  Future<void> _showClearPurchasedConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Purchased"),
        content: Text("Remove all purchased items?"),
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
      context.read<ShoppingListModel>().clearPurchased();
    }
  }
  
  Future<void> _showClearAllConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Items"),
        content: Text("This will delete all shopping items. This action cannot be undone."),
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
      context.read<ShoppingListModel>().clearAllItems();
    }
  }
}

class AddShoppingItemDialog extends StatefulWidget {
  @override
  State<AddShoppingItemDialog> createState() => _AddShoppingItemDialogState();
}

class _AddShoppingItemDialogState extends State<AddShoppingItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  ShoppingCategory _selectedCategory = ShoppingCategory.groceries;
  
  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Shopping Item"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Item name...",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              hintText: "Quantity (optional)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text("Category: ", style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButton<ShoppingCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: ShoppingCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(_getCategoryIcon(cat), size: 16),
                          SizedBox(width: 8),
                          Text(_getCategoryName(cat)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (ShoppingCategory? newCategory) {
                    if (newCategory != null) {
                      setState(() => _selectedCategory = newCategory);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              int? quantity = int.tryParse(_quantityController.text.trim());
              context.read<ShoppingListModel>().addItem(_nameController.text, _selectedCategory, quantity);
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
  
  String _getCategoryName(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return "Groceries";
      case ShoppingCategory.household:
        return "Household";
      case ShoppingCategory.electronics:
        return "Electronics";
      case ShoppingCategory.clothing:
        return "Clothing";
      case ShoppingCategory.health:
        return "Health";
      case ShoppingCategory.other:
        return "Other";
    }
  }
  
  IconData _getCategoryIcon(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return Icons.local_grocery_store;
      case ShoppingCategory.household:
        return Icons.home;
      case ShoppingCategory.electronics:
        return Icons.devices;
      case ShoppingCategory.clothing:
        return Icons.checkroom;
      case ShoppingCategory.health:
        return Icons.medical_services;
      case ShoppingCategory.other:
        return Icons.more_horiz;
    }
  }
}

class EditShoppingItemDialog extends StatefulWidget {
  final int index;
  final ShoppingItem item;
  
  const EditShoppingItemDialog({
    required this.index,
    required this.item,
  });
  
  @override
  State<EditShoppingItemDialog> createState() => _EditShoppingItemDialogState();
}

class _EditShoppingItemDialogState extends State<EditShoppingItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late ShoppingCategory _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity?.toString() ?? '');
    _selectedCategory = widget.item.category;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Shopping Item"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Item name...",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              hintText: "Quantity (optional)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text("Category: ", style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButton<ShoppingCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: ShoppingCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(_getCategoryIcon(cat), size: 16),
                          SizedBox(width: 8),
                          Text(_getCategoryName(cat)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (ShoppingCategory? newCategory) {
                    if (newCategory != null) {
                      setState(() => _selectedCategory = newCategory);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            int? quantity = int.tryParse(_quantityController.text.trim());
            context.read<ShoppingListModel>().updateItem(widget.index, _nameController.text, _selectedCategory, quantity);
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
  
  String _getCategoryName(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return "Groceries";
      case ShoppingCategory.household:
        return "Household";
      case ShoppingCategory.electronics:
        return "Electronics";
      case ShoppingCategory.clothing:
        return "Clothing";
      case ShoppingCategory.health:
        return "Health";
      case ShoppingCategory.other:
        return "Other";
    }
  }
  
  IconData _getCategoryIcon(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return Icons.local_grocery_store;
      case ShoppingCategory.household:
        return Icons.home;
      case ShoppingCategory.electronics:
        return Icons.devices;
      case ShoppingCategory.clothing:
        return Icons.checkroom;
      case ShoppingCategory.health:
        return Icons.medical_services;
      case ShoppingCategory.other:
        return Icons.more_horiz;
    }
  }
}