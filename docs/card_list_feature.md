# Card List Feature

## Overview

The card list displays information widgets in a vertically scrolling list. Each card represents an action, app, or info widget that can be triggered by the user.

## Implementation

### Circular Scrolling

The card list supports circular scrolling, allowing users to scroll infinitely in both directions without getting stuck. This is achieved using a virtual list approach.

**How it works:**

1. **Virtual Count**: The list uses `itemCount * 100` as the total count, creating a large virtual scroll range
2. **Index Mapping**: `getActualIndex(virtualIndex)` converts virtual indices to actual indices using modulo
3. **Initial Position**: Starts at the middle of the virtual list to allow scrolling both directions
4. **No Interrupting Jumps**: Scroll listener is removed to prevent interrupting user's scroll gesture

```dart
class CircularListController extends ScrollController {
  int _itemCount;
  final double itemExtent;
  static const int virtualMultiplier = 100;
  
  late int _virtualCount;
  bool _initialized = false;
  
  CircularListController({int itemCount = 1, this.itemExtent = 100}) 
      : _itemCount = itemCount == 0 ? 1 : itemCount {
    _virtualCount = _itemCount * virtualMultiplier;
  }
  
  int getActualIndex(int virtualIndex) {
    return virtualIndex % _itemCount;
  }
  
  void initPosition() {
    if (!hasClients || _initialized) return;
    final startPoint = (_itemCount * virtualMultiplier ~/ 2) * itemExtent;
    jumpTo(startPoint);
    _initialized = true;
  }
}
```

**Key Points:**

1. `virtualMultiplier = 100` creates a very large list (100x actual item count)
2. `initPosition()` jumps to the middle on first frame render
3. User can scroll freely without getting stuck - no jumps during scroll
4. `_initialized` flag prevents repeated position initialization
5. `itemCount` setter resets `_initialized` to false when items change

### List Configuration

- `reverse: true` - Cards are displayed from bottom to top
- `cacheExtent: 500` - Cache extent for better performance
- `addAutomaticKeepAlives: false` - Disable to save memory
- `addRepaintBoundaries: false` - Disable for smoother scrolling
- `physics: BouncingScrollPhysics()` - Enable bounce effect at boundaries