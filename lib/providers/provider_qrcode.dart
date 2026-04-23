import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

QRModel qrModel = QRModel();

MyProvider providerQRCode = MyProvider(
    name: "QRCode",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'QR Generator',
      keywords: 'qr qrcode code generate barcode scan share',
      action: () {
        Global.infoModel.addInfo("GenerateQR", "Generate QR Code",
            subtitle: "Tap to create a QR code",
            icon: Icon(Icons.qr_code),
            onTap: () => _showQRGeneratorDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  qrModel.init();
  Global.infoModel.addInfoWidget(
      "QRCode",
      ChangeNotifierProvider.value(
          value: qrModel,
          builder: (context, child) => QRCard()),
      title: "QR Code Generator");
}

Future<void> _update() async {
  qrModel.refresh();
}

void _showQRGeneratorDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => QRGeneratorDialog(),
  );
}

class QRModel extends ChangeNotifier {
  String _currentText = "";
  bool _isInitialized = false;

  String get currentText => _currentText;
  bool get isInitialized => _isInitialized;
  bool get hasQR => _currentText.isNotEmpty;

  void init() {
    _isInitialized = true;
    Global.loggerModel.info("QR Code initialized", source: "QRCode");
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void setText(String text) {
    _currentText = text.trim();
    notifyListeners();
    if (_currentText.isNotEmpty) {
      Global.loggerModel.info("QR code text set: ${_currentText.length > 20 ? _currentText.substring(0, 20) : _currentText}...", source: "QRCode");
    }
  }

  void clearText() {
    _currentText = "";
    notifyListeners();
    Global.loggerModel.info("QR code cleared", source: "QRCode");
  }
}

class QRCard extends StatefulWidget {
  @override
  State<QRCard> createState() => _QRCardState();
}

class _QRCardState extends State<QRCard> {
  @override
  Widget build(BuildContext context) {
    final qr = context.watch<QRModel>();
    
    if (!qr.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.qr_code, size: 24),
              SizedBox(width: 12),
              Text("QR Code: Loading..."),
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
                  "QR Code Generator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 18),
                  onPressed: () => _showQRGeneratorDialog(context),
                  tooltip: "Generate QR code",
                ),
              ],
            ),
            SizedBox(height: 12),
            if (!qr.hasQR)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Enter text to generate QR code",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(
                        data: qr.currentText,
                        version: QrVersions.auto,
                        size: 150,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      qr.currentText.length > 30 
                          ? '${qr.currentText.substring(0, 30)}...'
                          : qr.currentText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy, size: 16),
                          onPressed: () {
                            _copyToClipboard(context, qr.currentText);
                          },
                          tooltip: "Copy text",
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear, size: 16),
                          onPressed: () => qr.clearText(),
                          tooltip: "Clear QR code",
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Text copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
    Global.loggerModel.info("QR code text copied to clipboard", source: "QRCode");
  }
}

class QRGeneratorDialog extends StatefulWidget {
  @override
  State<QRGeneratorDialog> createState() => _QRGeneratorDialogState();
}

class _QRGeneratorDialogState extends State<QRGeneratorDialog> {
  final TextEditingController _controller = TextEditingController();
  String _selectedType = "text";
  
  @override
  void initState() {
    super.initState();
    final qr = context.read<QRModel>();
    _controller.text = qr.currentText;
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Generate QR Code"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: "text", label: Text("Text"), icon: Icon(Icons.text_fields, size: 16)),
              ButtonSegment(value: "url", label: Text("URL"), icon: Icon(Icons.link, size: 16)),
              ButtonSegment(value: "email", label: Text("Email"), icon: Icon(Icons.email, size: 16)),
              ButtonSegment(value: "phone", label: Text("Phone"), icon: Icon(Icons.phone, size: 16)),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _selectedType = newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: _getHintText(),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
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
              final formattedText = _formatText(_controller.text.trim());
              context.read<QRModel>().setText(formattedText);
              Navigator.pop(context);
            }
          },
          child: Text("Generate"),
        ),
      ],
    );
  }
  
  String _getHintText() {
    switch (_selectedType) {
      case "url":
        return "https://example.com";
      case "email":
        return "email@example.com";
      case "phone":
        return "+1234567890";
      case "wifi":
        return "WIFI:S:network_name;T:WPA;P:password;;";
      default:
        return "Enter text...";
    }
  }
  
  String _formatText(String text) {
    switch (_selectedType) {
      case "url":
        if (!text.startsWith('http://') && !text.startsWith('https://')) {
          return 'https://$text';
        }
        return text;
      case "email":
        return 'mailto:$text';
      case "phone":
        return 'tel:$text';
      default:
        return text;
    }
  }
}