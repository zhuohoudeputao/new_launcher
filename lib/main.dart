/*
 * @Author: zhuohoudeputao
 * @LastEditors: zhuohoudeputao
 * @LastEditTime: 2020-07-24 21:40:17
 * @Description: AI-Powered Intelligent Launcher
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:new_launcher/data.dart';
import 'package:new_launcher/card_config.dart';
import 'package:new_launcher/providers/provider_app_drawer.dart';
import 'package:new_launcher/providers/provider_app.dart';
import 'package:new_launcher/providers/provider_notifications.dart';
import 'package:new_launcher/providers/provider_smart_suggestions.dart';

import 'package:new_launcher/ai_engine.dart';
import 'package:new_launcher/action_executor.dart';
import 'package:new_launcher/memory_system.dart';
import 'package:new_launcher/context_builder.dart';
import 'package:new_launcher/types/ai_types.dart';
import 'package:new_launcher/settings_page.dart';
import 'package:new_launcher/ui/animation_helper.dart';
import 'package:new_launcher/widgets/animated_info_widget.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize providers
  await Global.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Global.actionModel),
        ChangeNotifierProvider.value(value: Global.infoModel),
        ChangeNotifierProvider.value(value: Global.settingsModel),
        ChangeNotifierProvider.value(value: Global.backgroundImageModel),
        ChangeNotifierProvider.value(value: Global.themeModel),
        ChangeNotifierProvider.value(value: Global.loggerModel),
        ChangeNotifierProvider.value(value: appModel),
        ChangeNotifierProvider.value(value: allAppsModel),
        ChangeNotifierProvider.value(value: appStatisticsModel),
        ChangeNotifierProvider.value(value: smartSuggestionsModel),
        ChangeNotifierProvider.value(value: notificationsModel),
        ChangeNotifierProvider.value(value: appDrawerModel),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'AI Launcher',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: ThemeMode.system,
            home: const MyHomePage(),
            routes: {
              '/settings': (context) => const SettingsPage(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  /// Animation controller for reorder animations
  AnimationController? _reorderAnimationController;
  
  /// GlobalKey for SliverAnimatedList state control
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();
  
  /// Previous card order for detecting reorder
  List<String> _previousCardKeys = [];
  
  /// Previous priorities for detecting priority changes
  Map<String, double> _previousPriorities = {};
  
  /// PageController for PageView navigation
  late PageController _pageController;
  
  /// Current page index (0 = secondary, 1 = main)
  int _currentPage = 1;
  
  /// DraggableScrollableController for app drawer
  DraggableScrollableController? _drawerController;
  
  @override
  void initState() {
    super.initState();
    _reorderAnimationController = AnimationController(
      duration: AnimationHelper.defaultDuration,
      vsync: this,
    );
    _pageController = PageController(initialPage: 0);
    _drawerController = DraggableScrollableController();
    _drawerController!.addListener(_onDrawerChanged);
  }
  
  /// Sync drawer state with AppDrawerModel
  void _onDrawerChanged() {
    if (_drawerController == null) return;
    final model = Provider.of<AppDrawerModel>(context, listen: false);
    final size = _drawerController!.size;
    // Update model state based on drawer size
    if (size > 0.1 && !model.isDrawerOpen) {
      model._isDrawerOpen = true;
      model._drawerHeight = size;
      model.notifyListeners();
    } else if (size <= 0.1 && model.isDrawerOpen) {
      model._isDrawerOpen = false;
      model._drawerHeight = size;
      model.notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _reorderAnimationController?.dispose();
    _pageController.dispose();
    _drawerController?.removeListener(_onDrawerChanged);
    _drawerController?.dispose();
    super.dispose();
  }
  
  /// Animate a single card reorder
  void _animateCardReorder(int oldIndex, int newIndex, List<CardConfig> cards) {
    final listState = _listKey.currentState;
    if (listState == null) return;
    
    // Cancel any previous animation
    _reorderAnimationController?.reset();
    
    // Use SliverAnimatedList's built-in animation
    // Remove from old position and insert at new position
    // The animation is handled by the list itself with default duration
    final card = cards[newIndex];
    final isRemoving = Global.infoModel.isRemoving(card.key);
    
    // Remove item from old position with animation
    listState.removeItem(
      oldIndex,
      (context, animation) {
        // Build the removed item with fade-out animation
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: RepaintBoundary(
                key: ValueKey('repaint_${card.key}'),
                child: AnimatedInfoWidget(
                  key: ValueKey(card.key),
                  child: card.widget,
                  visible: !isRemoving,
                ),
              ),
            ),
          ),
        );
      },
      duration: AnimationHelper.defaultDuration,
    );
    
    // Insert item at new position with animation
    listState.insertItem(
      newIndex,
      duration: AnimationHelper.defaultDuration,
    );
    
    // Start animation
    _reorderAnimationController?.forward();
  }
  
  /// Helper function to compare two maps
  bool _mapsEqual(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
  
  @override
  Widget build(BuildContext context) {
    final actionModel = context.watch<ActionModel>();
    final infoModel = context.watch<InfoModel>();
    final smartModel = context.watch<SmartSuggestionsModel>();
    final notificationsModel = context.watch<NotificationsModel>();
    final settingsModel = context.watch<SettingsModel>();
    String query = actionModel.searchQuery;
    
    // Get priorities for smart sorting
    Map<String, double> priorities = {};
    bool useSmartSorting = query.isEmpty && 
                           settingsModel.isSmartSortingEnabled() && 
                           smartModel.isInitialized && 
                           smartModel.uniqueActions > 0;
    if (useSmartSorting) {
      priorities = smartModel.getCardPriorities();
      // Merge notification priorities with card priorities
      final notificationPriorities = notificationsModel.getNotificationPriorities();
      priorities.addAll(notificationPriorities);
    }
    
    // Helper function to get sorted/filtered CardConfig by layout
    List<CardConfig> getCardsByLayout(CardLayout layout) {
      final cards = infoModel.getCardsByLayout(layout);
      
      // Filter by search query if active
      List<CardConfig> filteredCards;
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase().trim();
        filteredCards = cards.where((c) =>
          c.key.toLowerCase().contains(lowerQuery) ||
          (c.title?.toLowerCase().contains(lowerQuery) ?? false)
        ).toList();
      } else {
        filteredCards = cards;
      }
      
      // Sort by priority if smart sorting is enabled
      if (useSmartSorting) {
        filteredCards.sort((a, b) {
          final priorityA = priorities[a.key] ?? 0.0;
          final priorityB = priorities[b.key] ?? 0.0;
          return priorityB.compareTo(priorityA);
        });
      }
      
      return filteredCards;
    }
    
    // Get cards for each layout type
    final listCards = getCardsByLayout(CardLayout.LIST);
    final gridCards = getCardsByLayout(CardLayout.GRID);
    final fullWidthCards = getCardsByLayout(CardLayout.FULL_WIDTH);
    
    // Detect reorder for LIST layout cards
    final currentListKeys = listCards.map((c) => c.key).toList();
    if (useSmartSorting && 
        _previousCardKeys.isNotEmpty && 
        _previousCardKeys.length == currentListKeys.length &&
        _listKey.currentState != null) {
      // Check if priorities changed
      final prioritiesChanged = _previousPriorities.isNotEmpty && 
          !_mapsEqual(_previousPriorities, priorities);
      
      if (prioritiesChanged) {
        // Find cards that moved and animate them
        for (int newIndex = 0; newIndex < currentListKeys.length; newIndex++) {
          final newKey = currentListKeys[newIndex];
          final oldIndex = _previousCardKeys.indexOf(newKey);
          
          if (oldIndex != newIndex && oldIndex != -1) {
            // Card moved - animate reorder
            _animateCardReorder(oldIndex, newIndex, listCards);
          }
        }
      }
    }
    
    // Update previous state for next comparison
    _previousCardKeys = currentListKeys;
    _previousPriorities = Map.from(priorities);
    
    // Helper function to convert CardConfig to widgets with animation wrapper
    Widget buildCardWidget(CardConfig c) {
      final isRemoving = infoModel.isRemoving(c.key);
      return RepaintBoundary(
        key: ValueKey('repaint_${c.key}'),
        child: AnimatedInfoWidget(
          key: ValueKey(c.key),
          child: c.widget,
          visible: !isRemoving,
        ),
      );
    }
    
    // Get widgets for each layout type
    final gridWidgets = gridCards.map((c) => buildCardWidget(c)).toList();
    final fullWidthWidgets = fullWidthCards.map((c) => buildCardWidget(c)).toList();
    
    // Check if all cards are empty (empty state)
    final isEmpty = listCards.isEmpty && gridWidgets.isEmpty && fullWidthWidgets.isEmpty;
    
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage == 1) {
          _pageController.animateToPage(
            0,
            duration: AnimationHelper.defaultDuration,
            curve: Curves.easeInOut,
          );
        }
      },
      child: Stack(fit: StackFit.expand, children: <Widget>[
        Consumer<BackgroundImageModel>(
            builder: (context, BackgroundImageModel background, child) {
          return Image(
              image: context.watch<BackgroundImageModel>().backgroundImage,
              fit: BoxFit.cover);
        }),
        PageView(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index) {
            // Dismiss keyboard when swiping pages
            FocusScope.of(context).unfocus();
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            // Page 0: Secondary screen with wallpaper and AISearchField
            Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Card.filled(
                    color: Theme.of(context).cardColor,
                    child: AISearchField(),
                  ),
                ],
              ),
            ),
            // Page 1: Main screen with AISearchField and cards
            Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                verticalDirection: VerticalDirection.up,
                children: <Widget>[
                  Card.filled(
                    color: Theme.of(context).cardColor,
                    child: AISearchField(),
                  ),
                  AnimatedCrossFade(
                    duration: AnimationHelper.fastDuration,
                    crossFadeState: query.isNotEmpty && (listCards.isNotEmpty || gridWidgets.isNotEmpty || fullWidthWidgets.isNotEmpty)
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      child: Text(
                        "${listCards.length + gridWidgets.length + fullWidthWidgets.length} ${listCards.length + gridWidgets.length + fullWidthWidgets.length == 1 ? 'result' : 'results'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                  child: isEmpty
                      ? Center(
                          child: Card.filled(
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No cards enabled',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/settings');
                                    },
                                    icon: const Icon(Icons.settings),
                                    label: const Text('Go to Settings'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
: GestureDetector(
                           onTap: () {
                             FocusScope.of(context).requestFocus(FocusNode());
                           },
child: LayoutBuilder(
                                builder: (context, constraints) {
                                 // Responsive grid: phone (<600px) vs tablet (>600px)
                                 final isTablet = constraints.maxWidth > 600;
                                 final gridCrossAxisCount = isTablet ? 3 : 2;
                                 final fullWidthCrossAxisCount = isTablet ? 4 : 3;
                                 
return CustomScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    // cacheExtent: Pre-render off-screen cards for smoother scrolling
                                    // Default is 250px, increase to 500px for better lazy loading
                                    cacheExtent: 500,
slivers: [
                                      // SliverAnimatedList for LIST layout cards (full-width with reorder animation)
                                      if (listCards.isNotEmpty)
                                        SliverAnimatedList(
                                          key: _listKey,
                                          initialItemCount: listCards.length,
                                          itemBuilder: (context, index, animation) {
                                            final card = listCards[index];
                                            final isRemoving = infoModel.isRemoving(card.key);
                                            
                                            // Build item with fade-in animation for insertions
                                            return FadeTransition(
                                              opacity: animation,
                                              child: SizeTransition(
                                                sizeFactor: animation,
                                                axisAlignment: 0.0,
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: RepaintBoundary(
                                                    key: ValueKey('repaint_${card.key}'),
                                                    child: AnimatedInfoWidget(
                                                      key: ValueKey(card.key),
                                                      child: card.widget,
                                                      visible: !isRemoving,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                     // SliverGrid for GRID layout cards (responsive columns)
                                     if (gridWidgets.isNotEmpty)
                                       SliverGrid(
                                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                           crossAxisCount: gridCrossAxisCount,
                                           mainAxisSpacing: 8,
                                           crossAxisSpacing: 8,
                                           mainAxisExtent: 150,
                                         ),
                                         delegate: SliverChildBuilderDelegate(
                                           (context, index) {
                                             return Padding(
                                               padding: const EdgeInsets.all(4),
                                               child: gridWidgets[index],
                                             );
                                           },
                                           childCount: gridWidgets.length,
                                         ),
                                       ),
                                     // SliverGrid for FULL_WIDTH layout cards (responsive columns)
                                     if (fullWidthWidgets.isNotEmpty)
                                       SliverGrid(
                                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                           crossAxisCount: fullWidthCrossAxisCount,
                                           mainAxisSpacing: 8,
                                           crossAxisSpacing: 8,
                                           mainAxisExtent: 120,
                                         ),
                                         delegate: SliverChildBuilderDelegate(
                                           (context, index) {
                                             return Padding(
                                               padding: const EdgeInsets.all(4),
                                               child: fullWidthWidgets[index],
                                             );
                                           },
                                           childCount: fullWidthWidgets.length,
                                         ),
                                       ),
],
 );
                                 },
                               ),
                           ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

// AI-powered search field
class AISearchField extends StatefulWidget {
  const AISearchField({super.key});

  @override
  State<AISearchField> createState() => _AISearchFieldState();
}

class _AISearchFieldState extends State<AISearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isLoading = false;
  AIResponse? _aiResponse;
  String? _error;
  
  // Animation state for buttons
  double _sendButtonScale = 1.0;
  double _clearButtonScale = 1.0;
  Map<int, double> _actionButtonScales = {};
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final actionModel = context.read<ActionModel>();
    actionModel.updateSearchQuery(_controller.text);
    
    // Trigger rebuild to show/hide buttons based on text presence
    setState(() {
      // Clear AI response when text changes
      if (_aiResponse != null || _error != null) {
        _aiResponse = null;
        _error = null;
      }
    });
  }

  void _clearText() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _aiResponse = null;
      _error = null;
      _isLoading = false;
    });
  }
  
  // Send query to AI
  Future<void> _sendToAI() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Check if AI is configured
    if (aiEngine == null) {
      setState(() {
        _error = 'AI not configured. Go to Settings → AI API Keys to add your key.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _aiResponse = null;
    });
    
    try {
      // Build context (apps, time, location) from ContextBuilder
      final context = contextBuilder?.buildFullContext() ?? 
        aiEngine?.buildContext(currentTime: DateTime.now()) ?? {};
      
      // Send to AI
      final response = await aiEngine?.processCommand(text, context);
      
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
      
      // Save to memory
      if (response != null && response.success) {
        await memorySystem?.addConversation(text, response.text);
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }
  
  // Execute an AI-suggested action
  Future<void> _executeAction(AIAction action) async {
    try {
      final success = await actionExecutor?.executeAction(action);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success == true
              ? '✓ ${action.explanation}'
              : '✗ Failed to execute action',
          ),
          backgroundColor: success == true ? Colors.green : Colors.red,
        ),
      );
      
      // Clear after successful execution
      if (success == true) {
        _clearText();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search input
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Ask AI or search...',
            prefixIcon: Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty && !_isLoading)
                  AnimatedScale(
                    scale: _sendButtonScale,
                    duration: AnimationHelper.fastDuration,
                    curve: Curves.easeOut,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _sendButtonScale = 0.95),
                      onTapUp: (_) {
                        setState(() => _sendButtonScale = 1.0);
                        _sendToAI();
                      },
                      onTapCancel: () => setState(() => _sendButtonScale = 1.0),
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: null, // Disabled, handled by GestureDetector
                        tooltip: 'Send to AI',
                      ),
                    ),
                  ),
                if (_controller.text.isNotEmpty)
                  AnimatedOpacity(
                    opacity: _controller.text.isNotEmpty ? 1.0 : 0.0,
                    duration: AnimationHelper.fastDuration,
                    curve: Curves.easeOut,
                    child: AnimatedScale(
                      scale: _clearButtonScale,
                      duration: AnimationHelper.fastDuration,
                      curve: Curves.easeOut,
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _clearButtonScale = 0.95),
                        onTapUp: (_) {
                          setState(() => _clearButtonScale = 1.0);
                          _clearText();
                        },
                        onTapCancel: () => setState(() => _clearButtonScale = 1.0),
                        child: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: null, // Disabled, handled by GestureDetector
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        // AI response area
        if (_isLoading)
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('AI thinking...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        
        if (_error != null)
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ),
          ),
        
        if (_aiResponse != null && !_isLoading)
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI text response
                Text(_aiResponse!.text),
                
                // Action buttons
                if (_aiResponse!.actions.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _aiResponse!.actions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final action = entry.value;
                        final scale = _actionButtonScales[index] ?? 1.0;
                        return AnimatedScale(
                          scale: scale,
                          duration: AnimationHelper.fastDuration,
                          curve: Curves.easeOut,
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _actionButtonScales[index] = 0.95),
                            onTapUp: (_) {
                              setState(() => _actionButtonScales[index] = 1.0);
                              _executeAction(action);
                            },
                            onTapCancel: () => setState(() => _actionButtonScales[index] = 1.0),
                            child: ElevatedButton.icon(
                              icon: Icon(_getActionIcon(action.type)),
                              label: Text(action.target),
                              onPressed: null, // Disabled, handled by GestureDetector
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
  
  IconData _getActionIcon(AIActionType type) {
    switch (type) {
      case AIActionType.LAUNCH_APP:
        return Icons.launch;
      case AIActionType.TOGGLE_SETTING:
        return Icons.toggle_on;
      case AIActionType.SHOW_INFO:
        return Icons.info;
      case AIActionType.OPEN_FILE:
        return Icons.link;
      default:
        return Icons.check;
    }
  }
}


