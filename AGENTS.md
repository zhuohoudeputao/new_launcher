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

### Minimum SDK Version
The app requires Android 6.0 (API 23) or higher due to the `torch_light` plugin requirement. This is set in `android/app/build.gradle`:
```gradle
minSdkVersion 23
```

See `docs/min_sdk_version_fix.md` for details.

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
  - All apps now displayed as info widgets in main list (no limit)
  - Text overflow handling for long app/package names
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
- **Flashlight**: Quick flashlight toggle control
  - On/off status display
  - Toggle switch for quick activation
  - Availability check for devices without flashlight
  - Uses `Card.filled` for Material 3 style
  - Keywords: flashlight, torch, light, flash, lamp, toggle
- **Timer**: Countdown timer functionality
  - Quick preset timers (1, 5, 10, 15, 30 minutes)
  - Custom timer input
  - Pause/resume timer controls
  - Clear all timers with confirmation
  - Timer completion notification via SnackBar
  - Maximum 5 concurrent timers
  - Circular progress indicator for countdown
  - Uses `Card.filled` for Material 3 style
  - Keywords: timer, countdown, alarm, clock, time
- **Stopwatch**: Elapsed time tracking functionality
  - Start/pause/resume controls
  - Lap recording with time splits (max 20 laps)
  - Lap history view toggle
  - Reset with confirmation dialog
  - 10ms precision display (MM:SS.ms format)
  - Uses `Card.filled` for Material 3 style
  - Keywords: stopwatch, lap, elapsed, time, clock
- **Notes**: Quick notes for storing text snippets
  - Add, edit, and delete notes
  - Maximum 10 notes stored (oldest removed when limit exceeded)
  - Notes persisted via SharedPreferences
  - Clear all notes button with confirmation dialog
  - Uses `Card.filled` for Material 3 style
  - Keywords: note, notes, text, memo, clipboard, write, quick
- **Calculator**: Quick calculations directly in launcher
  - Basic arithmetic operations (+, -, ×, ÷)
  - Percentage and sign toggle
  - Calculation history (up to 10 entries)
  - Tap history entries to reuse results
  - Clear history button with confirmation dialog
  - Uses `Card.filled` for Material 3 style
  - Keywords: calc, calculator, math, calculate, equal
- **WorldClock**: Multiple timezone display
   - Shows time in up to 10 configured timezones
   - Day/night icon indicators (sun/moon)
   - Time period labels (morning, afternoon, evening, night)
   - Add timezone via dialog with (+) button
   - Remove timezone by swipe gesture or long press
   - Default timezones: New York, London, Tokyo
   - 14 supported timezones worldwide
   - Uses `Card.filled` for Material 3 style
   - Keywords: world, clock, timezone, time, zone, add, remove
- **Countdown**: Event countdown tracking
    - Track countdowns to important dates
    - Add countdowns with name and target date
    - Optional time selection (hours/minutes)
    - Edit and delete countdowns
    - Maximum 10 countdowns stored
    - Countdowns persisted via SharedPreferences
    - Human-readable time display (days, hours, minutes)
    - Expired countdown indication
    - Color coding for urgency (days < 7 shows warning color)
    - Uses `Card.filled` for Material 3 style
    - Keywords: countdown, deadline, birthday, event, date, add
- **UnitConverter**: Quick unit conversions
    - Three categories: Temperature, Length, Weight
    - Temperature units: Celsius, Fahrenheit, Kelvin
    - Length units: Meter, Kilometer, Centimeter, Millimeter, Inch, Foot, Mile, Yard
    - Weight units: Kilogram, Gram, Milligram, Pound, Ounce
    - Real-time conversion as you type
    - Swap input/output units with one tap
    - Conversion history (up to 10 entries)
    - Tap history entries to reuse conversions
    - Clear history button with confirmation dialog
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: convert, unit, temperature, length, weight, cm, m, km, inch, foot, mile, celsius, fahrenheit, kg, lb, gram, ounce
- **Pomodoro**: Productivity timer using Pomodoro Technique
    - Work sessions (default 25 minutes)
    - Short breaks (5 minutes after each work session)
    - Long breaks (15 minutes after 4 work sessions)
    - Circular progress indicator
    - Completed session counter
    - Pause/resume controls
    - Skip current phase option
    - Customizable durations via settings dialog
    - Session history (up to 20 entries)
    - Phase-specific colors and icons
    - Uses `Card.filled` and `CircularProgressIndicator` for Material 3 style
    - Keywords: pomodoro, timer, productivity, work, break, focus, session
- **Clipboard**: Clipboard history management
    - Track copied text snippets
    - Capture from system clipboard
    - Copy entries back to system clipboard
    - Add, delete, and clear entries
    - Maximum 15 entries stored (oldest removed when limit exceeded)
    - Entries persisted via SharedPreferences
    - Timestamp display (just now, Xm ago, Xh ago, Xd ago)
    - Uses `Card.filled` for Material 3 style
    - Keywords: clipboard, history, copy, paste, clip, text, snippet
- **Todo**: Task/todo list management
    - Add, edit, and delete tasks
    - Mark tasks as completed/incomplete
    - Priority levels (high, medium, low) with visual indicators
    - Maximum 20 tasks stored (oldest removed when limit exceeded)
    - Tasks persisted via SharedPreferences
    - Active/done count display
    - Clear completed tasks button
    - Clear all tasks with confirmation dialog
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: todo, task, list, check, done, complete, add, checklist
- **QRCode**: QR code generator
    - Generate QR codes from text input
    - Multiple input types: Text, URL, Email, Phone
    - URL auto-prefixing (adds https:// if missing)
    - Email and phone formatting (mailto:, tel:)
    - Copy text to clipboard
    - Clear QR code option
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Uses `QrImageView` from qr_flutter package
    - Keywords: qr, qrcode, code, generate, barcode, scan, share
- **Random**: Random generator utilities
    - Coin flip: heads or tails with one tap
    - Dice roll: D4, D6, D8, D10, D12, D20, D100 options
    - Random number: custom min/max range generator
    - Password generator: configurable length (4-64 chars)
    - Password options: lowercase, uppercase, numbers, symbols
    - Copy password to clipboard
    - Uses `Card.filled`, `SegmentedButton`, `Slider`, `FilterChip` for Material 3 style
    - Keywords: random, coin, dice, roll, flip, password, generate, number
- **Color**: Color generator utilities
    - Random color generation with one tap
    - HEX color input and display
    - RGB color input and display
    - Copy HEX/RGB values to clipboard
    - Color preview with contrast text
    - Light/dark color detection
    - Uses `Card.filled` and `SelectableText` for Material 3 style
    - Keywords: color, random, hex, rgb, picker, palette, generate
- **Currency**: Currency converter with real-time exchange rates
    - 20 supported currencies (USD, EUR, GBP, JPY, CNY, AUD, CAD, CHF, etc.)
    - Real-time rates from Frankfurter API
    - Swap currencies with one tap
    - Conversion history (up to 10 entries)
    - Rate caching for 1 hour
    - Manual refresh button
    - Uses `Card.filled` and `DropdownButton` for Material 3 style
    - Keywords: currency, exchange, rate, money, convert, dollar, euro, pound, yen, usd, eur, gbp, jpy, cny
- **Bookmarks**: Quick URL/bookmark manager
    - Add, edit, and delete bookmarks
    - Open bookmarks in external browser
    - Auto-normalize URLs (adds https:// if missing)
    - Auto-extract title from URL domain
    - Maximum 15 bookmarks stored (oldest removed when limit exceeded)
    - Bookmarks persisted via SharedPreferences
    - Long press to edit, tap to open
    - Clear all bookmarks with confirmation dialog
    - Uses `Card.filled` for Material 3 style
    - Keywords: bookmark, bookmarks, url, link, website, save, quick
- **Habit**: Daily habit tracking with streaks
    - Track daily habits with completion marking
    - Streak tracking for consecutive days
    - Best streak record for each habit
    - Tap to toggle completion status
    - Long press to edit or delete habits
    - Maximum 10 habits stored (oldest removed when limit exceeded)
    - Habits persisted via SharedPreferences
    - Daily streak reset if not completed previous day
    - Color coding for streak levels (7+ days green, 3-6 days yellow, <3 days gray)
    - Fire icon with streak count display
    - Uses `Card.filled` for Material 3 style
    - Keywords: habit, track, daily, routine, streak, goal, habit tracker
- **Meditation**: Meditation timer with breathing guide
    - Preset durations: 1, 3, 5, 10, 15, 20, 30 minutes
    - Optional breathing guide (4-4-4-4 pattern: Inhale, Hold, Exhale, Rest)
    - Start/pause/resume controls
    - Circular progress indicator
    - Session completion tracking
    - Total meditation time display
    - Session history (up to 20 entries)
    - Clear history with confirmation dialog
    - Uses `Card.filled`, `ActionChip`, `CircularProgressIndicator` for Material 3 style
    - Keywords: meditation, meditate, relax, breath, calm, focus, zen, mindfulness
- **Water**: Daily water intake tracker
    - Track daily water consumption in glasses
    - Daily goal setting (default 8 glasses, adjustable 1-20)
    - Progress bar with percentage visualization
    - Add/remove glasses with quick buttons
    - Goal reached celebration indicator
    - Daily automatic reset
    - History tracking for up to 30 days
    - Water intake persisted via SharedPreferences
    - Uses `Card.filled` and `LinearProgressIndicator` for Material 3 style
    - Keywords: water, drink, hydration, glass, cup, intake, track, daily, health
- **Mood**: Daily mood and emotional well-being tracker
    - Five mood levels: Very Sad, Sad, Neutral, Happy, Very Happy
    - Emoji-based visual representation (😢, 😔, 😐, 😊, 😄)
    - Positive streak tracking for consecutive positive days
    - Most common mood and average mood statistics
    - History tracking for up to 30 days
    - Mood entries persisted via SharedPreferences
    - History view with clear all option
    - Uses `Card.filled` and `showModalBottomSheet` for Material 3 style
    - Keywords: mood, emotion, feeling, happy, sad, track, daily, mental, health
- **Expense**: Daily expense tracker with categories
    - Track daily expenses with amounts and categories
    - 7 predefined categories: Food, Transport, Entertainment, Shopping, Bills, Health, Other
    - Emoji-based category icons (🍔, 🚗, 🎬, 🛍️, 📄, 💊, 📦)
    - Optional description/notes for each expense
    - Daily, weekly, and monthly totals display
    - History view showing recent expenses
    - Delete expenses by swipe gesture
    - Clear all expenses with confirmation dialog
    - Maximum 100 expenses stored (oldest removed when limit exceeded)
    - Expenses persisted via SharedPreferences
    - Uses `Card.filled` and `ChoiceChip` for Material 3 style
    - Keywords: expense, money, spend, cost, budget, track, finance, wallet
- **NumberBase**: Number base converter for programmers
    - Convert between binary, octal, decimal, and hexadecimal
    - Real-time conversion as you type
    - Input sanitization based on selected base
    - Swap input/output bases with one tap
    - Conversion history (up to 10 entries)
    - Tap history entries to reuse conversions
    - Clear history with confirmation dialog
    - Uses `Card.filled` and `DropdownButton` for Material 3 style
    - Keywords: convert, number, base, binary, octal, decimal, hex, hexadecimal, bin, oct, dec
- **Calendar**: Monthly calendar widget for date visualization
    - Full month calendar grid display
    - Navigate between months with left/right buttons
    - Today's date highlighted with primary color circle
    - Tap month title to return to current month
    - Week number display at bottom
    - Sunday dates shown in red color
    - Automatic day change at midnight
    - CalendarModel for state management (ChangeNotifier pattern)
    - Uses `Card.filled` for Material 3 style
    - Keywords: calendar, month, date, day, week, schedule
- **Progress**: Goal/project progress tracker
    - Track progress on goals with percentage visualization
    - Linear progress bar with color coding
    - Increment/decrement buttons for quick updates
    - Add, edit, and delete progress items
    - Maximum 15 progress items stored (oldest removed when limit exceeded)
    - Progress items persisted via SharedPreferences
    - Completed/total count display
    - Average progress calculation
    - Color coding for progress levels (100% green, 75%+ teal, 50%+ secondary)
    - Uses `Card.filled` and `LinearProgressIndicator` for Material 3 style
    - Keywords: progress, track, goal, project, percentage, completion, goal tracker
- **Anniversary**: Recurring event tracker for birthdays and anniversaries
    - Track recurring events like birthdays, anniversaries, holidays
    - Shows days until next occurrence
    - Optional year tracking for age/years count display
    - Add, edit, and delete anniversaries
    - Maximum 15 anniversaries stored (oldest removed when limit exceeded)
    - Anniversaries persisted via SharedPreferences
    - Human-readable time display (Today!, Tomorrow, X days, X weeks, X months)
    - Color coding for urgency (today shows celebration color)
    - Uses `Card.filled` for Material 3 style
    - Keywords: anniversary, birthday, recurring, event, date, add
- **Sleep**: Sleep duration and quality tracker
    - Track sleep hours (0-12 hours, 0.5-hour increments)
    - Five quality levels with emoji indicators: Terrible 😫, Poor 😴, Fair 😐, Good 😊, Excellent 😄
    - Optional notes for each sleep entry
    - Log sleep for custom dates (within 30 days)
    - Statistics: average hours, average quality, nights meeting 7-hour goal
    - Delete individual entries via history view
    - Clear all history with confirmation dialog
    - Maximum 30 entries stored (oldest removed when limit exceeded)
    - Sleep entries persisted via SharedPreferences
    - Uses `Card.filled` and `Slider` for Material 3 style
    - Keywords: sleep, rest, nap, bed, track, night, hours, quality, bedtime
- **Counter**: Multiple named counters for tracking
    - Create multiple named counters (up to 15)
    - Custom step values for increment/decrement (default: 1)
    - Increment (+) and decrement (-) buttons
    - Reset individual counters to zero
    - Edit counter name and step via long press
    - Delete counters via edit dialog
    - Total count display (sum of all counters)
    - Clear all counters with confirmation dialog
    - Counters persisted via SharedPreferences
    - Uses `Card.filled` for Material 3 style
    - Keywords: counter, count, tap, tally, number, increment, add, track
- **Tip**: Tip calculator for dining/bill splitting
    - Bill amount input with dollar prefix
    - Tip percentage selection (preset: 10%, 15%, 18%, 20%, 25%)
    - Custom tip percentage input
    - Split between 1-20 people with increment/decrement buttons
    - Real-time calculation: tip amount, total, per person, tip per person
    - Calculation history (up to 10 entries)
    - Tap history to restore previous calculations
    - Clear history with confirmation dialog
    - Uses `Card.filled`, `SegmentedButton`, `TextField` for Material 3 style
    - Keywords: tip, tipcalc, calculator, bill, restaurant, dining, split
- **BMI**: Body Mass Index calculator for health tracking
    - Unit system selection: Metric (kg/cm) or Imperial (lb/ft/in)
    - Real-time BMI calculation as values are entered
    - BMI categories: Underweight (<18.5), Normal (18.5-24.9), Overweight (25-29.9), Obese (>=30)
    - Color-coded results with category-specific colors
    - Calculation history (up to 10 entries)
    - Load previous calculations from history
    - Clear history with confirmation dialog
    - Uses `Card.filled`, `SegmentedButton`, `TextField` for Material 3 style
    - Keywords: bmi, body, mass, index, weight, height, health, calculator, metric, imperial
- **Metronome**: Visual beat indicator for musicians
    - Configurable BPM (20-300, default 120)
    - Visual beat indicator with accent highlight for first beat
    - Start/pause/stop controls
    - Tap tempo feature (tap to set BPM)
    - Preset BPM options (60, 80, 100, 120, 140, 160, 180)
    - Time signature support (2/4, 3/4, 4/4, 6/4, 8/4)
    - BPM history (up to 10 entries)
    - Circular beat indicator with current beat number display
    - Uses `Card.filled`, `SegmentedButton`, `ActionChip`, `FloatingActionButton` for Material 3 style
    - Keywords: metronome, beat, bpm, tempo, rhythm, music, tap, pulse
- **Flashcard**: Study tool for learning and memorization
    - Create multiple flashcard decks (up to 10 decks)
    - Add cards with front (question) and back (answer) to each deck (up to 50 cards per deck)
    - Study mode with card flipping and navigation
    - Mark cards as correct/incorrect for progress tracking
    - Accuracy percentage display for each deck
    - Edit and delete decks via long press
    - Add cards to specific decks
    - Clear all decks with confirmation dialog
    - Decks persisted via SharedPreferences
    - Uses `Card.filled` for Material 3 style
    - Keywords: flashcard, flash, cards, study, learn, memorize, quiz, deck, review
- **Workout**: Fitness and exercise tracking
    - 8 workout types: Running (🏃), Cycling (🚴), Weights (🏋️), Yoga (🧘), Swimming (🏊), Walking (🚶), HIIT (⚡), Other (💪)
    - Duration tracking (5-180 minutes with slider)
    - Optional notes for each session
    - Log workouts for custom dates (within 30 days)
    - Statistics: weekly/monthly total minutes, session count
    - History view with delete option (up to 100 entries)
    - Clear all workouts with confirmation dialog
    - Workouts persisted via SharedPreferences
    - Uses `Card.filled` and `Wrap` for Material 3 style
    - Keywords: workout, exercise, gym, fitness, run, cycle, swim, yoga, walk, training, log
- **Age**: Age calculator from birthdate
    - Calculate age in years, months, and days
    - Display total days lived
    - Western zodiac sign with emoji (Aries ♈, Taurus ♉, etc.)
    - Chinese zodiac sign with emoji (Rat 🐀, Ox 🐂, etc.)
    - Days until next birthday countdown
    - Birthday proximity indicator (warning color if <= 7 days)
    - Happy Birthday celebration message on birthday day
    - Save multiple birthdates for quick reference (up to 10 entries)
    - Load saved birthdates from history
    - Delete individual entries or clear all
    - Birthdates persisted via SharedPreferences
    - Uses `Card.filled` for Material 3 style
    - Keywords: age, birthday, birthdate, calculate, years, old, zodiac
- **Percentage**: Percentage calculator for quick calculations
    - Four calculation modes: X% of Y, X is what % of Y, Percentage Change, Discount
    - Real-time calculation as values are entered
    - Percentage of: calculates what X% of Y is (e.g., 20% of 100 = 20)
    - What percent: calculates what percentage X is of Y (e.g., 50 is 25% of 200)
    - Percentage change: calculates percentage increase/decrease (e.g., 100 to 150 = +50%)
    - Discount calculator: calculates final price after discount (e.g., 20% off $100 = $80)
    - Handles division by zero cases
    - Calculation history (up to 10 entries)
    - Tap history entries to reuse calculations
    - Clear history with confirmation dialog
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: percentage, percent, calc, discount, ratio, rate, %
- **QuickContacts**: Quick contacts for speed dial and messaging
    - Add frequently used contacts with name and phone number
    - Quick dial: tap contact to open phone dialer
    - Quick SMS: tap message icon to send SMS
    - Add, edit, and delete contacts
    - Maximum 15 contacts stored (oldest removed when limit exceeded)
    - Contacts persisted via SharedPreferences
    - Phone number normalization (removes dashes, spaces)
    - Long press to edit, tap to call
    - Clear all contacts with confirmation dialog
    - Uses `Card.filled` for Material 3 style
    - Keywords: contact, contacts, quick, dial, phone, call, speed, speeddial
- **ShoppingList**: Shopping list management
    - Add, edit, and delete shopping items
    - Mark items as purchased/unpurchased
    - Optional quantity tracking per item
    - 6 categories: Groceries, Household, Electronics, Clothing, Health, Other
    - Category-specific icons (🛒, 🏠, 📱, 👕, 💊, ⋯)
    - Maximum 30 items stored (oldest removed when limit exceeded)
    - Items persisted via SharedPreferences
    - To buy/done count display
    - Clear purchased items button
    - Clear all items with confirmation dialog
    - Uses `Card.filled` and `DropdownButton` for Material 3 style
    - Keywords: shopping, list, shop, buy, grocery, market, item, add, cart
- **Caffeine**: Daily caffeine intake tracker
    - Track daily caffeine consumption in milligrams (mg)
    - 8 preset drink options: Coffee (95mg), Espresso (64mg), Tea (26mg), Green Tea (28mg), Energy Drink (80mg), Cola (35mg), Diet Cola (46mg), Chocolate Bar (12mg)
    - Emoji-based drink icons (☕, 🍵, ⚡, 🥤, 🍫)
    - Custom caffeine amount input via dialog
    - Daily limit setting (default 400mg, adjustable 50-1000mg)
    - Progress bar with color coding (tertiary under limit, primary at limit, error over limit)
    - Over-limit warning indicator
    - History tracking for up to 30 days
    - Caffeine entries persisted via SharedPreferences
    - Uses `Card.filled` and `ActionChip` for Material 3 style
    - Keywords: caffeine, coffee, tea, energy, drink, cola, beverage, intake, track, daily, health
- **Subscription**: Subscription and recurring payment tracker
    - Track recurring subscriptions with name, cost, and renewal date
    - Three frequency options: Weekly, Monthly, Yearly
    - Monthly and yearly total cost calculation
    - Upcoming renewals sorted by urgency
    - Days until renewal display with color coding (red for 7 days, orange for 30 days)
    - Expired subscription detection with renewal button
    - Maximum 15 subscriptions stored (oldest removed when limit exceeded)
    - Subscriptions persisted via SharedPreferences
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: subscription, subscribe, bill, recurring, payment, netflix, spotify, membership, fee, monthly, yearly
- **Parking**: Parking location and meter tracker
    - Save parking location with custom description (e.g., "Level 2, Spot 15")
    - Optional notes for additional details (e.g., "Near elevator")
    - Parking meter countdown timer with expiration alert
    - Quick add time buttons (+15m, +30m, +60m, +90m, +120m)
    - Pause/resume meter timer controls
    - Linear progress indicator for meter time remaining
    - Parked duration display
    - Edit location and notes without resetting meter
    - Meter expiration notification via SnackBar
    - Color coding: primary for active meter, error for expired
    - Parking data persisted via SharedPreferences
    - Uses `Card.filled`, `ActionChip`, `LinearProgressIndicator` for Material 3 style
    - Keywords: parking, park, car, vehicle, meter, spot, location, level, garage
- **Gratitude**: Daily gratitude journal for mental health tracking
    - Record daily gratitude entries (up to 5 entries per day)
    - Streak tracking for consecutive days of gratitude logging
    - History view with expandable day entries
    - Delete individual entries via history view
    - Clear all history with confirmation dialog
    - Maximum 30 days of history stored
    - Entries persisted via SharedPreferences
    - Heart icon with pink color for visual appeal
    - Uses `Card.filled` for Material 3 style
    - Keywords: gratitude, grateful, thanks, thankful, appreciation, journal, daily, positive
- **Debt**: Debt/loan tracker for managing money owed
    - Track debts owed to you and debts owed by you
    - Optional due dates with overdue detection
    - Mark debts as paid/unpaid
    - Net balance calculation (owed to me - owed by me)
    - Overdue debt alerts with badge indicator
    - History view with all debt entries
    - Maximum 20 entries stored (oldest removed when limit exceeded)
    - Debt entries persisted via SharedPreferences
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: debt, loan, money, owe, borrow, lend, tracker, owed
- **IntervalTimer**: HIIT/Tabata workout interval timer
    - Preset workout intervals: Tabata (20s/10s), HIIT 30/10, HIIT 45/15, Circuit 60/30, EMOM
    - Custom work/rest durations (5-300s work, 0-120s rest)
    - Custom sets (1-20 rounds)
    - Work/rest phase indicators with color coding
    - Circular progress indicator for phase countdown
    - Total progress bar showing overall workout progress
    - Skip phase option to advance through intervals
    - Pause/resume/stop controls
    - Total time display
    - Uses `Card.filled`, `ActionChip`, `CircularProgressIndicator` for Material 3 style
    - Keywords: interval, timer, hiit, tabata, workout, circuit, training
- **TextEncoder**: Text encoding/decoding utilities for developers
    - Base64 encode/decode
    - URL encode/decode (percent-encoding)
    - HTML encode/decode (entity encoding)
    - JSON escape/unescape (string escaping)
    - Swap encode/decode operation with one tap
    - Real-time encoding as you type
    - Encoding history (up to 10 entries)
    - Tap history entries to reuse previous encodings
    - Clear history with confirmation dialog
    - Copy output to clipboard
    - Error handling for invalid input
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: encode, decode, base64, url, html, json, escape, text, string, convert
- **MorseCode**: Morse code encoder/decoder
    - Convert text to Morse code (dots and dashes)
    - Convert Morse code to text
    - Supports letters A-Z, numbers 0-9, and common punctuation
    - Space represented as '/' in Morse code
    - Swap encode/decode operation with one tap
    - Real-time conversion as you type
    - Conversion history (up to 10 entries)
    - Tap history entries to reuse previous conversions
    - Clear history with confirmation dialog
    - Copy output to clipboard
    - Unknown characters shown as '?' in output
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: morse, code, encode, decode, dot, dash, signal, telegraph, convert
- **Timestamp**: Unix timestamp converter
    - Convert Unix timestamp to readable datetime
    - Convert datetime string to Unix timestamp
    - Automatically detects milliseconds vs seconds timestamps
    - Use current timestamp with one tap
    - Swap timestamp/datetime input with one tap
    - Uses UTC timezone for consistent conversions
    - Conversion history (up to 10 entries)
    - Tap history entries to reuse conversions
    - Clear history with confirmation dialog
    - Clear input button
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: timestamp, unix, datetime, epoch, time, convert, date
- **TextCase**: Text case converter for developers and writers
    - 9 case types: UPPERCASE, lowercase, Title Case, Sentence case, camelCase, PascalCase, snake_case, kebab-case, CONSTANT_CASE
    - Real-time conversion as you type
    - Word splitting handles spaces, underscores, and hyphens
    - Conversion history (up to 10 entries)
    - Tap history entries to reuse conversions
    - Clear history with confirmation dialog
    - Clear input button
    - Uses `Card.filled` and `SegmentedButton` for Material 3 style
    - Keywords: textcase, case, uppercase, lowercase, title, sentence, camel, pascal, snake, kebab, constant, convert, text
- **WordCounter**: Text analysis tool for counting text statistics
    - Character count (with and without spaces)
    - Word count
    - Line count
    - Sentence count
    - Paragraph count
    - Real-time counting as you type
    - Clear input button
    - Uses `Card.filled` and `Chip` for Material 3 style
    - Keywords: wordcounter, word, count, character, char, line, sentence, paragraph, text, letter
- **DaysCalculator**: Days calculator for date calculations
    - Calculate days between two dates
    - Add days to a date
    - Subtract days from a date
    - Results displayed in days, weeks, months, years
    - Date picker integration with today button
    - Swap dates button for difference mode
    - Slider for adding/subtracting days (0-365)
    - Calculation history (up to 10 entries)
    - Reset button to clear all inputs
    - Uses `Card.filled`, `SegmentedButton`, `Slider`, `Chip` for Material 3 style
    - Keywords: days, calculator, date, difference, between, add, subtract, calculate
- **LoremIpsum**: Lorem Ipsum placeholder text generator
    - Generate placeholder text for designers and developers
    - Configurable word count (10-500 words)
    - Configurable paragraph count (1-10 paragraphs)
    - Option to start with classic "Lorem ipsum dolor sit amet..."
    - Regenerate text with one tap
    - Selectable text for easy copying
    - History of generated texts (up to 10 entries)
    - Clear history with confirmation dialog
    - Uses `Card.filled`, `Slider`, `FilterChip`, `ElevatedButton` for Material 3 style
    - Keywords: loremipsum, lorem, ipsum, placeholder, text, generate, dummy, sample
- **UUID**: UUID/GUID generator for unique identifiers
    - Generate UUID v4 (random) identifiers
    - Generate UUID v1 (time-based) identifiers
    - Generate short IDs (timestamp-based)
    - Copy UUID to clipboard with one tap
    - Generation count display
    - History of generated UUIDs (up to 10 entries)
    - No-dash UUID format display
    - Clear history with confirmation dialog
    - Uses `Card.filled`, `ActionChip` for Material 3 style
    - Keywords: uuid, guid, id, unique, identifier, generate, random
- **PasswordStrength**: Password strength checker for security analysis
    - Check password strength with real-time scoring (0-100)
    - Five strength levels: Very Weak, Weak, Medium, Strong, Very Strong
    - Color-coded strength indicators (red, orange, yellow, green)
    - Feedback for improving password security
    - Detects repeated characters, sequential patterns, common passwords
    - Password history tracking (up to 10 entries)
    - Show/hide password toggle
    - Copy password from history with one tap
    - Clear password and history options
    - Uses `Card.filled`, `LinearProgressIndicator` for Material 3 style
    - Keywords: password, strength, check, security, weak, strong, analyze, score
- **MoonPhase**: Moon phase calculator based on date
    - Current moon phase display with emoji (🌑, 🌒, 🌓, 🌔, 🌕, 🌖, 🌗, 🌘)
    - Illumination percentage (0-100%)
    - Moon age in days (synodic month cycle)
    - Phase name (New Moon, Waxing Crescent, First Quarter, Waxing Gibbous, Full Moon, Waning Gibbous, Last Quarter, Waning Crescent)
    - Date selector to view past/future moon phases
    - Upcoming events: next new moon and full moon countdown
    - "Today" quick action button
    - Uses `Card.filled`, `ActionChip`, `showDatePicker` for Material 3 style
    - Keywords: moon, phase, lunar, cycle, full, new, crescent, gibbous, waxing, waning, quarter
- **ReactionTime**: Reaction time tester for measuring response speed
    - Test reaction speed with visual signal
    - Initial state is 'ready' allowing immediate test start
    - Random delay between 1-5 seconds before signal appears
    - Detect early taps with "Too early" warning
    - Track best time, average time, and attempt count
    - History tracking for up to 10 attempts
    - Trophy icon indicator for best time
    - Clear all history with confirmation dialog
    - Reaction time persisted in history via SharedPreferences
    - Uses `Card.filled`, `GestureDetector`, circular button for Material 3 style
    - Keywords: reaction, time, reflex, speed, test, tap, quick, fast, response
- **DecisionMaker**: Decision making utility for random choices
    - Three decision modes: Pick from options, Coin toss, Yes/No
    - Pick mode: Enter comma-separated options for random selection
    - Spinning animation for 3+ options before result
    - Coin toss: Quick Heads/Tails flip
    - Yes/No: Quick Yes/No decision
    - Decision history tracking (up to 10 entries)
    - Timestamp display (just now, Xm ago, Xh ago, Xd ago)
    - Clear all history with confirmation dialog
    - Uses `Card.filled`, `SegmentedButton`, `TextField` for Material 3 style
    - Keywords: decision, maker, decide, choose, random, pick, option, spin, wheel, coin, toss, yes, no
- **RockPaperScissors**: Rock Paper Scissors game against computer
    - Play against computer opponent with random choices
    - Three choices: Rock (🪨), Paper (📄), Scissors (✂️)
    - Win/loss/draw statistics tracking
    - Win rate percentage display
    - Game history tracking (up to 10 entries)
    - Reset stats with confirmation dialog
    - History toggle view
    - Standard RPS rules: Rock beats Scissors, Scissors beats Paper, Paper beats Rock
    - Uses `Card.filled`, `ElevatedButton`, `TextButton` for Material 3 style
    - Keywords: rock, paper, scissors, game, rps, play, hand

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
- `torch_light: ^1.0.0` - Flashlight control
- `qr_flutter: ^4.1.0` - QR code generation
- `url_launcher: ^6.3.0` - URL/bookmark opening in external browser

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
- Flashlight provider tests (provider existence, keywords, model state, widget rendering)
- Notes provider tests (provider existence, keywords, model state, CRUD operations)
- Timer provider tests (provider existence, keywords, model state, timer operations)
- Stopwatch provider tests (provider existence, keywords, model state, stopwatch operations)
- Calculator provider tests (provider existence, keywords, model state, calculation operations)
- World Clock provider tests (provider existence, keywords, model state, timezone operations)
- Countdown provider tests (provider existence, keywords, model state, CRUD operations, time formatting)
- Unit Converter provider tests (provider existence, keywords, model state, conversion operations)
- Pomodoro provider tests (provider existence, keywords, model state, timer operations, phase transitions)
- Clipboard provider tests (provider existence, keywords, model state, CRUD operations)
- Todo provider tests (provider existence, keywords, model state, CRUD operations, priority handling)
- QR Code provider tests (provider existence, keywords, model state, text operations, widget rendering)
- Random Generator provider tests (provider existence, keywords, model state, coin flip, dice roll, password generation)
- Color Generator provider tests (provider existence, keywords, model state, color operations, HEX/RGB conversion)
- Currency Converter provider tests (provider existence, keywords, model state, currency operations, widget rendering)
- Habit provider tests (provider existence, keywords, model state, CRUD operations, streak tracking, widget rendering)
- Meditation provider tests (provider existence, keywords, model state, timer operations, breathing guide, widget rendering)
- Water provider tests (provider existence, keywords, model state, add/remove glasses, goal setting, progress, widget rendering)
- Mood provider tests (provider existence, keywords, model state, CRUD operations, streak tracking, widget rendering)
- Number Base Converter provider tests (provider existence, keywords, model state, conversion operations)
- Calendar provider tests (provider existence, keywords, model state, navigation buttons, widget rendering)
- Progress provider tests (provider existence, keywords, model state, CRUD operations, percentage calculation, widget rendering)
- Anniversary provider tests (provider existence, keywords, model state, CRUD operations, time formatting, widget rendering)
- Sleep provider tests (provider existence, keywords, model state, sleep logging, statistics calculations, widget rendering)
- Counter provider tests (provider existence, keywords, model state, CRUD operations, increment/decrement, persistence, widget rendering)
- Tip Calculator provider tests (provider existence, keywords, model state, bill calculations, split functionality, history, widget rendering)
- BMI Calculator provider tests (provider existence, keywords, model state, BMI calculation, unit switching, history, widget rendering)
- Metronome provider tests (provider existence, keywords, model state, BPM operations, time signature, tap tempo, history, widget rendering)
- Flashcard provider tests (provider existence, keywords, model state, CRUD operations for decks and cards, study tracking, widget rendering)
- Workout provider tests (provider existence, keywords, model state, workout logging, statistics calculations, widget rendering)
- Age provider tests (provider existence, keywords, model state, zodiac calculation, age calculation, birthday countdown, CRUD operations, widget rendering)
- Percentage provider tests (provider existence, keywords, model state, percentage calculations, history, widget rendering)
- Quick Contacts provider tests (provider existence, keywords, model state, CRUD operations, widget rendering)
- Shopping List provider tests (provider existence, keywords, model state, CRUD operations, category handling, persistence, widget rendering)
- Caffeine provider tests (provider existence, keywords, model state, add/remove caffeine, limit tracking, preset drinks, history, widget rendering)
- Subscription provider tests (provider existence, keywords, model state, CRUD operations, renewal calculations, cost totals, widget rendering)
- Parking provider tests (provider existence, keywords, model state, entry operations, meter controls, widget rendering)
- Gratitude provider tests (provider existence, keywords, model state, CRUD operations, streak tracking, widget rendering)
- Debt provider tests (provider existence, keywords, model state, CRUD operations, owed tracking, history, widget rendering)
- Interval Timer provider tests (provider existence, keywords, model state, presets, phase operations, timer controls, widget rendering)
- TextCase provider tests (provider existence, keywords, model state, case conversions, history, widget rendering)
- DaysCalculator provider tests (provider existence, keywords, model state, date operations, history, widget rendering)
- LoremIpsum provider tests (provider existence, keywords, model state, text generation, paragraph handling, history, widget rendering)
- UUID provider tests (provider existence, keywords, model state, UUID v4 generation, UUID v1 generation, short UUID generation, history, widget rendering)
- PasswordStrength provider tests (provider existence, keywords, model state, password analysis, strength scoring, feedback, history, widget rendering)
- MoonPhase provider tests (provider existence, keywords, model state, moon age calculation, illumination percentage, phase name/emoji validation, next new/full moon, date operations, widget rendering)
- ReactionTime provider tests (provider existence, keywords, model state, reaction time operations, history, widget rendering)
- DecisionMaker provider tests (provider existence, keywords, model state, decision operations, history, widget rendering)
- RockPaperScissors provider tests (provider existence, keywords, model state, game operations, statistics, history, widget rendering)
  
Total tests: 1684 tests

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
- `flashlight_provider.md` - Flashlight toggle provider implementation
- `notes_provider.md` - Notes provider implementation
- `timer_provider.md` - Timer provider implementation
- `stopwatch_provider.md` - Stopwatch provider implementation
- `calculator_provider.md` - Calculator provider implementation
- `worldclock_provider.md` - World Clock provider implementation
- `countdown_provider.md` - Countdown provider implementation
- `unitconverter_provider.md` - Unit Converter provider implementation
- `pomodoro_provider.md` - Pomodoro timer provider implementation
- `clipboard_provider.md` - Clipboard history provider implementation
- `todo_provider.md` - Todo/task list provider implementation
- `qrcode_provider.md` - QR code generator provider implementation
- `random_provider.md` - Random Generator provider implementation
- `color_provider.md` - Color Generator provider implementation
- `currency_provider.md` - Currency Converter provider implementation
- `currency_provider_fix.md` - Currency provider MultiProvider fix
- `bookmarks_provider.md` - Bookmarks provider implementation
- `habit_provider.md` - Habit tracker provider implementation
- `meditation_provider.md` - Meditation timer provider implementation
- `water_provider.md` - Water intake tracker provider implementation
- `mood_provider.md` - Mood tracker provider implementation
- `expense_provider.md` - Expense tracker provider implementation
- `numberbase_provider.md` - Number Base Converter provider implementation
- `progress_provider.md` - Progress tracker provider implementation
- `anniversary_provider.md` - Anniversary provider implementation
- `sleep_provider.md` - Sleep tracker provider implementation
- `counter_provider.md` - Counter provider implementation for multiple named counters
- `tip_provider.md` - Tip Calculator provider implementation for dining/bill splitting
- `bmi_provider.md` - BMI Calculator provider implementation for health tracking
- `metronome_provider.md` - Metronome provider implementation for musicians
- `flashcard_provider.md` - Flashcard provider implementation for studying/memorization
- `workout_provider.md` - Workout provider implementation for fitness/exercise tracking
- `age_provider.md` - Age Calculator provider implementation for birthdate/age calculation
- `percentage_provider.md` - Percentage Calculator provider implementation for percentage calculations
- `quickcontacts_provider.md` - Quick Contacts provider implementation for speed dial and messaging
- `shoppinglist_provider.md` - Shopping List provider implementation for shopping list management
- `calendar_model.md` - CalendarModel implementation for provider pattern consistency
- `min_sdk_version_fix.md` - Minimum SDK version fix for torch_light plugin
- `critical_bug_fixes_iteration29.md` - Critical bug fixes for missing MultiProvider models and memory leaks
- `critical_bug_fixes_iteration32.md` - Critical bug fix for missing Anniversary model in MultiProvider
- `critical_bug_fixes_iteration49.md` - Critical bug fix for missing Parking, Gratitude, Debt models in MultiProvider
- `interval_timer_provider.md` - Interval Timer (HIIT/Tabata) provider implementation for workout intervals
- `app_limit_removal.md` - Removal of 20 app limit in info widget list
- `battery_listener_optimization.md` - Battery state listener optimization to prevent excessive notifications
- `textencoder_provider.md` - TextEncoder provider implementation for encoding/decoding utilities
- `morse_provider.md` - Morse Code encoder/decoder provider implementation
- `timestamp_provider.md` - Timestamp Converter provider implementation for Unix timestamp/datetime conversion
- `textcase_provider.md` - TextCase provider implementation for text case conversion
- `wordcounter_provider.md` - Word Counter provider implementation for text analysis
- `passwordstrength_provider.md` - Password Strength provider implementation for security analysis
- `moonphase_provider.md` - Moon Phase provider implementation for lunar phase calculation
- `reactiontime_provider.md` - Reaction Time provider implementation for reaction speed testing

## Notice
DO NOT EDIT task*.md

### Network Connection

```shell
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
```