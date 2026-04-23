# GridView Overflow Fix

## Problem

The `AllAppsCard` widget caused a `RenderFlex overflowed by 52 pixels on the bottom` error during app runtime.

## Root Cause

The `AllAppsCard` uses a horizontal `GridView.builder` with the following configuration:

```dart
Container(
  height: 120,
  child: GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 5,
      childAspectRatio: 0.8,
    ),
    scrollDirection: Axis.horizontal,
    ...
  ),
)
```

For a horizontal GridView:
- `crossAxisCount` = number of rows (vertical direction)
- Container height: 120px
- Each row height = 120 / 5 = **24px**

However, each grid cell contains a Column with:
- App icon: 48px height
- SizedBox: 4px
- App name text: ~10-12px
- **Total minimum height: ~62-64px**

This caused each row (24px) to overflow by ~38-52 pixels.

## Solution

Changed `crossAxisCount` from 5 to 2:

```dart
crossAxisCount: 2,
```

This gives each row a height of 120 / 2 = **60px**, which provides adequate space for the app icon and text.

## Impact

- Before: Continuous overflow errors during app rendering
- After: No overflow errors, apps display correctly in 2 rows

## Implementation Date

2026-04-23