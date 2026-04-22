# Wallpaper Feature Documentation

## Overview

The wallpaper feature allows users to set background images for the launcher from either local gallery or Picsum website. Wallpapers are persisted and restored on app startup without re-fetching.

## Implementation Details

### Provider

- **Name**: `Wallpaper`
- **Location**: `lib/providers/provider_wallpaper.dart`

### Sources

1. **Gallery** - Local images via image_picker, saved to app documents directory
2. **Picsum** - Random images from picsum.photos, URL stored in settings

### Settings

- **WallpaperType** - "network" or "file" indicating wallpaper source
- **LastWallpaper** - Stores network wallpaper URL (for Picsum)
- **WallpaperFile** - Stores file path for gallery-picked wallpapers

### Picsum URLs

```dart
final List<String> _wallpaperUrls = [
  "https://picsum.photos/1920/1080",
  "https://picsum.photos/1920/1080?random=1",
  // ...
];
```

## Flow

### On Startup (Init)

1. Check `WallpaperType` setting
2. If "network": Load from saved URL in `LastWallpaper`
3. If "file": Load from saved path in `WallpaperFile`
4. If no saved wallpaper: Do nothing (no auto-fetch on startup)

### When User Picks from Gallery

1. Copy image to app documents directory as `saved_wallpaper.jpg`
2. Set `WallpaperType` = "file"
3. Set `WallpaperFile` = file path
4. Update background image

### When User Refreshes Wallpaper

1. Fetch random image from Picsum
2. Set `WallpaperType` = "network"
3. Set `LastWallpaper` = URL
4. Update background image

### Commands

| Command | Action |
|---------|--------|
| refresh wallpaper | Fetch new Picsum image |

## Persistence

- Gallery wallpapers: Saved as file in `getApplicationDocumentsDirectory()/saved_wallpaper.jpg`
- Network wallpapers: URL saved in SharedPreferences
- Wallpaper persists across app restarts
- No automatic fetching on startup if wallpaper already saved