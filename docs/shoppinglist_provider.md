# Shopping List Provider

## Overview

The Shopping List provider enables quick shopping list management directly from the launcher. Users can add items to their shopping list, mark items as purchased, organize by categories, and track quantities.

## Features

- **Item management**: Add, edit, and delete shopping items
- **Purchase tracking**: Mark items as purchased/unpurchased
- **Quantity tracking**: Optional quantity per item
- **Categories**: 6 predefined categories with icons
- **Maximum storage**: 30 items stored (oldest removed when limit exceeded)
- **Persistence**: Items saved via SharedPreferences

## Implementation

### Model: ShoppingListModel

Located in `lib/providers/provider_shoppinglist.dart`.

```dart
class ShoppingListModel extends ChangeNotifier {
  List<ShoppingItem> _items = [];
  static const int maxItems = 30;
  bool _isInitialized = false;
  
  List<ShoppingItem> get items => List.unmodifiable(_items);
  List<ShoppingItem> get unpurchasedItems => _items.where((i) => !i.purchased).toList();
  List<ShoppingItem> get purchasedItems => _items.where((i) => i.purchased).toList();
  int get unpurchasedCount => unpurchasedItems.length;
  int get purchasedCount => purchasedItems.length;
}
```

### Data Model: ShoppingItem

```dart
class ShoppingItem {
  final String name;
  final bool purchased;
  final ShoppingCategory category;
  final int? quantity;
  final DateTime createdAt;
}

enum ShoppingCategory {
  groceries,    // 🛒
  household,    // 🏠
  electronics,  // 📱
  clothing,     // 👕
  health,       // 💊
  other,        // ⋯
}
```

### Card Widget: ShoppingListCard

- Material 3 `Card.filled` style
- Loading state indicator
- Empty state message
- Item list with purchase toggle
- Add, clear purchased, and clear all buttons

### Dialog Widgets

- `AddShoppingItemDialog`: Add new item with name, category, quantity
- `EditShoppingItemDialog`: Edit existing item

## Usage

### Adding an Item

```dart
model.addItem('Milk', ShoppingCategory.groceries, 2);
// Adds "Milk (2)" to the list
```

### Toggling Purchase Status

```dart
model.togglePurchased(index);
// Marks item as purchased or unpurchased
```

### Clearing Purchased Items

```dart
model.clearPurchased();
// Removes all purchased items from the list
```

### Deleting an Item

```dart
model.deleteItem(index);
```

## Keywords

The provider responds to these keywords:
- `shopping`
- `list`
- `shop`
- `buy`
- `grocery`
- `market`
- `item`
- `add`
- `cart`

## Dependencies

- `shared_preferences`: For persistence
- `provider`: For state management

## Categories

Each category has a unique icon and color:

| Category | Icon | Description |
|----------|------|-------------|
| Groceries | 🛒 | Food and household essentials |
| Household | 🏠 | Home items |
| Electronics | 📱 | Tech and gadgets |
| Clothing | 👕 | Apparel |
| Health | 💊 | Medical and health items |
| Other | ⋯ | Miscellaneous |

## Testing

The provider includes comprehensive tests:
- Model initialization
- Add, update, delete operations
- Toggle purchase status
- Category handling
- Persistence and loading
- Widget rendering tests
- Dialog tests

See `test/widget_test.dart` under "Shopping List provider tests" group.