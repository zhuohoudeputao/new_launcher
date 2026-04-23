# Notes Provider Implementation

## Overview

The Notes provider (`provider_notes.dart`) provides a quick notes feature for storing and managing text snippets. It allows users to add, edit, delete, and clear notes, with data persisted locally.

## Implementation Details

### Provider Structure

```dart
MyProvider providerNotes = MyProvider(
    name: "Notes",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### NotesModel

The `NotesModel` class manages the notes data:

- **Storage**: List of strings stored in memory
- **Persistence**: SharedPreferences for local storage
- **Limit**: Maximum 10 notes (oldest removed when exceeded)
- **State**: Tracks initialization status

#### Key Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize and load persisted notes |
| `addNote(String)` | Add a new note at the beginning of list |
| `updateNote(int, String)` | Update existing note (or delete if empty) |
| `deleteNote(int)` | Remove note at specified index |
| `clearAllNotes()` | Remove all notes |

### Widgets

#### NotesCard

The main display widget showing all notes:
- Shows loading state before initialization
- Empty state message when no notes
- ListView of note items with edit/delete actions
- Add button (+) in header
- Clear all button when notes exist

#### AddNoteDialog

Dialog for creating new notes:
- Multi-line text input
- Cancel and Save buttons
- Auto-focus on text field

#### EditNoteDialog

Dialog for editing existing notes:
- Pre-filled with current note text
- Multi-line text input
- Cancel and Save buttons

### Quick Note Action

The provider registers a "Quick note" action with keywords:
`note notes text memo clipboard write quick`

This adds an info card prompting users to add a new note.

## Data Flow

1. User taps "Add Quick Note" card or NotesCard add button
2. AddNoteDialog appears
3. User enters text and saves
4. Note added to front of list via `addNote()`
5. Model notifies listeners
6. Note saved to SharedPreferences
7. NotesCard updates display

## Storage Format

Notes are stored as a string list in SharedPreferences:
- Key: `Notes.List`
- Format: `List<String>`

## UI Design

- Uses `Card.filled` for Material 3 consistency
- Dense ListTile layout for notes
- Small icons (18-20px) for compact display
- Confirmation dialog for clear all action
- ColorScheme colors for visual consistency

## Error Handling

- Trims whitespace from note text
- Ignores empty note submissions
- Safe index checking for update/delete operations
- Logging for all note operations

## Test Coverage

Tests verify:
- Provider existence in Global.providerList
- Keywords contain expected terms
- Model initialization state
- Add, update, delete operations
- Clear all functionality
- Maximum notes limit
- Empty state rendering
- Loading state rendering
- Widget existence