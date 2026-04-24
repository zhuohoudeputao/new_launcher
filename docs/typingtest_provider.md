# TypingTest Provider Implementation

## Overview

The TypingTest provider implements a typing speed and accuracy test for the Flutter launcher application. Users can measure their typing speed in WPM (words per minute) and accuracy percentage.

## Implementation Details

### Location
- Provider: `lib/providers/provider_typingtest.dart`
- Tests: `test/widget_test.dart` (TypingTest provider tests group)

### Model: TypingTestModel

The `TypingTestModel` class extends `ChangeNotifier` and manages:

- **Test State**: Ready, typing, or finished
- **Sample Text**: Random text from 10 preset samples
- **Typed Text**: User's input text
- **Timer**: Elapsed seconds counter
- **WPM Calculation**: Words per minute speed
- **Accuracy Calculation**: Percentage of correct characters
- **Error Tracking**: Count of incorrect characters
- **History**: Recent test results (up to 10)
- **Best/Average WPM**: Statistics from history

### Features

1. **Test States**
   - Ready: Initial state, shows sample text and Start button
   - Typing: Active test with real-time timer and stats
   - Finished: Complete with final results

2. **Sample Texts**
   - 10 preset English text samples
   - Random selection for each test
   - Includes programming and general sentences
   - Examples: "The quick brown fox...", "Flutter makes it easy..."

3. **Real-time Statistics**
   - Timer counting elapsed seconds
   - WPM calculated during typing
   - Accuracy percentage updated live
   - Error count tracking

4. **Character Feedback**
   - Green: Correctly typed characters
   - Red: Incorrectly typed characters
   - Gray: Pending characters (not yet typed)

5. **Test Completion**
   - Automatic finish when full text typed
   - Final WPM and accuracy display
   - Results saved to history
   - Try Again or Reset options

6. **History Tracking**
   - Up to 10 recent test results
   - Stores WPM, accuracy, errors, duration, timestamp
   - Best WPM calculation from history
   - Average WPM calculation from history

7. **Focus Management**
   - Auto-focus on text field when test starts
   - Keywords action requests focus on widget

### Widget: TypingTestCard

The `TypingTestCard` widget displays:

- Ready state: Sample text, Start button
- Typing state: Timer, WPM, Accuracy stats, text with color feedback, input field
- Finished state: Completion message, final stats, action buttons
- History section: Recent results with best/average WPM

### Keywords

`typing, test, speed, wpm, words, per, minute, type, keyboard, fast, accuracy`

## Material 3 Design

- `Card.filled` for card container
- `TextField` for user input
- `SelectableText` for sample text display
- `RichText` for character-by-character feedback
- Color coding: Green for correct, Red for incorrect, Gray for pending
- `ElevatedButton` for Try Again action
- `TextButton` for Reset action
- `CircularProgressIndicator` for loading state

## Tests

Test coverage includes:

- TypingTestResult properties
- TypingTestModel default values
- TypingTestModel initialization
- Test start
- Text update during typing
- Error counting
- Test finish (automatic on completion)
- WPM calculation
- Accuracy calculation
- Test reset (returns to ready state)
- History clearing
- History max limit
- Best WPM calculation
- Average WPM calculation
- Character status retrieval
- Refresh notification
- Provider existence and keywords
- TypingTestCard rendering (loading, initialized, ready, typing, finished states)
- Sample text display
- History section display

## WPM Calculation

Words Per Minute (WPM) is calculated as:
- Count words typed (split by spaces, exclude empty)
- Divide by elapsed minutes
- Formula: `WPM = wordsTyped / (elapsedSeconds / 60)`

## Accuracy Calculation

Accuracy percentage is calculated as:
- Count correct characters (total typed minus errors)
- Divide by total characters typed
- Formula: `Accuracy = (correctChars / typedChars) * 100`

## Sample Texts

The 10 preset texts include:
1. "The quick brown fox jumps over the lazy dog near the river bank."
2. "Programming is both an art and a science that requires patience."
3. "Flutter makes it easy to build beautiful mobile applications."
4. "Practice makes perfect when learning new skills every day."
5. "Technology changes rapidly so we must adapt quickly."
6. "Reading books helps expand knowledge and vocabulary daily."
7. "Writing clean code is essential for maintainable software."
8. "A journey of a thousand miles begins with a single step."
9. "Success comes to those who work hard and stay focused."
10. "Learning to type faster can save valuable time each day."

## Future Enhancements

Potential improvements:

- Add difficulty levels (short/medium/long texts)
- Add timed test mode (fixed duration)
- Add custom text input option
- Add statistics persistence via SharedPreferences
- Add typing lessons/tutorial mode
- Add international text samples
- Add error position tracking
- Add detailed error analysis