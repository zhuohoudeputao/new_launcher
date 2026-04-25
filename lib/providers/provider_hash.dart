import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

HashGeneratorModel hashGeneratorModel = HashGeneratorModel();

MyProvider providerHashGenerator = MyProvider(
    name: "HashGenerator",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'MD5 Hash',
      keywords: 'md5 hash generate digest checksum security',
      action: () {
        hashGeneratorModel.setMode('md5');
        Global.infoModel.addInfo(
            "MD5Hash",
            "MD5 Hash",
            subtitle: "Generate MD5 hash from text",
            icon: Icon(Icons.fingerprint, size: 24),
            onTap: () => hashGeneratorModel.setMode('md5'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'SHA1 Hash',
      keywords: 'sha1 sha-1 hash generate digest checksum security',
      action: () {
        hashGeneratorModel.setMode('sha1');
        Global.infoModel.addInfo(
            "SHA1Hash",
            "SHA1 Hash",
            subtitle: "Generate SHA1 hash from text",
            icon: Icon(Icons.fingerprint, size: 24),
            onTap: () => hashGeneratorModel.setMode('sha1'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'SHA256 Hash',
      keywords: 'sha256 sha-256 hash generate digest checksum security',
      action: () {
        hashGeneratorModel.setMode('sha256');
        Global.infoModel.addInfo(
            "SHA256Hash",
            "SHA256 Hash",
            subtitle: "Generate SHA256 hash from text",
            icon: Icon(Icons.fingerprint, size: 24),
            onTap: () => hashGeneratorModel.setMode('sha256'));
      },
      times: List.generate(24, (index) => 0),
    ),
    MyAction(
      name: 'SHA512 Hash',
      keywords: 'sha512 sha-512 hash generate digest checksum security',
      action: () {
        hashGeneratorModel.setMode('sha512');
        Global.infoModel.addInfo(
            "SHA512Hash",
            "SHA512 Hash",
            subtitle: "Generate SHA512 hash from text",
            icon: Icon(Icons.fingerprint, size: 24),
            onTap: () => hashGeneratorModel.setMode('sha512'));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  hashGeneratorModel.init();
  Global.infoModel.addInfoWidget(
      "HashGenerator",
      ChangeNotifierProvider.value(
          value: hashGeneratorModel,
          builder: (context, child) => HashGeneratorCard()),
      title: "Hash Generator");
}

Future<void> _update() async {
  hashGeneratorModel.refresh();
}

class HashGeneratorModel extends ChangeNotifier {
  bool _isInitialized = false;
  String _inputText = "";
  String _outputHash = "";
  String _mode = "sha256";
  List<_HistoryEntry> _history = [];

  bool get isInitialized => _isInitialized;
  String get inputText => _inputText;
  String get outputHash => _outputHash;
  String get mode => _mode;
  List<_HistoryEntry> get history => _history;

  static const List<String> modes = ['md5', 'sha1', 'sha256', 'sha512'];

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("HashGenerator initialized", source: "HashGenerator");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setInputText(String text) {
    _inputText = text;
    _process();
  }

  void setMode(String mode) {
    if (modes.contains(mode)) {
      _mode = mode;
      _process();
    }
  }

  void clearInput() {
    _inputText = "";
    _outputHash = "";
    notifyListeners();
  }

  void _process() {
    if (_inputText.isEmpty) {
      _outputHash = "";
      notifyListeners();
      return;
    }

    try {
      final bytes = utf8.encode(_inputText);
      switch (_mode) {
        case 'md5':
          _outputHash = md5.convert(bytes).toString();
          break;
        case 'sha1':
          _outputHash = sha1.convert(bytes).toString();
          break;
        case 'sha256':
          _outputHash = sha256.convert(bytes).toString();
          break;
        case 'sha512':
          _outputHash = sha512.convert(bytes).toString();
          break;
      }
      Global.loggerModel.info("Generated $_mode hash", source: "HashGenerator");
    } catch (e) {
      _outputHash = "";
      Global.loggerModel.warning("Hash generation error: $e", source: "HashGenerator");
    }
    notifyListeners();
  }

  void addToHistory() {
    if (_outputHash.isNotEmpty) {
      _history.insert(0, _HistoryEntry(
        input: _inputText,
        hash: _outputHash,
        mode: _mode,
        timestamp: DateTime.now(),
      ));
      if (_history.length > 10) {
        _history.removeLast();
      }
      Global.loggerModel.info("Added to history: $_mode hash", source: "HashGenerator");
      notifyListeners();
    }
  }

  void loadFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      final entry = _history[index];
      _inputText = entry.input;
      _mode = entry.mode;
      _process();
      Global.loggerModel.info("Loaded from history: index $index", source: "HashGenerator");
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    Global.loggerModel.info("History cleared", source: "HashGenerator");
    notifyListeners();
  }

  void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Hash copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String getModeLabel(String mode) {
    switch (mode) {
      case 'md5': return 'MD5';
      case 'sha1': return 'SHA1';
      case 'sha256': return 'SHA256';
      case 'sha512': return 'SHA512';
      default: return mode.toUpperCase();
    }
  }

  int getHashLength(String mode) {
    switch (mode) {
      case 'md5': return 32;
      case 'sha1': return 40;
      case 'sha256': return 64;
      case 'sha512': return 128;
      default: return 0;
    }
  }
}

class _HistoryEntry {
  final String input;
  final String hash;
  final String mode;
  final DateTime timestamp;

  _HistoryEntry({
    required this.input,
    required this.hash,
    required this.mode,
    required this.timestamp,
  });
}

class HashGeneratorCard extends StatefulWidget {
  @override
  State<HashGeneratorCard> createState() => _HashGeneratorCardState();
}

class _HashGeneratorCardState extends State<HashGeneratorCard> {
  final TextEditingController _inputController = TextEditingController();
  bool _showHistory = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HashGeneratorModel>();

    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.fingerprint, size: 24),
              SizedBox(width: 12),
              Text("Hash Generator: Loading..."),
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
            _buildHeader(context, model),
            SizedBox(height: 12),
            _buildModeSelector(context, model),
            SizedBox(height: 12),
            _buildInputField(context, model),
            if (model.outputHash.isNotEmpty) _buildOutputField(context, model),
            SizedBox(height: 8),
            _buildActionButtons(context, model),
            if (_showHistory && model.history.isNotEmpty) ...[
              SizedBox(height: 12),
              _buildHistorySection(context, model),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HashGeneratorModel model) {
    return Row(
      children: [
        Icon(Icons.fingerprint, size: 20),
        SizedBox(width: 8),
        Text(
          "Hash Generator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Spacer(),
        if (model.history.isNotEmpty)
          IconButton(
            icon: Icon(_showHistory ? Icons.history : Icons.history_outlined, size: 18),
            onPressed: () {
              setState(() => _showHistory = !_showHistory);
            },
            tooltip: "History",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context, HashGeneratorModel model) {
    return SegmentedButton<String>(
      segments: HashGeneratorModel.modes.map((mode) =>
        ButtonSegment(
          value: mode,
          label: Text(model.getModeLabel(mode)),
        )
      ).toList(),
      selected: {model.mode},
      onSelectionChanged: (Set<String> newSelection) {
        model.setMode(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }

  Widget _buildInputField(BuildContext context, HashGeneratorModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Input:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: "Enter text to hash...",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: TextStyle(fontSize: 12),
              maxLines: 3,
              onChanged: (value) => model.setInputText(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputField(BuildContext context, HashGeneratorModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text("${model.getModeLabel(model.mode)} (${model.getHashLength(model.mode)} chars):",
                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, size: 14),
                  onPressed: () => model.copyToClipboard(model.outputHash, context),
                  tooltip: "Copy",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: Size(24, 24),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            SelectableText(
              model.outputHash,
              style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, HashGeneratorModel model) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.clear, size: 18),
          onPressed: () {
            _inputController.clear();
            model.clearInput();
          },
          tooltip: "Clear",
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
        if (model.outputHash.isNotEmpty)
          IconButton(
            icon: Icon(Icons.save_outlined, size: 18),
            onPressed: () => model.addToHistory(),
            tooltip: "Save to history",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, HashGeneratorModel model) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 16),
                SizedBox(width: 8),
                Text("History (${model.history.length})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 14),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Clear History"),
                        content: Text("Clear all ${model.history.length} history entries?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              model.clearHistory();
                              Navigator.pop(context);
                            },
                            child: Text("Clear"),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: "Clear history",
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: Size(24, 24),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...model.history.asMap().entries.map((entry) {
              final index = entry.key;
              final historyItem = entry.value;
              return ListTile(
                dense: true,
                leading: Text("${index + 1}", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.secondary)),
                title: Text(
                  "${model.getModeLabel(historyItem.mode)} Hash",
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  historyItem.input.length > 30 ? "${historyItem.input.substring(0, 30)}..." : historyItem.input,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {
                  model.loadFromHistory(index);
                  _inputController.text = model.inputText;
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}