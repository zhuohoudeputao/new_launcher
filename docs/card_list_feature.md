# Card List Feature

## Overview

The card list displays information widgets in a vertically scrolling list. Each card represents an action, app, or info widget that can be triggered by the user.

## Implementation

### Circular Scrolling

The card list supports circular scrolling, allowing users to scroll infinitely in both directions without reaching the end. This is achieved using a virtual list approach.

**How it works:**

1. **Virtual Count**: The list uses `itemCount * 100` as the total count, creating a large virtual scroll range
2. **Index Mapping**: `getActualIndex(virtualIndex)` converts virtual indices to actual indices using modulo
3. **Wrap on Scroll**: When scrolling near boundaries, the position jumps to the middle to create infinite scrolling illusion

```dart
class CircularListController extends ScrollController {
  int _itemCount;
  final double itemExtent;
  static const int virtualMultiplier = 100;
  
  late int _virtualCount;
  
  CircularListController({int itemCount = 1, this.itemExtent = 100}) 
      : _itemCount = itemCount == 0 ? 1 : itemCount {
    _virtualCount = _itemCount * virtualMultiplier;
  }
  
  int get itemCount => _itemCount;
  
  int get virtualCount => _virtualCount;
  
  int getActualIndex(int virtualIndex) {
    return virtualIndex % _itemCount;
  }
  
  void onScroll() {
    if (!hasClients || _itemCount == 0) return;
    final maxExtent = _virtualCount * itemExtent;
    final current = position.pixels;
    final halfPoint = (_itemCount ~/ 2) * itemExtent;
    
    if (current >= maxExtent - itemExtent * 4) {
      jumpTo(halfPoint);
    } else if (current < itemExtent * 2) {
      jumpTo(halfPoint);
    }
  }
}
```

**Key Points:**

1. `itemExtent = 100` by default, representing average card height
2. Listener attached to `_circularListController` calls `onScroll()` on each scroll event
3. When approaching 95% of the virtual list, jumps to the middle section
4. When near the start, also jumps to the middle to maintain continuous scrolling

### List Configuration

- `reverse: true` - Cards are displayed from bottom to top
- `cacheExtent: 500` - Cache extent for better performance
- `addAutomaticKeepAlives: false` - Disable to save memory
- `addRepaintBoundaries: false` - Disable for smoother scrolling
- `physics: BouncingScrollPhysics()` - Enable bounce effect at boundaries