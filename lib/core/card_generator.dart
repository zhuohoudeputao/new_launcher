import 'package:flutter/material.dart' hide TimeOfDay;
import 'context_manager.dart';
import '../models/card_model.dart';

enum CardPriority {
  time,
  location,
  usage,
  input,
  ai,
}

class CardGenerator extends ChangeNotifier {
  final ContextManager contextManager;
  final List<SmartCardModel> _cards = [];
  List<SmartCardModel> get cards => List.unmodifiable(_cards);

  CardGenerator({required this.contextManager});

  void generateCards() {
    _cards.clear();

    _addTimeBasedCards();
    _addLocationBasedCards();
    _addUsageBasedCards();

    _sortByPriority();
    notifyListeners();
  }

  void _addTimeBasedCards() {
    final context = contextManager.context;
    final greeting = context.getGreeting();

    _cards.add(SmartCardModel(
      id: 'greeting',
      title: greeting,
      priority: CardPriority.time,
      content: _buildGreetingContent(context),
      icon: _getTimeIcon(context.timeOfDay),
    ));

    _cards.add(SmartCardModel(
      id: 'quick_actions',
      title: 'Quick Actions',
      priority: CardPriority.time,
      content: _buildQuickActionsContent(),
      icon: Icons.flash_on,
    ));
  }

  Widget _buildGreetingContent(LauncherContext context) {
    final hour = context.currentTime.hour;
    final minute = context.currentTime.minute;
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeStr,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tap for more',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const Icon(Icons.access_time, size: 40),
      ],
    );
  }

  Widget _buildQuickActionsContent() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _QuickActionChip(icon: Icons.phone, label: 'Call'),
        _QuickActionChip(icon: Icons.message, label: 'Message'),
        _QuickActionChip(icon: Icons.camera, label: 'Camera'),
        _QuickActionChip(icon: Icons.music_note, label: 'Music'),
      ],
    );
  }

  IconData _getTimeIcon(TimeOfDay time) {
    switch (time) {
      case TimeOfDay.morning:
        return Icons.wb_sunny;
      case TimeOfDay.afternoon:
        return Icons.wb_cloudy;
      case TimeOfDay.evening:
        return Icons.nights_stay;
      case TimeOfDay.night:
        return Icons.bedtime;
    }
  }

  void _addLocationBasedCards() {
    final context = contextManager.context;
    final location = context.location;

    if (location == LocationType.office) {
      _cards.add(SmartCardModel(
        id: 'work_apps',
        title: 'Work',
        priority: CardPriority.location,
        content: _buildWorkAppsContent(),
        icon: Icons.work,
      ));
    } else if (location == LocationType.home) {
      _cards.add(SmartCardModel(
        id: 'home_apps',
        title: 'Home',
        priority: CardPriority.location,
        content: _buildHomeAppsContent(),
        icon: Icons.home,
      ));
    }
  }

  Widget _buildWorkAppsContent() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _AppIcon(name: 'Mail', icon: Icons.email),
        _AppIcon(name: 'Calendar', icon: Icons.calendar_today),
        _AppIcon(name: 'Drive', icon: Icons.cloud),
        _AppIcon(name: 'Meet', icon: Icons.videocam),
      ],
    );
  }

  Widget _buildHomeAppsContent() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _AppIcon(name: 'YouTube', icon: Icons.play_circle_filled),
        _AppIcon(name: 'Spotify', icon: Icons.music_note),
        _AppIcon(name: 'Netflix', icon: Icons.movie),
        _AppIcon(name: 'Browser', icon: Icons.language),
      ],
    );
  }

  void _addUsageBasedCards() {
    final recentApps = contextManager.getRecentApps();
    if (recentApps.isEmpty) return;

    _cards.add(SmartCardModel(
      id: 'recent_apps',
      title: 'Recent',
      priority: CardPriority.usage,
      content: _buildRecentAppsContent(recentApps),
      icon: Icons.history,
    ));

    final frequentApps = contextManager.getFrequentApps();
    if (frequentApps.isNotEmpty) {
      _cards.add(SmartCardModel(
        id: 'frequent_apps',
        title: 'Frequent',
        priority: CardPriority.usage,
        content: _buildFrequentAppsContent(frequentApps),
        icon: Icons.star,
      ));
    }
  }

  Widget _buildRecentAppsContent(List<AppUsageData> recentApps) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentApps.length.clamp(0, 10),
        itemBuilder: (context, index) {
          final app = recentApps[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.android),
                ),
                const SizedBox(height: 4),
                Text(
                  app.appName.length > 8
                      ? '${app.appName.substring(0, 8)}...'
                      : app.appName,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrequentAppsContent(List<String> frequentApps) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: frequentApps.length.clamp(0, 5),
        itemBuilder: (context, index) {
          final app = frequentApps[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.star, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  app.length > 8 ? '${app.substring(0, 8)}...' : app,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _sortByPriority() {
    final priorityOrder = {
      CardPriority.time: 0,
      CardPriority.location: 1,
      CardPriority.usage: 2,
      CardPriority.input: 3,
      CardPriority.ai: 4,
    };
    _cards.sort((a, b) =>
        priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!));
  }

  void addContextualCard(SmartCardModel card) {
    _cards.add(card);
    _sortByPriority();
    notifyListeners();
  }

  void removeCard(String id) {
    _cards.removeWhere((card) => card.id == id);
    notifyListeners();
  }

  void clearCards() {
    _cards.clear();
    notifyListeners();
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {},
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String name;
  final IconData icon;

  const _AppIcon({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
