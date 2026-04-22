# AGENTS.md

## Project Overview

Flutter-based Android launcher with a command-based interface. Users type commands in a text field to trigger actions. Info widgets display in a list.

## Key Commands

```bash
~/app/flutter/bin/flutter run              # Run app on connected device/emulator
~/app/flutter/bin/flutter build apk        # Build debug APK
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && ~/app/flutter/bin/flutter test  # Run tests (unset proxy first)
```

## Build Configuration

### Required Android Settings
Add to `android/gradle.properties`:
```properties
android.useAndroidX=true
android.enableJetifier=true
```

### Flutter SDK Path
Set in `android/local.properties`:
```properties
flutter.sdk=/home/linzuxuan/app/flutter
```

**Note**: The system Flutter (`/usr/lib/flutter`) has gradle cache issues. Use the local flutter at `~/app/flutter` instead.

## Architecture

- **Entry point**: `lib/main.dart` - `MyApp` widget wraps `MyHomePage`
- **Card list**: `CircularListController` in main.dart handles circular scrolling
- **Providers system**: `lib/providers/*.dart` - Each provider adds services (weather, apps, wallpaper, etc.)
- **Data layer**: `lib/data.dart` - Contains `Global`, `ActionModel`, `InfoModel`, `SettingsModel`, `BackgroundImageModel`, `ThemeModel`
  - `InfoModel.addInfoWidgetsBatch()`: Batch add widgets with single notifyListeners for performance
- **Action definition**: `lib/action.dart` - `MyAction` class with keywords, action function, and suggest widget

## Adding a New Provider

1. Create `lib/providers/provider_<name>.dart`
2. Create a `MyProvider` instance with:
   - `name`: UpperCase identifier (used for settings key: `name.Enabled`)
   - `provideActions`: Register `MyAction` objects via `Global.addActions()`
   - `initActions`: Add initial info widgets via `Global.infoModel.addInfoWidget()`
   - `update`: Handle settings changes
3. Add provider to `Global.providerList` in `lib/data.dart`

## Provider Pattern Example

```dart
MyProvider providerExample = MyProvider(
  name: "Example",
  provideActions: () {
    Global.addActions([
      MyAction(
        name: "Command Name",
        keywords: "search keywords",
        action: () {
          Global.infoModel.addInfo("key", "Title", subtitle: "Subtitle");
        },
        times: List.generate(24, (_) => 0),
      ),
    ]);
  },
  initActions: () {
    Global.infoModel.addInfoWidget("WidgetKey", MyWidget(), title: "Display Name");
  },
  update: () { /* handle settings change */ },
);
```

## Search Feature

The search feature filters info cards based on user input:
- `ActionModel.searchQuery` stores the current search text
- `InfoModel.getFilteredList(query)` returns cards matching the query
- Pass `title` parameter to `addInfoWidget()` to make cards searchable by title
- Filtering matches against both key and title (case-insensitive)

## Settings Storage

Settings auto-saved via `SharedPreferences`:
- `Global.getValue(key, defaultValue)` - Read
- `Global.settingsModel.saveValue(key, value)` - Write
- Boolean settings auto-generate toggle UI

## Known Issues

- System proxy configuration may cause Flutter test failures - unset proxy env vars before running tests

### Build Troubleshooting

- **Kotlin compiler session errors**: Use local Flutter SDK at `~/app/flutter`, not system Flutter
- **AndroidX not enabled**: Add `android.useAndroidX=true` to `android/gradle.properties`

## Providers

- **Weather**: Fetches weather using Open-Meteo API with geolocator
- **Theme**: Manages card colors, dark mode, transparency
- **Wallpaper**: Background image selection
- **Time**: Local time display
- **App**: App launcher with device_apps
  - `AllAppsCard`: Horizontal GridView showing all installed apps (compact view)
  - `RecentlyUsedAppsCard`: Shows recently launched apps
  - Top 20 apps displayed as individual cards for quick access (performance optimized)
  - ListView uses itemExtent and repaintBoundaries for smooth scrolling
  - Models registered as providers: `appModel`, `allAppsModel`
- **System**: System-related actions

## Dependencies

Key packages (pubspec.yaml):
- `provider: ^6.0.0` - State management
- `shared_preferences: ^2.0.0` - Settings storage
- `url_launcher: ^6.0.0` - Open URLs
- `sqflite: ^2.0.0` - Database (unused)
- `permission_handler: ^10.0.0` - Permissions
- `http: ^1.0.0` - HTTP requests
- `device_apps: ^2.2.0` - App enumeration and launching

## Testing

Tests are located in `test/widget_test.dart`. Run tests with:
```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && ~/app/flutter/bin/flutter test
```

Test coverage includes:
- `MyAction` class (keyword matching, frequency tracking, midnight safety)
- `MyProvider` class (constructor, initialization)
- `ActionModel` class (action storage, suggestion generation)
- `InfoModel` class (widget storage, filtering, batch operations)
- `ThemeModel` and `BackgroundImageModel` (notifications)
- UI widget tests (`customInfoWidget`, `CustomBoolSettingWidget`, etc.)

## Documentation

Technical documentation is available in `docs/`:
- `critical_bug_fixes.md` - Bug fixes and code cleanup history
- `search_feature.md` - Search feature implementation
- `theme_feature.md` - Theme management
- `wallpaper_feature.md` - Wallpaper handling
- `weather_service.md` - Weather API integration
- `logging_system.md` - Logging model usage
- `card_list_feature.md` - Circular list implementation
- `app_card_feature.md` - App display cards

## Notice
DO NOT EDIT task*.md