import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

TodoModel todoModel = TodoModel();

MyProvider providerTodo = MyProvider(
    name: "Todo",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Quick task',
      keywords: 'todo task list check done complete add checklist',
      action: () {
        Global.infoModel.addInfo("AddTodo", "Add Quick Task",
            subtitle: "Tap to add a new task",
            icon: Icon(Icons.add_task),
            onTap: () => _showAddTodoDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await todoModel.init();
  Global.infoModel.addInfoWidget(
      "Todo",
      ChangeNotifierProvider.value(
          value: todoModel,
          builder: (context, child) => TodoCard()),
      title: "Todo List");
}

Future<void> _update() async {
  await todoModel.refresh();
}

void _showAddTodoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddTodoDialog(),
  );
}

void _showEditTodoDialog(BuildContext context, int index, TodoItem item) {
  showDialog(
    context: context,
    builder: (context) => EditTodoDialog(index: index, item: item),
  );
}

enum TodoPriority { high, medium, low }

class TodoItem {
  final String text;
  final bool completed;
  final TodoPriority priority;
  final DateTime createdAt;

  TodoItem({
    required this.text,
    this.completed = false,
    this.priority = TodoPriority.medium,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String toJson() {
    return jsonEncode({
      'text': text,
      'completed': completed,
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  static TodoItem fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return TodoItem(
      text: map['text'] as String,
      completed: map['completed'] as bool,
      priority: TodoPriority.values[map['priority'] as int],
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  TodoItem copyWith({
    String? text,
    bool? completed,
    TodoPriority? priority,
    DateTime? createdAt,
  }) {
    return TodoItem(
      text: text ?? this.text,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TodoModel extends ChangeNotifier {
  List<TodoItem> _todos = [];
  static const int maxTodos = 20;
  static const String _todosKey = 'Todo.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<TodoItem> get todos => List.unmodifiable(_todos);
  List<TodoItem> get activeTodos => _todos.where((t) => !t.completed).toList();
  List<TodoItem> get completedTodos => _todos.where((t) => t.completed).toList();
  int get length => _todos.length;
  int get activeCount => activeTodos.length;
  int get completedCount => completedTodos.length;
  bool get isInitialized => _isInitialized;
  bool get hasTodos => _todos.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTodos();
    _isInitialized = true;
    Global.loggerModel.info("Todo initialized with ${_todos.length} tasks", source: "Todo");
    notifyListeners();
  }

  Future<void> _loadTodos() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final todosData = prefs.getStringList(_todosKey);
    if (todosData != null) {
      _todos = todosData.map((json) => TodoItem.fromJson(json)).toList();
    }
  }

  Future<void> _saveTodos() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    try {
      final todosData = _todos.map((t) => t.toJson()).toList();
      await prefs.setStringList(_todosKey, todosData);
      Global.loggerModel.info("Saved ${_todos.length} todos", source: "Todo");
    } catch (e) {
      Global.loggerModel.error("Failed to save todos: $e", source: "Todo");
    }
  }

  Future<void> refresh() async {
    await _loadTodos();
    notifyListeners();
    Global.loggerModel.info("Todo refreshed", source: "Todo");
  }

  void addTodo(String text, TodoPriority priority) {
    if (text.trim().isEmpty) return;
    
    _todos.insert(0, TodoItem(
      text: text.trim(),
      priority: priority,
    ));
    
    if (_todos.length > maxTodos) {
      _todos.removeLast();
    }
    
    notifyListeners();
    _saveTodos();
    final preview = text.trim().length > 20 ? text.trim().substring(0, 20) : text.trim();
    Global.loggerModel.info("Added todo: $preview...", source: "Todo");
  }

  void updateTodo(int index, String text, TodoPriority priority) {
    if (index < 0 || index >= _todos.length) return;
    if (text.trim().isEmpty) {
      deleteTodo(index);
      return;
    }
    
    _todos[index] = _todos[index].copyWith(
      text: text.trim(),
      priority: priority,
    );
    notifyListeners();
    _saveTodos();
    Global.loggerModel.info("Updated todo at index $index", source: "Todo");
  }

  void toggleCompleted(int index) {
    if (index < 0 || index >= _todos.length) return;
    
    _todos[index] = _todos[index].copyWith(
      completed: !_todos[index].completed,
    );
    notifyListeners();
    _saveTodos();
    Global.loggerModel.info("Toggled todo completion at index $index", source: "Todo");
  }

  void deleteTodo(int index) {
    if (index < 0 || index >= _todos.length) return;
    
    _todos.removeAt(index);
    notifyListeners();
    _saveTodos();
    Global.loggerModel.info("Deleted todo at index $index", source: "Todo");
  }

  void clearCompleted() {
    _todos = _todos.where((t) => !t.completed).toList();
    notifyListeners();
    _saveTodos();
    Global.loggerModel.info("Cleared completed todos", source: "Todo");
  }

  void clearAllTodos() {
    _todos.clear();
    notifyListeners();
    _saveTodos();
    Global.loggerModel.info("Cleared all todos", source: "Todo");
  }
}

class TodoCard extends StatefulWidget {
  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  @override
  Widget build(BuildContext context) {
    final todo = context.watch<TodoModel>();
    
    if (!todo.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.task, size: 24),
              SizedBox(width: 12),
              Text("Todo: Loading..."),
            ],
          ),
        ),
      );
    }
    
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Todo List",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (todo.completedCount > 0)
                      IconButton(
                        icon: Icon(Icons.cleaning_services, size: 18),
                        onPressed: () => _showClearCompletedConfirmation(context),
                        tooltip: "Clear completed",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (todo.hasTodos)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearAllConfirmation(context),
                        tooltip: "Clear all",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddTodoDialog(context),
                      tooltip: "Add task",
                    ),
                  ],
                ),
              ],
            ),
            if (todo.activeCount > 0 || todo.completedCount > 0)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "${todo.activeCount} active, ${todo.completedCount} done",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            SizedBox(height: 8),
            if (!todo.hasTodos)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No tasks yet. Tap + to add.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: todo.length,
                itemBuilder: (context, index) {
                  final item = todo.todos[index];
                  return _buildTodoItem(context, index, item);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTodoItem(BuildContext context, int index, TodoItem item) {
    final displayText = item.text.length > 40 ? '${item.text.substring(0, 40)}...' : item.text;
    final priorityColor = _getPriorityColor(context, item.priority);
    final priorityIcon = _getPriorityIcon(item.priority);
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              item.completed ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: item.completed 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => context.read<TodoModel>().toggleCompleted(index),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Icon(priorityIcon, size: 16, color: priorityColor),
        ],
      ),
      title: Text(
        displayText,
        style: TextStyle(
          fontSize: 13,
          color: item.completed 
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
            : null,
          decoration: item.completed ? TextDecoration.lineThrough : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showEditTodoDialog(context, index, item),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 16),
        onPressed: () => context.read<TodoModel>().deleteTodo(index),
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  
  Color _getPriorityColor(BuildContext context, TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Theme.of(context).colorScheme.error;
      case TodoPriority.medium:
        return Theme.of(context).colorScheme.primary;
      case TodoPriority.low:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
  
  IconData _getPriorityIcon(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Icons.flag;
      case TodoPriority.medium:
        return Icons.flag_outlined;
      case TodoPriority.low:
        return Icons.remove;
    }
  }
  
  Future<void> _showClearCompletedConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Completed"),
        content: Text("Remove all completed tasks?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear"),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      context.read<TodoModel>().clearCompleted();
    }
  }
  
  Future<void> _showClearAllConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Tasks"),
        content: Text("This will delete all tasks. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Clear"),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      context.read<TodoModel>().clearAllTodos();
    }
  }
}

class AddTodoDialog extends StatefulWidget {
  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final TextEditingController _controller = TextEditingController();
  TodoPriority _selectedPriority = TodoPriority.medium;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Quick Task"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Enter your task...",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text("Priority: ", style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              SegmentedButton<TodoPriority>(
                segments: [
                  ButtonSegment(
                    value: TodoPriority.high,
                    label: Text("High"),
                    icon: Icon(Icons.flag, size: 16),
                  ),
                  ButtonSegment(
                    value: TodoPriority.medium,
                    label: Text("Med"),
                    icon: Icon(Icons.flag_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: TodoPriority.low,
                    label: Text("Low"),
                    icon: Icon(Icons.remove, size: 16),
                  ),
                ],
                selected: {_selectedPriority},
                onSelectionChanged: (Set<TodoPriority> newSelection) {
                  setState(() => _selectedPriority = newSelection.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              context.read<TodoModel>().addTodo(_controller.text, _selectedPriority);
              Navigator.pop(context);
            }
          },
          child: Text("Add"),
        ),
      ],
    );
  }
}

class EditTodoDialog extends StatefulWidget {
  final int index;
  final TodoItem item;
  
  const EditTodoDialog({
    required this.index,
    required this.item,
  });
  
  @override
  State<EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<EditTodoDialog> {
  late TextEditingController _controller;
  late TodoPriority _selectedPriority;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
    _selectedPriority = widget.item.priority;
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Task"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Enter your task...",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text("Priority: ", style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              SegmentedButton<TodoPriority>(
                segments: [
                  ButtonSegment(
                    value: TodoPriority.high,
                    label: Text("High"),
                    icon: Icon(Icons.flag, size: 16),
                  ),
                  ButtonSegment(
                    value: TodoPriority.medium,
                    label: Text("Med"),
                    icon: Icon(Icons.flag_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: TodoPriority.low,
                    label: Text("Low"),
                    icon: Icon(Icons.remove, size: 16),
                  ),
                ],
                selected: {_selectedPriority},
                onSelectionChanged: (Set<TodoPriority> newSelection) {
                  setState(() => _selectedPriority = newSelection.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            context.read<TodoModel>().updateTodo(widget.index, _controller.text, _selectedPriority);
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}