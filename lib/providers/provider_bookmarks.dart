import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

BookmarksModel bookmarksModel = BookmarksModel();

MyProvider providerBookmarks = MyProvider(
    name: "Bookmarks",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Quick bookmark',
      keywords: 'bookmark bookmarks url link website save quick',
      action: () {
        Global.infoModel.addInfo("AddBookmark", "Add Quick Bookmark",
            subtitle: "Tap to add a new bookmark",
            icon: Icon(Icons.bookmark_add),
            onTap: () => _showAddBookmarkDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await bookmarksModel.init();
  Global.infoModel.addInfoWidget(
      "Bookmarks",
      ChangeNotifierProvider.value(
          value: bookmarksModel,
          builder: (context, child) => BookmarksCard()),
      title: "Quick Bookmarks");
}

Future<void> _update() async {
  await bookmarksModel.refresh();
}

void _showAddBookmarkDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddBookmarkDialog(),
  );
}

void _showEditBookmarkDialog(BuildContext context, int index, Bookmark bookmark) {
  showDialog(
    context: context,
    builder: (context) => EditBookmarkDialog(index: index, bookmark: bookmark),
  );
}

class Bookmark {
  final String url;
  final String title;
  
  Bookmark({required this.url, required this.title});
  
  Map<String, dynamic> toMap() => {'url': url, 'title': title};
  
  factory Bookmark.fromMap(Map<String, dynamic> map) => 
      Bookmark(url: map['url'] ?? '', title: map['title'] ?? '');
  
  String toJson() => '${title}|${url}';
  
  factory Bookmark.fromJson(String json) {
    final parts = json.split('|');
    if (parts.length >= 2) {
      return Bookmark(title: parts[0], url: parts[1]);
    }
    return Bookmark(title: json, url: '');
  }
}

class BookmarksModel extends ChangeNotifier {
  List<Bookmark> _bookmarks = [];
  static const int maxBookmarks = 15;
  static const String _bookmarksKey = 'Bookmarks.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  int get length => _bookmarks.length;
  bool get isInitialized => _isInitialized;
  bool get hasBookmarks => _bookmarks.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadBookmarks();
    _isInitialized = true;
    Global.loggerModel.info("Bookmarks initialized with ${_bookmarks.length} bookmarks", source: "Bookmarks");
    notifyListeners();
  }

  Future<void> _loadBookmarks() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final bookmarksData = prefs.getStringList(_bookmarksKey);
    if (bookmarksData != null) {
      _bookmarks = bookmarksData.map((data) => Bookmark.fromJson(data)).toList();
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    try {
      final bookmarksData = _bookmarks.map((b) => b.toJson()).toList();
      await prefs.setStringList(_bookmarksKey, bookmarksData);
      Global.loggerModel.info("Saved ${_bookmarks.length} bookmarks", source: "Bookmarks");
    } catch (e) {
      Global.loggerModel.error("Failed to save bookmarks: $e", source: "Bookmarks");
    }
  }

  Future<void> refresh() async {
    await _loadBookmarks();
    notifyListeners();
    Global.loggerModel.info("Bookmarks refreshed", source: "Bookmarks");
  }

  void addBookmark(String url, String title) {
    if (url.trim().isEmpty) return;
    
    final normalizedUrl = _normalizeUrl(url.trim());
    final bookmarkTitle = title.trim().isEmpty ? _extractTitleFromUrl(normalizedUrl) : title.trim();
    
    _bookmarks.insert(0, Bookmark(url: normalizedUrl, title: bookmarkTitle));
    
    if (_bookmarks.length > maxBookmarks) {
      _bookmarks.removeLast();
    }
    
    notifyListeners();
    _saveBookmarks();
    Global.loggerModel.info("Added bookmark: $bookmarkTitle", source: "Bookmarks");
  }

  void updateBookmark(int index, String url, String title) {
    if (index < 0 || index >= _bookmarks.length) return;
    if (url.trim().isEmpty) {
      deleteBookmark(index);
      return;
    }
    
    final normalizedUrl = _normalizeUrl(url.trim());
    final bookmarkTitle = title.trim().isEmpty ? _extractTitleFromUrl(normalizedUrl) : title.trim();
    
    _bookmarks[index] = Bookmark(url: normalizedUrl, title: bookmarkTitle);
    notifyListeners();
    _saveBookmarks();
    Global.loggerModel.info("Updated bookmark at index $index", source: "Bookmarks");
  }

  void deleteBookmark(int index) {
    if (index < 0 || index >= _bookmarks.length) return;
    
    _bookmarks.removeAt(index);
    notifyListeners();
    _saveBookmarks();
    Global.loggerModel.info("Deleted bookmark at index $index", source: "Bookmarks");
  }

  void clearAllBookmarks() {
    _bookmarks.clear();
    notifyListeners();
    _saveBookmarks();
    Global.loggerModel.info("Cleared all bookmarks", source: "Bookmarks");
  }

  String _normalizeUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  String _extractTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.replaceAll('www.', '');
      return host.split('.')[0].capitalize();
    } catch (e) {
      return url;
    }
  }

  Future<void> openBookmark(int index) async {
    if (index < 0 || index >= _bookmarks.length) return;
    
    final url = _bookmarks[index].url;
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Global.loggerModel.info("Opened bookmark: $url", source: "Bookmarks");
      } else {
        Global.loggerModel.error("Cannot launch URL: $url", source: "Bookmarks");
      }
    } catch (e) {
      Global.loggerModel.error("Error launching URL: $e", source: "Bookmarks");
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class BookmarksCard extends StatefulWidget {
  @override
  State<BookmarksCard> createState() => _BookmarksCardState();
}

class _BookmarksCardState extends State<BookmarksCard> {
  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarksModel>();
    
    if (!bookmarks.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.bookmark, size: 24),
              SizedBox(width: 12),
              Text("Bookmarks: Loading..."),
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
                  "Quick Bookmarks",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bookmarks.hasBookmarks)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear all bookmarks",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddBookmarkDialog(context),
                      tooltip: "Add bookmark",
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!bookmarks.hasBookmarks)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No bookmarks yet. Tap + to add.",
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
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks.bookmarks[index];
                  return _buildBookmarkItem(context, index, bookmark);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookmarkItem(BuildContext context, int index, Bookmark bookmark) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(Icons.link, size: 20),
      title: Text(
        bookmark.title,
        style: TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        bookmark.url,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.read<BookmarksModel>().openBookmark(index),
      onLongPress: () => _showEditBookmarkDialog(context, index, bookmark),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 16),
        onPressed: () => context.read<BookmarksModel>().deleteBookmark(index),
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
        title: Text("Clear All Bookmarks"),
        content: Text("This will delete all bookmarks. This action cannot be undone."),
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
      context.read<BookmarksModel>().clearAllBookmarks();
    }
  }
}

class AddBookmarkDialog extends StatefulWidget {
  @override
  State<AddBookmarkDialog> createState() => _AddBookmarkDialogState();
}

class _AddBookmarkDialogState extends State<AddBookmarkDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  
  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Quick Bookmark"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: "URL",
              hintText: "https://example.com",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Title (optional)",
              hintText: "Example Site",
              border: OutlineInputBorder(),
            ),
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
            if (_urlController.text.trim().isNotEmpty) {
              context.read<BookmarksModel>().addBookmark(
                _urlController.text,
                _titleController.text,
              );
              Navigator.pop(context);
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class EditBookmarkDialog extends StatefulWidget {
  final int index;
  final Bookmark bookmark;
  
  const EditBookmarkDialog({
    required this.index,
    required this.bookmark,
  });
  
  @override
  State<EditBookmarkDialog> createState() => _EditBookmarkDialogState();
}

class _EditBookmarkDialogState extends State<EditBookmarkDialog> {
  late TextEditingController _urlController;
  late TextEditingController _titleController;
  
  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.bookmark.url);
    _titleController = TextEditingController(text: widget.bookmark.title);
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Bookmark"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: "URL",
              hintText: "https://example.com",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Title (optional)",
              hintText: "Example Site",
              border: OutlineInputBorder(),
            ),
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
            context.read<BookmarksModel>().updateBookmark(
              widget.index,
              _urlController.text,
              _titleController.text,
            );
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}