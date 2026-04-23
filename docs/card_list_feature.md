# Card List Feature

## Overview

The card list displays information widgets in a vertically scrolling list. Each card represents an action, app, or info widget that can be triggered by the user.

## Implementation

### Dynamic Card Sizing

The card list supports dynamic card heights, allowing each card to size itself based on its content. This prevents overflow issues when cards have varying content sizes.

**Key Changes:**
- Removed fixed `itemExtent` from ListView.builder
- Each card item is wrapped in a Container with padding
- Cards use `mainAxisSize: MainAxisSize.min` to size themselves dynamically

### List Configuration

The card list uses a standard `ListView.builder` for displaying info widgets:

- `reverse: true` - Cards are displayed from bottom to top
- `cacheExtent: 500` - Cache extent for better performance
- `addAutomaticKeepAlives: false` - Disable to save memory
- `addRepaintBoundaries: true` - Enable for smoother scrolling
- `physics: BouncingScrollPhysics()` - Enable bounce effect at boundaries

### Card Layout

```dart
ListView.builder(
  cacheExtent: 500,
  itemCount: infoList.length,
  itemBuilder: (BuildContext context, int index) {
    final widget = infoList[infoList.length - index - 1];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: widget,
    );
  },
  scrollDirection: Axis.vertical,
  reverse: true,
  physics: BouncingScrollPhysics(),
)
```

### Card Types

Different card types have varying heights:
- **Simple cards** (InfoCard): ~72px with ListTile
- **Weather card**: Dynamic height with forecast section
- **App Statistics card**: Dynamic height with ListView of stats
- **All Apps card**: 120px fixed height GridView
- **Recent Apps card**: 80px fixed height horizontal ListView
- **Log viewer**: ~280px with fixed 200px log area

### Benefits

- No overflow errors for cards with more content
- Better visual hierarchy with proper spacing
- Flexible layout for different content types
- Consistent 8px horizontal and 4px vertical padding between cards