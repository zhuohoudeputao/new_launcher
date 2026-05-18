import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/provider.dart';
import 'package:new_launcher/card_config.dart';
import 'package:new_launcher/providers/provider_smart_suggestions.dart';
import 'package:provider/provider.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:device_apps/device_apps.dart';

NotificationsModel notificationsModel = NotificationsModel();

MyProvider providerNotifications = MyProvider(
  name: "Notifications",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);

Future<void> _provideActions() async {
  Global.addActions([
    MyAction(
      name: 'Notifications',
      keywords: 'notification notifications alert message inbox unread',
      action: () => notificationsModel.requestFocus(),
      times: List.generate(24, (index) => 0),
    ),
  ]);
}

Future<void> _initActions() async {
  await notificationsModel.init();
  Global.infoModel.addCard(CardConfig(
    key: "Notifications",
    widget: ChangeNotifierProvider.value(
      value: notificationsModel,
      builder: (context, child) => NotificationsCard(),
    ),
    type: CardType.INFO,
    size: CardSize.LARGE,
    layout: CardLayout.LIST,
    title: "Notifications",
  ));
}

Future<void> _update() async {
  notificationsModel.refresh();
}

class NotificationsModel extends ChangeNotifier {
  static const int maxNotifications = 20;
  static const int maxInteractionsPerApp = 100;
  
  final List<NotificationEntry> _notifications = [];
  final Map<String, List<_NotificationInteraction>> _interactionHistory = {};
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _focusRequested = false;
  
  List<NotificationEntry> get notifications => List.unmodifiable(_notifications);
  int get count => _notifications.length;
  bool get hasNotifications => _notifications.isNotEmpty;
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  bool get shouldFocus => _focusRequested;
  
  /// Initialize notification listener
  Future<void> init() async {
    if (!Platform.isAndroid) {
      _isInitialized = true;
      notifyListeners();
      return;
    }
    
    try {
      // Check permission
      _hasPermission = await NotificationListenerService.isPermissionGranted();
      
      if (!_hasPermission) {
        // Request permission (opens settings)
        _hasPermission = await NotificationListenerService.requestPermission();
      }
      
      if (_hasPermission) {
        // Start listening to notifications
        _subscription = NotificationListenerService.notificationsStream.listen(
          _onNotificationEvent,
          onError: (error) {
            Global.loggerModel.error("Notification stream error: $error", source: "Notifications");
          },
        );
        
        Global.loggerModel.info("Notifications listener initialized", source: "Notifications");
      } else {
        Global.loggerModel.warning("Notification permission not granted", source: "Notifications");
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      Global.loggerModel.error("Notifications init error: $e", source: "Notifications");
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Handle notification events from stream
  void _onNotificationEvent(ServiceNotificationEvent event) {
    try {
      if (event.hasRemoved == true) {
        // Notification was removed from system
        removeNotification(event.id?.toString() ?? '');
      } else {
        // New notification posted
        final entry = NotificationEntry.fromServiceEvent(event);
        addNotification(entry);
        
        Global.loggerModel.info(
          "Notification received: ${event.title} from ${event.packageName}",
          source: "Notifications",
        );
      }
    } catch (e) {
      Global.loggerModel.error("Notification event error: $e", source: "Notifications");
    }
  }
  
  /// Add notification (enforces max limit)
  void addNotification(NotificationEntry notification) {
    // Remove duplicate if exists
    _notifications.removeWhere((n) => n.id == notification.id);
    
    // Add at beginning (most recent first)
    _notifications.insert(0, notification);
    
    // Enforce max limit
    if (_notifications.length > maxNotifications) {
      _notifications.removeRange(maxNotifications, _notifications.length);
    }
    
    notifyListeners();
  }
  
  /// Remove notification by ID
  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
  
  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
  
  /// Record interaction (tap) for pattern learning
  void recordTap(NotificationEntry notification) {
    recordInteraction(notification.packageName, true);
    
    // Also track in smart suggestions
    smartSuggestionsModel.recordCardInteraction("Notification_${notification.packageName}");
  }
  
  /// Record interaction (dismiss) for pattern learning
  void recordDismiss(NotificationEntry notification) {
    recordInteraction(notification.packageName, false);
  }
  
  /// Record interaction for pattern learning
  void recordInteraction(String packageName, bool wasTapped) {
    final interactions = _interactionHistory[packageName] ?? [];
    
    interactions.insert(0, _NotificationInteraction(
      packageName: packageName,
      wasTapped: wasTapped,
      timestamp: DateTime.now(),
      hour: DateTime.now().hour,
      dayOfWeek: DateTime.now().weekday,
    ));
    
    // Enforce limit
    if (interactions.length > maxInteractionsPerApp) {
      interactions.removeRange(maxInteractionsPerApp, interactions.length);
    }
    
    _interactionHistory[packageName] = interactions;
    
    // Update priority for this app's notifications
    _updateAppPriority(packageName);
    notifyListeners();
  }
  
  /// Calculate app priority based on interaction history
  double _calculateAppPriority(String packageName) {
    final interactions = _interactionHistory[packageName];
    if (interactions == null || interactions.isEmpty) return 0.5;
    
    final taps = interactions.where((i) => i.wasTapped).length;
    final dismisses = interactions.where((i) => !i.wasTapped).length;
    final total = interactions.length;
    
    // Tap ratio (higher = more important)
    final tapRatio = taps / total;
    
    // Dismiss ratio (higher = less important)
    final dismissRatio = dismisses / total;
    
    // Combined priority: tap boost, dismiss penalty
    return (0.5 + tapRatio * 0.4 - dismissRatio * 0.3).clamp(0.1, 1.0);
  }
  
  /// Calculate time pattern weight
  double _calculateTimePattern(String packageName) {
    final interactions = _interactionHistory[packageName];
    if (interactions == null || interactions.isEmpty) return 0.3;
    
    final now = DateTime.now();
    final sameHourInteractions = interactions.where((i) => i.hour == now.hour).length;
    final sameDayInteractions = interactions.where((i) => i.dayOfWeek == now.weekday).length;
    final total = interactions.length;
    
    // Time relevance: same hour (70%), same day (30%)
    return (sameHourInteractions / total * 0.7 + sameDayInteractions / total * 0.3).clamp(0.1, 1.0);
  }
  
  /// Get notification priority (combined formula)
  double getNotificationPriority(NotificationEntry notification) {
    final appPriority = _calculateAppPriority(notification.packageName);
    final timePattern = _calculateTimePattern(notification.packageName);
    
    // Type priority (messages higher than others)
    final typePriority = _getTypePriority(notification.packageName);
    
    // Combined: app * 0.5 + time * 0.3 + type * 0.2
    return (appPriority * 0.5 + timePattern * 0.3 + typePriority * 0.2).clamp(0.0, 1.0);
  }
  
  /// Get type priority based on package category
  double _getTypePriority(String packageName) {
    // Messaging apps get higher priority
    if (packageName.contains('whatsapp') || 
        packageName.contains('telegram') ||
        packageName.contains('messenger') ||
        packageName.contains('sms') ||
        packageName.contains('messages')) {
      return 0.9;
    }
    // Email apps
    if (packageName.contains('gmail') || packageName.contains('email')) {
      return 0.7;
    }
    // Social apps
    if (packageName.contains('instagram') || 
        packageName.contains('twitter') ||
        packageName.contains('facebook')) {
      return 0.5;
    }
    // Default
    return 0.4;
  }
  
  /// Update priority for all notifications from this app
  void _updateAppPriority(String packageName) {
    for (final notification in _notifications) {
      if (notification.packageName == packageName) {
        notification.priority = getNotificationPriority(notification);
      }
    }
  }
  
  /// Get notifications sorted by priority
  List<NotificationEntry> getSortedNotifications() {
    final sorted = _notifications.toList();
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }
  
  /// Get notification by ID
  NotificationEntry? getNotification(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get priorities for smart sorting
  Map<String, double> getNotificationPriorities() {
    final priorities = <String, double>{};
    for (final notification in _notifications) {
      priorities["Notification_${notification.id}"] = notification.priority;
    }
    return priorities;
  }
  
  void requestFocus() {
    _focusRequested = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 100), () {
      _focusRequested = false;
      notifyListeners();
    });
  }
  
  void refresh() {
    notifyListeners();
  }
  
  /// Open notification's source app
  Future<void> openApp(String packageName) async {
    try {
      final app = await DeviceApps.getApp(packageName);
      if (app != null) {
        DeviceApps.openApp(packageName);
        Global.loggerModel.info("Opened app: $packageName", source: "Notifications");
      }
    } catch (e) {
      Global.loggerModel.error("Failed to open app: $e", source: "Notifications");
    }
  }
  
  /// Request permission again
  Future<void> requestPermission() async {
    if (!Platform.isAndroid) return;
    
    try {
      _hasPermission = await NotificationListenerService.requestPermission();
      notifyListeners();
      
      if (_hasPermission && _subscription == null) {
        _subscription = NotificationListenerService.notificationsStream.listen(_onNotificationEvent);
      }
    } catch (e) {
      Global.loggerModel.error("Permission request error: $e", source: "Notifications");
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class _NotificationInteraction {
  final String packageName;
  final bool wasTapped;
  final DateTime timestamp;
  final int hour;
  final int dayOfWeek;
  
  _NotificationInteraction({
    required this.packageName,
    required this.wasTapped,
    required this.timestamp,
    required this.hour,
    required this.dayOfWeek,
  });
}

/// Notification entry data class
class NotificationEntry {
  final String id;
  final String packageName;
  final String title;
  final String content;
  final DateTime timestamp;
  final Uint8List? appIcon;
  double priority;
  bool isRead;
  
  NotificationEntry({
    required this.id,
    required this.packageName,
    required this.title,
    required this.content,
    required this.timestamp,
    this.appIcon,
    this.priority = 0.5,
    this.isRead = false,
  });
  
  static NotificationEntry fromServiceEvent(ServiceNotificationEvent event) {
    return NotificationEntry(
      id: event.id?.toString() ?? '',
      packageName: event.packageName ?? '',
      title: event.title ?? '',
      content: event.content ?? '',
      timestamp: DateTime.now(),
      appIcon: event.appIcon,
      priority: 0.5,
    );
  }
  
  String formatTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

class NotificationsCard extends StatelessWidget {
  const NotificationsCard({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final model = context.watch<NotificationsModel>();
    final colorScheme = Theme.of(context).colorScheme;
    
    if (!model.isInitialized) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.notifications, size: 24),
              SizedBox(width: 12),
              Text("Notifications: Initializing..."),
            ],
          ),
        ),
      );
    }
    
    if (!model.hasPermission) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_off, size: 20, color: colorScheme.onSurfaceVariant),
                  SizedBox(width: 8),
                  Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Permission required to show notifications",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => model.requestPermission(),
                icon: Icon(Icons.settings, size: 18),
                label: Text("Grant Permission"),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!model.hasNotifications) {
      return Card.filled(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.notifications_none, size: 20, color: colorScheme.onSurfaceVariant),
              SizedBox(width: 8),
              Text(
                "No notifications",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    
    final sortedNotifications = model.getSortedNotifications();
    
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
                Row(
                  children: [
                    Icon(Icons.notifications, size: 20, color: colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      "Notifications (${model.count})",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (model.hasNotifications)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _showClearConfirmation(context),
                    tooltip: "Clear all",
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            // Show top 5 notifications (sorted by priority)
            ...sortedNotifications.take(5).map((notification) => 
              _buildNotificationItem(context, model, notification, colorScheme),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationItem(
    BuildContext context,
    NotificationsModel model,
    NotificationEntry notification,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          model.recordTap(notification);
          model.openApp(notification.packageName);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // App icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: notification.appIcon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          notification.appIcon!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(Icons.apps, size: 20, color: colorScheme.onPrimaryContainer),
              ),
              SizedBox(width: 12),
              // Title and content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              // Time ago
              Text(
                notification.formatTimeAgo(),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 8),
              // Dismiss button
              IconButton(
                icon: Icon(Icons.close, size: 16),
                onPressed: () {
                  model.recordDismiss(notification);
                  model.removeNotification(notification.id);
                },
                tooltip: "Dismiss",
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  minimumSize: Size(24, 24),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear All Notifications"),
        content: Text("Remove all ${notificationsModel.count} notifications from the launcher?"),
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
      context.read<NotificationsModel>().clearAll();
    }
  }
}