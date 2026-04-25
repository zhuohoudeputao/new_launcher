# Todo Provider Implementation

## Overview

The Todo provider manages a task/todo list with priority levels and completion tracking.

## Provider Details

- **Provider Name**: Todo
- **Keywords**: todo, task, list, check, done, complete, add, checklist
- **Model**: todoModel
- **Max Tasks**: 20

## Features

### Task Management

- Add, edit, and delete tasks
- Mark tasks as completed/incomplete
- Priority levels (high, medium, low)
- Visual priority indicators

### Statistics

- Active/done count display
- Clear completed tasks button
- Clear all tasks with confirmation dialog

### Priority System

| Priority | Indicator | Color |
|----------|-----------|-------|
| High | Red circle | Error color |
| Medium | Orange circle | Warning color |
| Low | Gray circle | Surface color |

## Model (TodoModel)

```dart
class TodoModel extends ChangeNotifier {
  List<TodoTask> _tasks = [];
  static const int maxTasks = 20;
  
  void addTask(String text, String priority);
  void editTask(int index, String text, String priority);
  void deleteTask(int index);
  void toggleComplete(int index);
  void clearCompleted();
  void clearAll();
  int get activeCount;
  int get doneCount;
}
```

### TodoTask

```dart
class TodoTask {
  String text;
  String priority;
  bool isCompleted;
  DateTime createdAt;
}
```

## Widget (TodoCard)

- Card.filled style
- SegmentedButton for priority selection
- TextField for task input
- Task list with checkboxes
- Active/done count display
- Clear buttons with confirmation

## Persistence

Tasks persisted via SharedPreferences as JSON.

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- CRUD operations
- Priority handling
- Active/done count
- Widget rendering

## Related Files

- `lib/providers/provider_todo.dart` - Provider implementation