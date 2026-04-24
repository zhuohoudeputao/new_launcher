# UUID Provider Implementation

## Overview

The UUID provider implements a UUID/GUID generator that allows users to:
1. Generate UUID v4 (random) identifiers
2. Generate UUID v1 (time-based) identifiers
3. Generate short IDs (timestamp-based)
4. Copy UUIDs to clipboard with one tap
5. View history of generated UUIDs (up to 10 entries)

## Implementation Details

### File Structure

- `lib/providers/provider_uuid.dart` - Main provider implementation
- Model: `UUIDModel` - State management
- Widget: `UUIDCard` - UI component

### Model: UUIDModel

The model manages:
- Current UUID v4 result
- Current UUID v1 result
- Generation count tracking
- History of generated UUIDs (max 10 entries)
- Initialization state

Key methods:
- `init()` - Initialize and generate first UUID
- `generateUUIDv4()` - Generate random UUID version 4
- `generateUUIDv1()` - Generate time-based UUID version 1
- `generateShortUUID()` - Generate short timestamp-based ID
- `generateNoDashUUID()` - Generate UUID without dashes
- `addToHistory()` - Add UUID to history
- `removeFromHistory()` - Remove specific entry from history
- `clearHistory()` - Clear all history
- `copyToClipboard()` - Copy UUID to clipboard
- `refresh()` - Notify listeners

### UUID Generation Algorithm

**UUID v4 (Random):**
- Generates 16 random bytes
- Sets version bits (byte 6: 0x40)
- Sets variant bits (byte 8: 0x80)
- Converts to hex string with dashes: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx

**UUID v1 (Time-based):**
- Uses current microseconds timestamp
- Random clock sequence (14 bits)
- Random node identifier (6 bytes)
- Format: timestamp-clockseq-node

**Short UUID:**
- Combines timestamp with random suffix
- Format: <timestamp>x<random>

### Widget: UUIDCard

Features:
- Display current UUID v4 with copyable text
- Display no-dash format below main UUID
- Generation count badge
- ActionChip buttons for:
  - Generate v4
  - Generate v1
  - Short ID
  - Copy to clipboard
  - History toggle
- Expandable history section
- Clear history confirmation dialog

### Material 3 Components Used

- `Card.filled` - Main card container
- `ActionChip` - Generation action buttons
- `SelectableText` - UUID display
- `IconButton` - Copy button in history
- `AlertDialog` - Clear history confirmation
- `Container` - Generation count badge
- `ListView.builder` - History list
- `TextButton` - Clear history button

## Keywords

The provider is searchable with keywords:
- uuid, guid, id, unique, identifier, generate, random

## Testing

Tests cover:
- Provider existence in Global.providerList
- Model initialization
- UUID v4 generation and format validation
- UUID v1 generation and format validation
- Short UUID generation
- No-dash UUID generation
- Unique UUID generation verification
- Generation count increment
- History management (add, remove, clear, max length)
- Empty string rejection in history
- Listener notifications
- Widget rendering (loading and initialized states)

## Integration

The provider is integrated into the app via:
1. Added to `Global.providerList` in `lib/data.dart`
2. Added to `MultiProvider` in `lib/main.dart`
3. Model exposed as `uuidModel`

## User Experience

1. User opens the app and sees the UUID Generator card
2. Card displays a freshly generated UUID v4
3. User can see the no-dash format below
4. User taps "Generate v4" for new random UUID
5. User taps "Generate v1" for time-based UUID
6. User taps "Short ID" for compact identifier
7. User taps "Copy" to copy current UUID to clipboard
8. User taps "History" to view previous UUIDs
9. User can copy from history entries
10. User can clear history with confirmation dialog

## Use Cases

1. **Database**: Generate unique primary keys for records
2. **API Development**: Create unique request identifiers
3. **Session IDs**: Generate secure session tokens
4. **File Naming**: Create unique filenames
5. **Testing**: Generate test identifiers
6. **Logging**: Create unique log entry IDs
7. **Tracking**: Generate tracking codes for shipments/orders