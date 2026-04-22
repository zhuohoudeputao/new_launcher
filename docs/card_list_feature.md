# Card List Feature

## Overview

The card list displays information widgets in a vertically scrolling list. Each card represents an action, app, or info widget that can be triggered by the user.

## Implementation

### Circular Scrolling

The card list supports circular scrolling, allowing users to scroll infinitely in both directions without reaching the end.

**Implementation Details:**

- `CircularListController` extends `ScrollController` to manage the circular behavior
- When the user scrolls near the boundaries, the scroll position is seamlessly wrapped to the opposite end
- Uses a flag `_isWrapping` to prevent recursive wrapping calls

```dart
class CircularListController extends ScrollController {
  int itemCount;
  double itemExtent;
  bool _isWrapping = false;

  void maybeWrap() {
    if (_isWrapping || itemCount == 0 || position.maxScrollExtent == 0) return;
    final extent = itemCount * itemExtent;
    final offset = position.pixels;
    
    if (offset >= extent - itemExtent * 2) {
      _isWrapping = true;
      jumpTo(offset - extent);
      _isWrapping = false;
    } else if (offset < itemExtent) {
      _isWrapping = true;
      jumpTo(offset + extent);
      _isWrapping = false;
    }
  }
}
```

**Key Points:**

1. `NotificationListener<ScrollNotification>` wraps the `ListView` to detect scroll updates
2. The `maybeWrap()` method is called on each scroll update
3. When approaching boundaries (within 2 item extents), the position is jumped to create the circular effect
4. The `_isWrapping` flag prevents infinite loops during the jump

### List Configuration

- `reverse: true` - Cards are displayed from bottom to top
- `cacheExtent: 500` - Cache extent for better performance
- `addAutomaticKeepAlives: false` - Disable to save memory
- `addRepaintBoundaries: false` - Disable for smoother scrolling
- `physics: BouncingScrollPhysics()` - Enable bounce effect at boundaries