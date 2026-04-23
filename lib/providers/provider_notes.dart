import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

NotesModel notesModel = NotesModel();

MyProvider providerNotes = MyProvider(
    name: "Notes",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Quick note',
      keywords: 'note notes text memo clipboard write quick',
      action: () {
        Global.infoModel.addInfo("AddNote", "Add Quick Note",
            subtitle: "Tap to add a new note",
            icon: Icon(Icons.note_add),
            onTap: () => _showAddNoteDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await notesModel.init();
  Global.infoModel.addInfoWidget(
      "Notes",
      ChangeNotifierProvider.value(
          value: notesModel,
          builder: (context, child) => NotesCard()),
      title: "Quick Notes");
}

Future<void> _update() async {
  await notesModel.refresh();
}

void _showAddNoteDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddNoteDialog(),
  );
}

void _showEditNoteDialog(BuildContext context, int index, String currentText) {
  showDialog(
    context: context,
    builder: (context) => EditNoteDialog(index: index, currentText: currentText),
  );
}

class NotesModel extends ChangeNotifier {
  List<String> _notes = [];
  static const int maxNotes = 10;
  static const String _notesKey = 'Notes.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<String> get notes => List.unmodifiable(_notes);
  int get length => _notes.length;
  bool get isInitialized => _isInitialized;
  bool get hasNotes => _notes.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadNotes();
    _isInitialized = true;
    Global.loggerModel.info("Notes initialized with ${_notes.length} notes", source: "Notes");
    notifyListeners();
  }

  Future<void> _loadNotes() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final notesData = prefs.getStringList(_notesKey);
    if (notesData != null) {
      _notes = notesData;
    }
  }

  Future<void> _saveNotes() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    try {
      await prefs.setStringList(_notesKey, _notes);
      Global.loggerModel.info("Saved ${_notes.length} notes", source: "Notes");
    } catch (e) {
      Global.loggerModel.error("Failed to save notes: $e", source: "Notes");
    }
  }

  Future<void> refresh() async {
    await _loadNotes();
    notifyListeners();
    Global.loggerModel.info("Notes refreshed", source: "Notes");
  }

  void addNote(String text) {
    if (text.trim().isEmpty) return;
    
    _notes.insert(0, text.trim());
    
    if (_notes.length > maxNotes) {
      _notes.removeLast();
    }
    
    notifyListeners();
    _saveNotes();
    final preview = text.trim().length > 20 ? text.trim().substring(0, 20) : text.trim();
    Global.loggerModel.info("Added note: $preview...", source: "Notes");
  }

  void updateNote(int index, String text) {
    if (index < 0 || index >= _notes.length) return;
    if (text.trim().isEmpty) {
      deleteNote(index);
      return;
    }
    
    _notes[index] = text.trim();
    notifyListeners();
    _saveNotes();
    Global.loggerModel.info("Updated note at index $index", source: "Notes");
  }

  void deleteNote(int index) {
    if (index < 0 || index >= _notes.length) return;
    
    _notes.removeAt(index);
    notifyListeners();
    _saveNotes();
    Global.loggerModel.info("Deleted note at index $index", source: "Notes");
  }

  void clearAllNotes() {
    _notes.clear();
    notifyListeners();
    _saveNotes();
    Global.loggerModel.info("Cleared all notes", source: "Notes");
  }
}

class NotesCard extends StatefulWidget {
  @override
  State<NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<NotesCard> {
  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesModel>();
    
    if (!notes.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.note, size: 24),
              SizedBox(width: 12),
              Text("Notes: Loading..."),
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
                  "Quick Notes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (notes.hasNotes)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear all notes",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddNoteDialog(context),
                      tooltip: "Add note",
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!notes.hasNotes)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No notes yet. Tap + to add.",
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
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes.notes[index];
                  return _buildNoteItem(context, index, note);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoteItem(BuildContext context, int index, String note) {
    final displayText = note.length > 50 ? '${note.substring(0, 50)}...' : note;
    
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(Icons.note, size: 20),
      title: Text(
        displayText,
        style: TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _showEditNoteDialog(context, index, note),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 16),
        onPressed: () => context.read<NotesModel>().deleteNote(index),
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  
  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Notes"),
        content: Text("This will delete all notes. This action cannot be undone."),
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
      context.read<NotesModel>().clearAllNotes();
    }
  }
}

class AddNoteDialog extends StatefulWidget {
  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Quick Note"),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: "Enter your note...",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              context.read<NotesModel>().addNote(_controller.text);
              Navigator.pop(context);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class EditNoteDialog extends StatefulWidget {
  final int index;
  final String currentText;
  
  const EditNoteDialog({
    required this.index,
    required this.currentText,
  });
  
  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentText);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Note"),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: "Enter your note...",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            context.read<NotesModel>().updateNote(widget.index, _controller.text);
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}