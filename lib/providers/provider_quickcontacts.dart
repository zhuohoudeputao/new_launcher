import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

QuickContactsModel quickContactsModel = QuickContactsModel();

MyProvider providerQuickContacts = MyProvider(
    name: "QuickContacts",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Quick contacts',
      keywords: 'contact contacts quick dial phone call speed speeddial',
      action: () {
        Global.infoModel.addInfo("AddQuickContact", "Add Quick Contact",
            subtitle: "Tap to add a new contact",
            icon: Icon(Icons.contact_page),
            onTap: () => _showAddContactDialog(navigatorKey.currentContext!));
      },
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await quickContactsModel.init();
  Global.infoModel.addInfoWidget(
      "QuickContacts",
      ChangeNotifierProvider.value(
          value: quickContactsModel,
          builder: (context, child) => QuickContactsCard()),
      title: "Quick Contacts");
}

Future<void> _update() async {
  await quickContactsModel.refresh();
}

void _showAddContactDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AddContactDialog(),
  );
}

void _showEditContactDialog(BuildContext context, int index, QuickContact contact) {
  showDialog(
    context: context,
    builder: (context) => EditContactDialog(index: index, contact: contact),
  );
}

class QuickContact {
  final String name;
  final String phone;
  
  QuickContact({required this.name, required this.phone});
  
  Map<String, dynamic> toMap() => {'name': name, 'phone': phone};
  
  factory QuickContact.fromMap(Map<String, dynamic> map) => 
      QuickContact(name: map['name'] ?? '', phone: map['phone'] ?? '');
  
  String toJson() => '${name}|${phone}';
  
  factory QuickContact.fromJson(String json) {
    final parts = json.split('|');
    if (parts.length >= 2) {
      return QuickContact(name: parts[0], phone: parts[1]);
    }
    return QuickContact(name: json, phone: '');
  }
}

class QuickContactsModel extends ChangeNotifier {
  List<QuickContact> _contacts = [];
  static const int maxContacts = 15;
  static const String _contactsKey = 'QuickContacts.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  List<QuickContact> get contacts => List.unmodifiable(_contacts);
  int get length => _contacts.length;
  bool get isInitialized => _isInitialized;
  bool get hasContacts => _contacts.isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadContacts();
    _isInitialized = true;
    Global.loggerModel.info("Quick Contacts initialized with ${_contacts.length} contacts", source: "QuickContacts");
    notifyListeners();
  }

  Future<void> _loadContacts() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    final contactsData = prefs.getStringList(_contactsKey);
    if (contactsData != null) {
      _contacts = contactsData.map((data) => QuickContact.fromJson(data)).toList();
    }
  }

  Future<void> _saveContacts() async {
    final prefs = _prefs;
    if (prefs == null) return;
    
    try {
      final contactsData = _contacts.map((c) => c.toJson()).toList();
      await prefs.setStringList(_contactsKey, contactsData);
      Global.loggerModel.info("Saved ${_contacts.length} contacts", source: "QuickContacts");
    } catch (e) {
      Global.loggerModel.error("Failed to save contacts: $e", source: "QuickContacts");
    }
  }

  Future<void> refresh() async {
    await _loadContacts();
    notifyListeners();
    Global.loggerModel.info("Quick Contacts refreshed", source: "QuickContacts");
  }

  void addContact(String name, String phone) {
    if (name.trim().isEmpty || phone.trim().isEmpty) return;
    
    final contactName = name.trim();
    final contactPhone = _normalizePhone(phone.trim());
    
    _contacts.insert(0, QuickContact(name: contactName, phone: contactPhone));
    
    if (_contacts.length > maxContacts) {
      _contacts.removeLast();
    }
    
    notifyListeners();
    _saveContacts();
    Global.loggerModel.info("Added contact: $contactName", source: "QuickContacts");
  }

  void updateContact(int index, String name, String phone) {
    if (index < 0 || index >= _contacts.length) return;
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      deleteContact(index);
      return;
    }
    
    final contactName = name.trim();
    final contactPhone = _normalizePhone(phone.trim());
    
    _contacts[index] = QuickContact(name: contactName, phone: contactPhone);
    notifyListeners();
    _saveContacts();
    Global.loggerModel.info("Updated contact at index $index", source: "QuickContacts");
  }

  void deleteContact(int index) {
    if (index < 0 || index >= _contacts.length) return;
    
    _contacts.removeAt(index);
    notifyListeners();
    _saveContacts();
    Global.loggerModel.info("Deleted contact at index $index", source: "QuickContacts");
  }

  void clearAllContacts() {
    _contacts.clear();
    notifyListeners();
    _saveContacts();
    Global.loggerModel.info("Cleared all contacts", source: "QuickContacts");
  }

  String _normalizePhone(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!normalized.startsWith('+') && normalized.length > 10) {
      normalized = '+$normalized';
    }
    return normalized;
  }

  Future<void> callContact(int index) async {
    if (index < 0 || index >= _contacts.length) return;
    
    final phone = _contacts[index].phone;
    final uri = Uri.parse('tel:$phone');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        Global.loggerModel.info("Calling: $phone", source: "QuickContacts");
      } else {
        Global.loggerModel.error("Cannot launch phone: $phone", source: "QuickContacts");
      }
    } catch (e) {
      Global.loggerModel.error("Error launching phone: $e", source: "QuickContacts");
    }
  }

  Future<void> smsContact(int index) async {
    if (index < 0 || index >= _contacts.length) return;
    
    final phone = _contacts[index].phone;
    final uri = Uri.parse('sms:$phone');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        Global.loggerModel.info("SMS to: $phone", source: "QuickContacts");
      } else {
        Global.loggerModel.error("Cannot launch SMS: $phone", source: "QuickContacts");
      }
    } catch (e) {
      Global.loggerModel.error("Error launching SMS: $e", source: "QuickContacts");
    }
  }
}

class QuickContactsCard extends StatefulWidget {
  @override
  State<QuickContactsCard> createState() => _QuickContactsCardState();
}

class _QuickContactsCardState extends State<QuickContactsCard> {
  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<QuickContactsModel>();
    
    if (!contacts.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.contact_phone, size: 24),
              SizedBox(width: 12),
              Text("Quick Contacts: Loading..."),
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
                  "Quick Contacts",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (contacts.hasContacts)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _showClearConfirmation(context),
                        tooltip: "Clear all contacts",
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18),
                      onPressed: () => _showAddContactDialog(context),
                      tooltip: "Add contact",
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (!contacts.hasContacts)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No contacts yet. Tap + to add.",
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
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts.contacts[index];
                  return _buildContactItem(context, index, contact);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactItem(BuildContext context, int index, QuickContact contact) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(Icons.person, size: 20),
      title: Text(
        contact.name,
        style: TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        contact.phone,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.read<QuickContactsModel>().callContact(index),
      onLongPress: () => _showEditContactDialog(context, index, contact),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.message, size: 16),
            onPressed: () => context.read<QuickContactsModel>().smsContact(index),
            tooltip: "Send SMS",
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: () => context.read<QuickContactsModel>().deleteContact(index),
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Contacts"),
        content: Text("This will delete all quick contacts. This action cannot be undone."),
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
      context.read<QuickContactsModel>().clearAllContacts();
    }
  }
}

class AddContactDialog extends StatefulWidget {
  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Quick Contact"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Name",
              hintText: "John Doe",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: "Phone Number",
              hintText: "+1234567890",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
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
            if (_nameController.text.trim().isNotEmpty && 
                _phoneController.text.trim().isNotEmpty) {
              context.read<QuickContactsModel>().addContact(
                _nameController.text,
                _phoneController.text,
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

class EditContactDialog extends StatefulWidget {
  final int index;
  final QuickContact contact;
  
  const EditContactDialog({
    required this.index,
    required this.contact,
  });
  
  @override
  State<EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<EditContactDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Contact"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Name",
              hintText: "John Doe",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: "Phone Number",
              hintText: "+1234567890",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
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
            context.read<QuickContactsModel>().updateContact(
              widget.index,
              _nameController.text,
              _phoneController.text,
            );
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}