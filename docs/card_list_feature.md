# Card List Feature

## Overview

The card list displays information widgets in a vertically scrolling list. Each card represents an action, app, or info widget that can be triggered by the user.

## Implementation

### List Configuration

The card list uses a standard `ListView.builder` for displaying info widgets:

- `reverse: true` - Cards are displayed from bottom to top
- `cacheExtent: 500` - Cache extent for better performance
- `itemExtent: 80` - Fixed item extent for efficient scrolling
- `addAutomaticKeepAlives: false` - Disable to save memory
- `addRepaintBoundaries: true` - Enable for smoother scrolling
- `physics: BouncingScrollPhysics()` - Enable bounce effect at boundaries

### Card Display

- Cards are rendered in reverse order (newest at bottom)
- The list directly uses `InfoModel.getFilteredList(query)` as the item source
- Each item is a Widget from the infoList

### List Behavior

- Normal scroll behavior with start and end boundaries
- Users can scroll freely within the list bounds
- Search filtering dynamically updates the displayed cards