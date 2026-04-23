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
- **Card list**: Standard ListView.builder displays info cards with dynamic sizing
  - Pull-to-refresh gesture triggers all provider refreshes via `RefreshIndicator`
  - Uses `AlwaysScrollableScrollPhysics` for consistent scroll behavior
- **Search input**: `SearchTextField` widget manages search field with clear button
- **Providers system**: `lib/providers/*.dart` - Each provider adds services (weather, apps, wallpaper, etc.)
- **Data layer**: `lib/data.dart` - Contains `Global`, `ActionModel`, `InfoModel`, `SettingsModel`, `BackgroundImageModel`, `ThemeModel`
  - `InfoModel.addInfoWidgetsBatch()`: Batch add widgets with single notifyListeners for performance
- **Action definition**: `lib/action.dart` - `MyAction` class with keywords and action function

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
- `ActionModel.updateSearchQuery(input)` updates the search query with debouncing
- `InfoModel.getFilteredList(query)` returns cards matching the query
- Pass `title` parameter to `addInfoWidget()` to make cards searchable by title
- Filtering matches against both key and title (case-insensitive)
- `SearchTextField` widget provides clear button for quick input reset
  - Clear button appears when text is present
  - Tapping clear removes text and dismisses keyboard

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

- **Settings**: Launcher configuration displayed in main list
  - `DarkModeOptionSelector`: Theme mode selection (Light/Dark/System) using SegmentedButton
  - `CardOpacitySlider`: Card transparency slider (0.1-1.0)
  - `WallpaperPickerButton`: Background image picker
  - All settings directly visible in main card list (no secondary page)
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
  - `AllAppsCard`: Card.outlined with GridView (120px height, horizontal scroll)
  - `RecentlyUsedAppsCard`: Card.filled (80px height, horizontal ListView)
  - `AppStatisticsCard`: Card.outlined with dynamic height statistics display
    - Clear button with confirmation dialog to reset usage history
    - Button only visible when statistics exist
  - RepaintBoundary and cacheWidth for icon performance
  - Models: `appModel`, `allAppsModel`, `appStatisticsModel`
  - Requires `QUERY_ALL_PACKAGES` permission for Android 11+ to enumerate all apps
  - Uses `onlyAppsWithLaunchIntent: true` to filter out non-launchable apps
- **System**: System-related actions
  - Quick launch: camera, settings, clock, calculator
  - Date/time settings: opens Android settings with guidance
  - View logs: displays app log viewer
- **Battery**: Device battery status display
  - Battery level percentage
  - Charging state (charging, discharging, full, connected not charging)
  - Dynamic battery icon based on level
  - Color indication (green >50%, orange 20-50%, red <20%)
  - Real-time battery state updates
  - Manual refresh button
  - Uses `Card.filled` for Material 3 style
- **Notes**: Quick notes for storing text snippets
  - Add, edit, and delete notes
  - Maximum 10 notes stored (oldest removed when limit exceeded)
  - Notes persisted via SharedPreferences
  - Clear all notes button with confirmation dialog
  - Uses `Card.filled` for Material 3 style
  - Keywords: note, notes, text, memo, clipboard, write, quick

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
- All cards explicitly use `color: Theme.of(context).cardColor` for transparency support
- Cards use `mainAxisSize: MainAxisSize.min` for dynamic sizing to prevent overflow
- Standalone functions use Builder widget to access Theme context

### Buttons
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
- `http: ^1.0.0` - HTTP requests
- `device_apps: ^2.2.0` - App enumeration and launching
- `geolocator: ^11.1.0` - Location services for weather
- `image_picker: ^1.0.0` - Wallpaper selection
- `path_provider: ^2.0.0` - File system paths
- `battery_plus: ^6.0.0` - Battery status

## Testing

Tests are located in `test/widget_test.dart`. Run tests with:
```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY && ~/app/flutter/bin/flutter test
```

Test coverage includes:
- `MyAction` class (keyword matching, frequency tracking, midnight safety)
- `MyProvider` class (constructor, initialization, SharedPreferences enabled check)
- `ActionModel` class (action storage, search query updates, debouncing)
- `InfoModel` class (widget storage, filtering, batch operations)
- `ThemeModel` and `BackgroundImageModel` (notifications)
- `SettingsModel` class (save/load values, SharedPreferences integration)
- `AppStatisticsModel` class (launch tracking, sorting, entry limits, persistence)
- UI widget tests (`customInfoWidget`, `CustomBoolSettingWidget`, `AppStatisticsCard`, etc.)
- Material 3 component tests (SegmentedButton, Card.filled/outlined, ElevatedButton)
- ColorScheme integration tests (Material 3 enabled, color generation)
- System provider action tests (camera, clock, calculator, settings, logs keywords)
- MyHomePage structure tests (PopScope, TextField, Card, CircularListController)
- MyApp structure tests (Material 3 theme, navigatorKey)
- Search results indicator tests (filtering, count format, pluralization)
- SearchTextField tests (rendering, clear button visibility and behavior)
- Pull-to-refresh tests (RefreshIndicator, scroll physics, provider refresh)
- Battery provider tests (provider existence, keywords, model state, widget rendering)
- Notes provider tests (provider existence, keywords, model state, CRUD operations)

Total tests: ~307 tests

### Test Configuration
Tests use the following setup in `setUpAll()`:
- `SharedPreferences.setMockInitialValues({})` for SharedPreferences-dependent tests
- `TestWidgetsFlutterBinding.ensureInitialized()` for Flutter test framework
- `Global.backgroundImageModel.backgroundImage = AssetImage('test_assets/transparent.png')` to mock network images

Test assets are defined in `pubspec.yaml` under `flutter.assets`.

## Documentation

Technical documentation is available in `docs/`:
- `automatic_loop.md` - Automatic development loop process
- `critical_bug_fixes.md` - Bug fixes and code cleanup history
- `search_feature.md` - Search feature implementation
- `search_clear_button.md` - Search clear button widget implementation
- `search_results_pluralization.md` - Search results pluralization fix
- `settings_provider.md` - Settings provider implementation
- `flatten_settings.md` - Flatten settings to main card list
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
- `test_coverage_update.md` - Additional tests for improved coverage
- `date_time_settings.md` - System date/time settings action
- `app_statistics_clear.md` - Clear statistics button feature
- `pull_to_refresh.md` - Pull-to-refresh feature implementation
- `battery_provider.md` - Battery status provider implementation
- `notes_provider.md` - Notes provider implementation

## Notice
DO NOT EDIT task*.md

### Network Connection

```shell
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
```