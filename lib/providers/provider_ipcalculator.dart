import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';

IPCalculatorModel ipCalculatorModel = IPCalculatorModel();

MyProvider providerIPCalculator = MyProvider(
    name: "IPCalculator",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'IP Calculator',
      keywords: 'ip calculator subnet network cidr mask broadcast host address ipv4',
      action: () => ipCalculatorModel.refresh(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  ipCalculatorModel.init();
  Global.infoModel.addInfoWidget(
      "IPCalculator",
      ChangeNotifierProvider.value(
          value: ipCalculatorModel,
          builder: (context, child) => IPCalculatorCard()),
      title: "IP Calculator");
}

Future<void> _update() async {
  ipCalculatorModel.refresh();
}

class IPCalculationHistory {
  final String ipAddress;
  final int cidr;
  final DateTime timestamp;

  IPCalculationHistory({
    required this.ipAddress,
    required this.cidr,
    required this.timestamp,
  });

  String get display => '$ipAddress/$cidr';
  
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class IPCalculatorModel extends ChangeNotifier {
  String _ipAddress = '192.168.1.100';
  int _cidr = 24;
  List<IPCalculationHistory> _history = [];
  bool _isInitialized = false;

  static const int maxHistoryLength = 10;

  String get ipAddress => _ipAddress;
  int get cidr => _cidr;
  List<IPCalculationHistory> get history => _history;
  bool get isInitialized => _isInitialized;
  bool get hasHistory => _history.isNotEmpty;

  int? get ipAsInt => _parseIP(_ipAddress);
  int get subnetMask => _getSubnetMask(_cidr);
  int? get networkAddress => ipAsInt != null ? ipAsInt! & subnetMask : null;
  int? get broadcastAddress => ipAsInt != null ? networkAddress! | (~subnetMask & 0xFFFFFFFF) : null;
  int get numberOfHosts => _cidr >= 31 ? 0 : (1 << (32 - _cidr)) - 2;
  int? get firstUsableHost => networkAddress != null && _cidr < 31 ? networkAddress! + 1 : null;
  int? get lastUsableHost => broadcastAddress != null && _cidr < 31 ? broadcastAddress! - 1 : null;
  
  String get subnetMaskDecimal => _formatIP(subnetMask);
  String get subnetMaskBinary => _formatBinary(subnetMask);
  String get networkAddressDecimal => networkAddress != null ? _formatIP(networkAddress!) : 'Invalid';
  String get broadcastAddressDecimal => broadcastAddress != null ? _formatIP(broadcastAddress!) : 'Invalid';
  String get firstUsableHostDecimal => firstUsableHost != null ? _formatIP(firstUsableHost!) : 'N/A';
  String get lastUsableHostDecimal => lastUsableHost != null ? _formatIP(lastUsableHost!) : 'N/A';
  
  String get ipClass {
    if (ipAsInt == null) return 'Invalid';
    int firstOctet = (ipAsInt! >> 24) & 0xFF;
    if (firstOctet < 128) return 'A';
    if (firstOctet < 192) return 'B';
    if (firstOctet < 224) return 'C';
    if (firstOctet < 240) return 'D (Multicast)';
    return 'E (Reserved)';
  }
  
  String get ipType {
    if (ipAsInt == null) return 'Invalid';
    int firstOctet = (ipAsInt! >> 24) & 0xFF;
    int secondOctet = (ipAsInt! >> 16) & 0xFF;
    if (firstOctet == 10) return 'Private';
    if (firstOctet == 172 && secondOctet >= 16 && secondOctet <= 31) return 'Private';
    if (firstOctet == 192 && secondOctet == 168) return 'Private';
    if (firstOctet == 127) return 'Loopback';
    if (firstOctet == 0) return 'This Network';
    if (firstOctet >= 224 && firstOctet <= 239) return 'Multicast';
    if (firstOctet == 255) return 'Broadcast';
    if (firstOctet >= 240) return 'Reserved';
    return 'Public';
  }

  bool get isValidIP => _isValidIPAddress(_ipAddress);
  bool get isValidCIDR => _cidr >= 0 && _cidr <= 32;

  void init() {
    _isInitialized = true;
    notifyListeners();
  }

  void setIPAddress(String ip) {
    _ipAddress = ip;
    notifyListeners();
  }

  void setCIDR(int value) {
    _cidr = value.clamp(0, 32);
    notifyListeners();
  }

  int? _parseIP(String ip) {
    if (!_isValidIPAddress(ip)) return null;
    List<String> parts = ip.split('.');
    int result = 0;
    for (int i = 0; i < 4; i++) {
      result = (result << 8) | int.parse(parts[i]);
    }
    return result;
  }

  bool _isValidIPAddress(String ip) {
    List<String> parts = ip.split('.');
    if (parts.length != 4) return false;
    for (String part in parts) {
      int? value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return false;
    }
    return true;
  }

  int _getSubnetMask(int cidr) {
    if (cidr == 0) return 0;
    if (cidr == 32) return 0xFFFFFFFF;
    return (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF;
  }

  String _formatIP(int ip) {
    return '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.${ip & 0xFF}';
  }

  String _formatBinary(int ip) {
    String binary = ip.toRadixString(2).padLeft(32, '0');
    return '${binary.substring(0, 8)}.${binary.substring(8, 16)}.${binary.substring(16, 24)}.${binary.substring(24, 32)}';
  }

  void addToHistory() {
    if (!isValidIP) return;
    
    IPCalculationHistory entry = IPCalculationHistory(
      ipAddress: _ipAddress,
      cidr: _cidr,
      timestamp: DateTime.now(),
    );
    
    _history.insert(0, entry);
    if (_history.length > maxHistoryLength) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void applyFromHistory(IPCalculationHistory entry) {
    _ipAddress = entry.ipAddress;
    _cidr = entry.cidr;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}

class IPCalculatorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = context.watch<IPCalculatorModel>();
    
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
                  Icon(Icons.router, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text('IP Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              SizedBox(height: 16),
              
              _buildInputSection(context, model),
              SizedBox(height: 16),
              
              if (model.isValidIP && model.isValidCIDR)
                _buildResultsSection(context, model),
              
              SizedBox(height: 16),
              _buildHistorySection(context, model),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, IPCalculatorModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('IP Address / CIDR', style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '192.168.1.100',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  errorText: model.isValidIP ? null : 'Invalid IP',
                ),
                controller: TextEditingController(text: model.ipAddress),
                onChanged: (value) => model.setIPAddress(value),
              ),
            ),
            SizedBox(width: 8),
            Text('/'),
            SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '24',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                controller: TextEditingController(text: model.cidr.toString()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  int? cidr = int.tryParse(value);
                  if (cidr != null) model.setCIDR(cidr);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsSection(BuildContext context, IPCalculatorModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        SizedBox(height: 12),
        _buildResultRow(context, 'Subnet Mask', model.subnetMaskDecimal, model.subnetMaskBinary),
        _buildResultRow(context, 'Network Address', model.networkAddressDecimal, null),
        _buildResultRow(context, 'Broadcast Address', model.broadcastAddressDecimal, null),
        _buildResultRow(context, 'First Usable Host', model.firstUsableHostDecimal, null),
        _buildResultRow(context, 'Last Usable Host', model.lastUsableHostDecimal, null),
        _buildResultRow(context, 'Number of Hosts', model.numberOfHosts.toString(), null),
        _buildResultRow(context, 'IP Class', model.ipClass, null),
        _buildResultRow(context, 'IP Type', model.ipType, null),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: Icon(Icons.save),
              label: Text('Save to History'),
              onPressed: () => model.addToHistory(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultRow(BuildContext context, String label, String value, String? secondary) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(value, style: TextStyle(fontWeight: FontWeight.w500)),
                if (secondary != null)
                  SelectableText(secondary, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, IPCalculatorModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (model.hasHistory)
          Row(
            children: [
              Text('History', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              TextButton(
                child: Text('Clear'),
                onPressed: () => model.clearHistory(),
              ),
            ],
          ),
        if (model.hasHistory)
          SizedBox(height: 8),
        if (model.hasHistory)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: model.history.map((entry) => ActionChip(
              label: Text(entry.display),
              onPressed: () => model.applyFromHistory(entry),
            )).toList(),
          ),
      ],
    );
  }
}