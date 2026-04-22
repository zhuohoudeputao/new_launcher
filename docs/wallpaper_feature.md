# Wallpaper Feature Documentation

## Overview

The wallpaper feature allows users to set background images for the launcher from either local gallery or Picsum website.

## Implementation Details

### Provider

- **Name**: `Wallpaper`
- **Location**: `lib/providers/provider_wallpaper.dart`

### Sources

1. **Gallery** - Local images via image_picker
2. **Picsum** - Random images from picsum.photos

### Settings

- **WallpaperPicker** - Toggle for gallery picker
- **LastWallpaper** - Stores last used wallpaper URL

### Picsum URLs

```dart
final List<String> _wallpaperUrls = [
  "https://picsum.photos/1920/1080",
  "https://picsum.photos/1920/1080?random=1",
  // ...
];
```

## Flow

1. Check for saved wallpaper (`LastWallpaper`)
2. If exists, restore from saved URL
3. If not, fetch random Picsum image
4. Update background and save URL

### Commands

| Command | Action |
|---------|--------|
| refresh background | Fetch new Picsum image |
| wallpaper | Refresh background |

## Future Features

- Wallpaper picker UI
- Multiple wallpaper sources
- Wallpaper rotation
- Category-based selection