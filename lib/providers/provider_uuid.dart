import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

UUIDModel uuidModel = UUIDModel();

MyProvider providerUUID = MyProvider(
    name: "UUID",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Generate UUID',
      keywords: 'uuid guid id unique identifier generate random',
      action: () {
        uuidModel.generateUUIDv4();
        Global.infoModel.addInfo(
            "UUID",
            "UUID Generator",
            subtitle: "Tap to generate new UUID",
            icon: Icon(Icons.fingerprint),
            onTap: () => uuidModel.generateUUIDv4());
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  uuidModel.init();
  Global.infoModel.addInfoWidget(
      "UUID",
      ChangeNotifierProvider.value(
          value: uuidModel,
          builder: (context, child) => UUIDCard()),
      title: "UUID Generator");
}

Future<void> _update() async {
  uuidModel.refresh();
}

class UUIDModel extends ChangeNotifier {
  final Random _random = Random();
  bool _isInitialized = false;

  String _uuidv4Result = "";
  String _uuidv1Result = "";
  int _generationCount = 0;
  List<String> _history = [];

  bool get isInitialized => _isInitialized;
  String get uuidv4Result => _uuidv4Result;
  String get uuidv1Result => _uuidv1Result;
  int get generationCount => _generationCount;
  List<String> get history => List.from(_history);

  void init() {
    _isInitialized = true;
    generateUUIDv4();
    Global.loggerModel.info("UUID initialized", source: "UUID");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  String generateUUIDv4() {
    final bytes = List.generate(16, (_) => _random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    _uuidv4Result =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';

    _generationCount++;
    addToHistory(_uuidv4Result);
    Global.loggerModel.info("UUID v4 generated: $_uuidv4Result", source: "UUID");
    notifyListeners();
    return _uuidv4Result;
  }

  String generateUUIDv1() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final timestampHex = timestamp.toRadixString(16).padLeft(16, '0');

    final clockSeq = _random.nextInt(16384);
    final clockSeqHex = clockSeq.toRadixString(16).padLeft(4, '0');

    final nodeBytes = List.generate(6, (_) => _random.nextInt(256));
    final nodeHex = nodeBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    _uuidv1Result =
        '${timestampHex.substring(0, 8)}-${timestampHex.substring(8, 12)}-${timestampHex.substring(12, 16)}-${clockSeqHex}-${nodeHex}';

    _generationCount++;
    addToHistory(_uuidv1Result);
    Global.loggerModel.info("UUID v1 generated: $_uuidv1Result", source: "UUID");
    notifyListeners();
    return _uuidv1Result;
  }

  String generateShortUUID() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(1000000);
    _uuidv4Result = '${timestamp}x${randomPart.toString().padLeft(6, '0')}';
    _generationCount++;
    addToHistory(_uuidv4Result);
    Global.loggerModel.info("Short UUID generated: $_uuidv4Result", source: "UUID");
    notifyListeners();
    return _uuidv4Result;
  }

  void addToHistory(String uuid) {
    if (uuid.isEmpty) return;
    _history.insert(0, uuid);
    if (_history.length > 10) {
      _history = _history.sublist(0, 10);
    }
  }

  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    Global.loggerModel.info("UUID history cleared", source: "UUID");
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("UUID copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String generateNoDashUUID() {
    final uuid = generateUUIDv4();
    return uuid.replaceAll('-', '');
  }
}

class UUIDCard extends StatefulWidget {
  @override
  State<UUIDCard> createState() => _UUIDCardState();
}

class _UUIDCardState extends State<UUIDCard> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final uuid = context.watch<UUIDModel>();

    if (!uuid.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.fingerprint, size: 24),
              SizedBox(width: 12),
              Text("UUID: Loading..."),
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
              children: [
                Icon(Icons.fingerprint, size: 20),
                SizedBox(width: 8),
                Text(
                  "UUID Generator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${uuid.generationCount}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildUUIDDisplay(context, uuid),
            SizedBox(height: 12),
            _buildUUIDActions(context, uuid),
            SizedBox(height: 12),
            _buildHistorySection(context, uuid),
          ],
        ),
      ),
    );
  }

  Widget _buildUUIDDisplay(BuildContext context, UUIDModel uuid) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "UUID v4:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 8),
            SelectableText(
              uuid.uuidv4Result,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "No dashes: ${uuid.uuidv4Result.replaceAll('-', '')}",
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUUIDActions(BuildContext context, UUIDModel uuid) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: Icon(Icons.refresh, size: 16),
          label: Text("Generate v4"),
          onPressed: () => uuid.generateUUIDv4(),
        ),
        ActionChip(
          avatar: Icon(Icons.timer, size: 16),
          label: Text("Generate v1"),
          onPressed: () => uuid.generateUUIDv1(),
        ),
        ActionChip(
          avatar: Icon(Icons.compress, size: 16),
          label: Text("Short ID"),
          onPressed: () => uuid.generateShortUUID(),
        ),
        ActionChip(
          avatar: Icon(Icons.copy, size: 16),
          label: Text("Copy"),
          onPressed: () => uuid.copyToClipboard(uuid.uuidv4Result, context),
        ),
        ActionChip(
          avatar: Icon(Icons.history, size: 16),
          label: Text("History (${uuid.history.length})"),
          onPressed: () {
            setState(() {
              _showHistory = !_showHistory;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, UUIDModel uuid) {
    if (!_showHistory || uuid.history.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "History:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Spacer(),
                if (uuid.history.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Clear History"),
                          content: Text("Clear all ${uuid.history.length} UUIDs from history?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                uuid.clearHistory();
                                Navigator.pop(context);
                              },
                              child: Text("Clear"),
                            ),
                          ],
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text("Clear", style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            SizedBox(height: 8),
            SizedBox(
              height: uuid.history.length * 24.0,
              child: ListView.builder(
                itemCount: uuid.history.length,
                itemBuilder: (context, index) {
                  final historyUuid = uuid.history[index];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: SelectableText(
                      historyUuid,
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.copy, size: 14),
                      onPressed: () => uuid.copyToClipboard(historyUuid, context),
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}