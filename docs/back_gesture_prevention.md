# Back Gesture Prevention

## Overview

This launcher prevents the back gesture from closing the app, since a launcher should always remain in the foreground.

## Implementation

Uses `PopScope` with `canPop: false` to completely prevent the back gesture:

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    // Launcher should never pop - this is intentional
  },
  child: // Main UI
);
```

## Key Points

1. `canPop: false` - Always prevents popping from this screen
2. `onPopInvokedWithResult` - Empty callback since popping never happens
3. The `_lastReturn` field was removed as it's no longer needed