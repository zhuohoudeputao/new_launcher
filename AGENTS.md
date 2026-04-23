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
  - Current temperature, wind speed, weather condition
  - Location name display (city, country)
  - 3-day forecast (max/min temps, weather icon)
  - Manual refresh button
  - Cache for 30 minutes
  - Geocoding API for location name
  - Uses `Card.filled` for Material 3 style
- **Theme**: Manages Material 3 theme with dynamic colors
  - Uses `ColorScheme.fromSeed()` with Indigo seed color
  - Light/dark/system mode support
  - SegmentedButton for mode selection (Material 3 component)
  - Transparent card backgrounds with configurable opacity
- **Wallpaper**: Background image selection
  - WallpaperPickerButton uses Card.filled with IconButton.styleFrom()
- **Time**: Local time display with optional seconds
- **App**: App launcher with device_apps
  - `AllAppsCard`: Card.outlined with GridView (Material 3 secondary style)
  - `RecentlyUsedAppsCard`: Card.filled (Material 3 primary style)
  - `AppStatisticsCard`: Card.outlined with statistics display
  - RepaintBoundary and cacheWidth for icon performance
  - Models: `appModel`, `allAppsModel`, `appStatisticsModel`
- **System**: System-related actions
  - Quick launch: camera, settings, clock, calculator

## Material 3 Design System

The app uses Material 3 design system with the following components:

### Color Scheme
- Dynamic colors from `ColorScheme.fromSeed(seedColor: Colors.indigo)`
- Light and dark theme variants
- All hardcoded colors replaced with ColorScheme properties

### Card Variants
- `Card.filled()` - Primary content (search input, weather, recent apps)
- `Card.outlined()` - Secondary content (all apps, app statistics)
- Standard Card with `elevation: 0` - Settings items

### Buttons
- `ElevatedButton` with `elevation: 0` for suggestions (Material 3 tonal style)
- `SegmentedButton` for theme mode selection (new Material 3 component)

### Components Updated
- Theme mode selector uses SegmentedButton with icons
- Log viewer uses ColorScheme for level colors
- Settings page AppBar uses scrolledUnderElevation
- All IconButtons use IconButton.styleFrom() with ColorScheme

### Benefits
- Consistent visual hierarchy
- Dynamic color adaptation
- Modern Material 3 appearance
- Better accessibility compliance

See `docs/material3_upgrade.md` for detailed implementation guide.

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
- `MyProvider` class (constructor, initialization, SharedPreferences enabled check)
- `ActionModel` class (action storage, suggestion generation)
- `InfoModel` class (widget storage, filtering, batch operations)
- `ThemeModel` and `BackgroundImageModel` (notifications)
- `SettingsModel` class (save/load values, SharedPreferences integration)
- `AppStatisticsModel` class (launch tracking, sorting, entry limits, persistence)
- UI widget tests (`customInfoWidget`, `CustomBoolSettingWidget`, `AppStatisticsCard`, etc.)
- Material 3 component tests (SegmentedButton, Card.filled/outlined, ElevatedButton)
- ColorScheme integration tests (Material 3 enabled, color generation)

### Test Configuration
Tests use the following setup in `setUpAll()`:
- `SharedPreferences.setMockInitialValues({})` for SharedPreferences-dependent tests
- `TestWidgetsFlutterBinding.ensureInitialized()` for Flutter test framework
- `Global.backgroundImageModel.backgroundImage = AssetImage('test_assets/transparent.png')` to mock network images

Test assets are defined in `pubspec.yaml` under `flutter.assets`.

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
- `app_statistics_feature.md` - App usage statistics tracking and display
- `material3_upgrade.md` - Material 3 implementation guide
- `skipped_tests_fix.md` - Fix for SharedPreferences-dependent tests
- `grid_overflow_fix.md` - Fix for AllAppsCard GridView overflow

## Notice
DO NOT EDIT task*.md