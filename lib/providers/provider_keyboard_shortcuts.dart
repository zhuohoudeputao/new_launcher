import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

KeyboardShortcutsModel keyboardShortcutsModel = KeyboardShortcutsModel();

MyProvider providerKeyboardShortcuts = MyProvider(
    name: "KeyboardShortcuts",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Keyboard Shortcuts',
      keywords: 'keyboard shortcut hotkey key combo shortcut reference',
      action: () => keyboardShortcutsModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  keyboardShortcutsModel.init();
  Global.infoModel.addInfoWidget(
      "KeyboardShortcuts",
      ChangeNotifierProvider.value(
          value: keyboardShortcutsModel,
          builder: (context, child) => KeyboardShortcutsCard()),
      title: "Keyboard Shortcuts");
}

Future<void> _update() async {
  keyboardShortcutsModel.refresh();
}

enum ShortcutCategory {
  general,
  browser,
  textEditing,
  fileManager,
  developer,
  system,
}

class KeyboardShortcut {
  final String action;
  final String windows;
  final String mac;
  final String linux;
  final ShortcutCategory category;

  const KeyboardShortcut({
    required this.action,
    required this.windows,
    required this.mac,
    required this.linux,
    required this.category,
  });
}

const List<KeyboardShortcut> keyboardShortcuts = [
  KeyboardShortcut(action: 'Copy', windows: 'Ctrl+C', mac: 'Cmd+C', linux: 'Ctrl+C', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Paste', windows: 'Ctrl+V', mac: 'Cmd+V', linux: 'Ctrl+V', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Cut', windows: 'Ctrl+X', mac: 'Cmd+X', linux: 'Ctrl+X', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Undo', windows: 'Ctrl+Z', mac: 'Cmd+Z', linux: 'Ctrl+Z', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Redo', windows: 'Ctrl+Y', mac: 'Cmd+Shift+Z', linux: 'Ctrl+Y', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Select All', windows: 'Ctrl+A', mac: 'Cmd+A', linux: 'Ctrl+A', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Find', windows: 'Ctrl+F', mac: 'Cmd+F', linux: 'Ctrl+F', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Find Next', windows: 'F3', mac: 'Cmd+G', linux: 'F3', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'Find Previous', windows: 'Shift+F3', mac: 'Cmd+Shift+G', linux: 'Shift+F3', category: ShortcutCategory.textEditing),
  KeyboardShortcut(action: 'New Tab', windows: 'Ctrl+T', mac: 'Cmd+T', linux: 'Ctrl+T', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Close Tab', windows: 'Ctrl+W', mac: 'Cmd+W', linux: 'Ctrl+W', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Reopen Closed Tab', windows: 'Ctrl+Shift+T', mac: 'Cmd+Shift+T', linux: 'Ctrl+Shift+T', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Next Tab', windows: 'Ctrl+Tab', mac: 'Cmd+Option+Right', linux: 'Ctrl+Tab', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Previous Tab', windows: 'Ctrl+Shift+Tab', mac: 'Cmd+Option+Left', linux: 'Ctrl+Shift+Tab', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Refresh Page', windows: 'Ctrl+R / F5', mac: 'Cmd+R', linux: 'Ctrl+R / F5', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Hard Refresh', windows: 'Ctrl+Shift+R / Ctrl+F5', mac: 'Cmd+Shift+R', linux: 'Ctrl+Shift+R', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Go to URL Bar', windows: 'Ctrl+L / Alt+D', mac: 'Cmd+L', linux: 'Ctrl+L', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'Open Download', windows: 'Ctrl+J', mac: 'Cmd+Shift+J', linux: 'Ctrl+J', category: ShortcutCategory.browser),
  KeyboardShortcut(action: 'New Window', windows: 'Ctrl+N', mac: 'Cmd+N', linux: 'Ctrl+N', category: ShortcutCategory.general),
  KeyboardShortcut(action: 'Close Window', windows: 'Alt+F4', mac: 'Cmd+W', linux: 'Alt+F4', category: ShortcutCategory.general),
  KeyboardShortcut(action: 'Switch Window', windows: 'Alt+Tab', mac: 'Cmd+Tab', linux: 'Alt+Tab', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Minimize Window', windows: 'Win+Down / Alt+Space+N', mac: 'Cmd+M', linux: 'Alt+F9', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Maximize Window', windows: 'Win+Up', mac: 'Ctrl+Cmd+F', linux: 'Alt+F10', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Lock Screen', windows: 'Win+L', mac: 'Ctrl+Cmd+Q', linux: 'Ctrl+Alt+L', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Show Desktop', windows: 'Win+D', mac: 'F11 / Cmd+F3', linux: 'Ctrl+Alt+D', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Task Manager', windows: 'Ctrl+Shift+Esc', mac: 'Cmd+Option+Esc', linux: 'Ctrl+Alt+Delete', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Screenshot', windows: 'Win+Shift+S', mac: 'Cmd+Shift+4', linux: 'Ctrl+Shift+Print', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Full Screenshot', windows: 'PrtScn', mac: 'Cmd+Shift+3', linux: 'Print', category: ShortcutCategory.system),
  KeyboardShortcut(action: 'Open File', windows: 'Ctrl+O', mac: 'Cmd+O', linux: 'Ctrl+O', category: ShortcutCategory.fileManager),
  KeyboardShortcut(action: 'Save File', windows: 'Ctrl+S', mac: 'Cmd+S', linux: 'Ctrl+S', category: ShortcutCategory.fileManager),
  KeyboardShortcut(action: 'Save As', windows: 'Ctrl+Shift+S', mac: 'Cmd+Shift+S', linux: 'Ctrl+Shift+S', category: ShortcutCategory.fileManager),
  KeyboardShortcut(action: 'Print', windows: 'Ctrl+P', mac: 'Cmd+P', linux: 'Ctrl+P', category: ShortcutCategory.fileManager),
  KeyboardShortcut(action: 'Rename', windows: 'F2', mac: 'Enter (select) / F2', linux: 'F2', category: ShortcutCategory.fileManager),
  KeyboardShortcut(action: 'Delete', windows: 'Del', mac: 'Cmd+Delete', linux: 'Del', category: ShortcutCategory.fileManager),
  KeyboardShortcut(action: 'Permanent Delete', windows: 'Shift+Del', mac: 'Cmd+Option+Delete', linux: 'Shift+Del', category: ShortcutCategory.fileManager),
  KeyboardShortcut(action: 'Go to Line', windows: 'Ctrl+G', mac: 'Cmd+L', linux: 'Ctrl+G', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Toggle Comment', windows: 'Ctrl+/', mac: 'Cmd+/', linux: 'Ctrl+/', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Find in Files', windows: 'Ctrl+Shift+F', mac: 'Cmd+Shift+F', linux: 'Ctrl+Shift+F', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Format Code', windows: 'Ctrl+Shift+I / Alt+Shift+F', mac: 'Cmd+Shift+I / Cmd+Option+F', linux: 'Ctrl+Shift+I', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Build/Run', windows: 'Ctrl+F5 / F5', mac: 'Cmd+F5 / F5', linux: 'Ctrl+F5 / F5', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Debug', windows: 'F9 (breakpoint)', mac: 'F9', linux: 'F9', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Terminal', windows: 'Ctrl+`', mac: 'Cmd+`', linux: 'Ctrl+`', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Split Editor', windows: 'Ctrl+\\', mac: 'Cmd+\\', linux: 'Ctrl+\\', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Close Editor', windows: 'Ctrl+F4', mac: 'Cmd+W', linux: 'Ctrl+F4', category: ShortcutCategory.developer),
  KeyboardShortcut(action: 'Zoom In', windows: 'Ctrl++', mac: 'Cmd++', linux: 'Ctrl++', category: ShortcutCategory.general),
  KeyboardShortcut(action: 'Zoom Out', windows: 'Ctrl+-', mac: 'Cmd+-', linux: 'Ctrl+-', category: ShortcutCategory.general),
  KeyboardShortcut(action: 'Reset Zoom', windows: 'Ctrl+0', mac: 'Cmd+0', linux: 'Ctrl+0', category: ShortcutCategory.general),
  KeyboardShortcut(action: 'Help', windows: 'F1', mac: 'Cmd+?', linux: 'F1', category: ShortcutCategory.general),
  KeyboardShortcut(action: 'Menu', windows: 'F10 / Alt', mac: 'F2', linux: 'F10', category: ShortcutCategory.general),
];

String getShortcutCategoryName(ShortcutCategory category) {
  switch (category) {
    case ShortcutCategory.general:
      return 'General';
    case ShortcutCategory.browser:
      return 'Browser';
    case ShortcutCategory.textEditing:
      return 'Text Editing';
    case ShortcutCategory.fileManager:
      return 'File Manager';
    case ShortcutCategory.developer:
      return 'Developer';
    case ShortcutCategory.system:
      return 'System';
  }
}

Color getShortcutCategoryColor(ShortcutCategory category, ColorScheme colorScheme) {
  switch (category) {
    case ShortcutCategory.general:
      return colorScheme.primary;
    case ShortcutCategory.browser:
      return colorScheme.tertiary;
    case ShortcutCategory.textEditing:
      return colorScheme.secondary;
    case ShortcutCategory.fileManager:
      return colorScheme.tertiary;
    case ShortcutCategory.developer:
      return colorScheme.primary;
    case ShortcutCategory.system:
      return colorScheme.error;
  }
}

class KeyboardShortcutsModel extends ChangeNotifier {
  bool _initialized = false;
  String _searchQuery = '';
  ShortcutCategory? _selectedCategory;
  KeyboardShortcut? _selectedShortcut;

  bool get initialized => _initialized;
  String get searchQuery => _searchQuery;
  ShortcutCategory? get selectedCategory => _selectedCategory;
  KeyboardShortcut? get selectedShortcut => _selectedShortcut;
  List<KeyboardShortcut> get allShortcuts => keyboardShortcuts;

  List<KeyboardShortcut> get filteredShortcuts {
    var shortcuts = keyboardShortcuts;

    if (_selectedCategory != null) {
      shortcuts = shortcuts.where((s) => s.category == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      shortcuts = shortcuts.where((s) =>
        s.action.toLowerCase().contains(query) ||
        s.windows.toLowerCase().contains(query) ||
        s.mac.toLowerCase().contains(query) ||
        s.linux.toLowerCase().contains(query)
      ).toList();
    }

    return shortcuts;
  }

  void init() {
    if (!_initialized) {
      _initialized = true;
      Global.loggerModel.info("KeyboardShortcuts initialized", source: "KeyboardShortcuts");
      notifyListeners();
    }
  }

  void refresh() {
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(ShortcutCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedShortcut(KeyboardShortcut? shortcut) {
    _selectedShortcut = shortcut;
    notifyListeners();
    if (shortcut != null) {
      Global.loggerModel.info("Shortcut selected: ${shortcut.action}", source: "KeyboardShortcuts");
    }
  }

  void clearSelection() {
    _selectedShortcut = null;
    notifyListeners();
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class KeyboardShortcutsCard extends StatefulWidget {
  @override
  State<KeyboardShortcutsCard> createState() => _KeyboardShortcutsCardState();
}

class _KeyboardShortcutsCardState extends State<KeyboardShortcutsCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<KeyboardShortcutsModel>();

    if (!model.initialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.keyboard, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Keyboard Shortcuts', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              SizedBox(height: 12),
              _buildSearchField(context, model),
              SizedBox(height: 8),
              _buildCategoryFilter(context, model),
              SizedBox(height: 12),
              if (model.selectedShortcut != null)
                _buildShortcutDetail(context, model)
              else
                _buildShortcutList(context, model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, KeyboardShortcutsModel model) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search shortcuts (action, key combo)',
        prefixIcon: Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                model.setSearchQuery('');
              },
            )
          : null,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => model.setSearchQuery(value),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, KeyboardShortcutsModel model) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            label: Text('All'),
            onPressed: () => model.setSelectedCategory(null),
            backgroundColor: model.selectedCategory == null
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          ),
          SizedBox(width: 4),
          ...ShortcutCategory.values.map((category) => Padding(
            padding: EdgeInsets.only(left: 4),
            child: ActionChip(
              label: Text(getShortcutCategoryName(category)),
              onPressed: () => model.setSelectedCategory(category),
              backgroundColor: model.selectedCategory == category
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildShortcutList(BuildContext context, KeyboardShortcutsModel model) {
    final shortcuts = model.filteredShortcuts;

    if (shortcuts.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('No shortcuts found', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    return Column(
      children: shortcuts.take(15).map((shortcut) => _buildShortcutTile(context, model, shortcut)).toList(),
    );
  }

  Widget _buildShortcutTile(BuildContext context, KeyboardShortcutsModel model, KeyboardShortcut shortcut) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getShortcutCategoryColor(shortcut.category, colorScheme);

    return ListTile(
      onTap: () => model.setSelectedShortcut(shortcut),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.keyboard_command_key, color: colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Text(shortcut.action),
      subtitle: Text(
        'Win: ${shortcut.windows}',
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      dense: true,
    );
  }

  Widget _buildShortcutDetail(BuildContext context, KeyboardShortcutsModel model) {
    final shortcut = model.selectedShortcut!;
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = getShortcutCategoryColor(shortcut.category, colorScheme);

    return Card(
      color: categoryColor.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shortcut.action, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(getShortcutCategoryName(shortcut.category), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => model.clearSelection(),
                  tooltip: 'Close detail',
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPlatformRow('Windows', shortcut.windows, colorScheme),
            SizedBox(height: 8),
            _buildPlatformRow('Mac', shortcut.mac, colorScheme),
            SizedBox(height: 8),
            _buildPlatformRow('Linux', shortcut.linux, colorScheme),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    final text = '${shortcut.action}\nWindows: ${shortcut.windows}\nMac: ${shortcut.mac}\nLinux: ${shortcut.linux}';
                    model.copyToClipboard(text, context);
                  },
                  child: Text('Copy All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformRow(String platform, String shortcut, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 80,
          child: Text(platform, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(shortcut, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}