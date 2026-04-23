# Bookmarks Provider Implementation

## Overview

The Bookmarks provider provides a quick URL/bookmark manager for the launcher, allowing users to save, organize, and quickly access frequently used websites.

## Features

- Add, edit, and delete bookmarks
- Open bookmarks in external browser
- Auto-normalize URLs (adds https:// if missing)
- Auto-extract title from URL domain
- Maximum 15 bookmarks stored (oldest removed when limit exceeded)
- Bookmarks persisted via SharedPreferences
- Long press to edit, tap to open
- Clear all bookmarks with confirmation dialog

## Implementation Details

### File Structure

- `lib/providers/provider_bookmarks.dart` - Main provider implementation

### Model

`BookmarksModel` extends `ChangeNotifier` and manages:
- List of `Bookmark` objects (url + title)
- Maximum 15 bookmarks limit
- SharedPreferences persistence

### Bookmark Class

```dart
class Bookmark {
  final String url;
  final String title;
  
  Bookmark({required this.url, required this.title});
  
  // Serialization methods
  Map<String, dynamic> toMap();
  factory Bookmark.fromMap(Map<String, dynamic> map);
  String toJson();
  factory Bookmark.fromJson(String json);
}
```

### Key Methods

- `addBookmark(String url, String title)` - Add new bookmark with auto-normalization
- `updateBookmark(int index, String url, String title)` - Edit existing bookmark
- `deleteBookmark(int index)` - Remove bookmark
- `clearAllBookmarks()` - Remove all bookmarks
- `openBookmark(int index)` - Open bookmark in external browser
- `_normalizeUrl(String url)` - Add https:// prefix if missing
- `_extractTitleFromUrl(String url)` - Extract domain name as title

### UI Components

#### BookmarksCard
- Material 3 `Card.filled` style
- Shows list of bookmarks with title and URL
- Add button (+ icon) in header
- Clear all button (when bookmarks exist)
- Empty state message when no bookmarks

#### AddBookmarkDialog
- URL input field (required)
- Title input field (optional)
- Auto-normalizes URL on save
- Auto-extracts title from URL if not provided

#### EditBookmarkDialog
- Pre-filled with existing bookmark data
- Same fields as AddBookmarkDialog
- Updates bookmark on save

### URL Opening

Uses `url_launcher` package:
```dart
await launchUrl(uri, mode: LaunchMode.externalApplication);
```

Opens bookmarks in the system's default browser.

### Keywords

`bookmark bookmarks url link website save quick`

## Usage

### Adding a Bookmark

1. Tap the + button in the BookmarksCard header
2. Enter URL (e.g., "example.com" or "https://example.com")
3. Optionally enter a title (auto-generated from domain if omitted)
4. Tap Save

### Opening a Bookmark

- Tap any bookmark entry to open in external browser

### Editing a Bookmark

- Long press a bookmark entry to edit

### Deleting a Bookmark

- Tap the X icon on the right side of any bookmark

### Clearing All Bookmarks

- Tap the trash icon in the header when bookmarks exist
- Confirm the deletion in the dialog

## Dependencies

- `url_launcher: ^6.3.0` - Opens URLs in external browser
- `shared_preferences: ^2.0.0` - Persists bookmarks locally

## Testing

Tests cover:
- Provider existence in Global.providerList
- Keywords validation
- BookmarksModel initialization state
- Bookmark class serialization
- CRUD operations (add, update, delete, clear)
- URL normalization
- Title extraction from URL
- Maximum limit enforcement
- Widget rendering (loading, empty, populated states)
- Dialog widgets existence

## Design Considerations

1. **URL Normalization**: Automatically adds "https://" prefix to ensure valid URLs
2. **Title Extraction**: Generates human-readable title from domain name when not provided
3. **Limit Enforcement**: Oldest bookmarks removed when exceeding 15 limit
4. **Material 3**: Uses `Card.filled` for consistent styling
5. **External Browser**: Opens in system browser for full functionality