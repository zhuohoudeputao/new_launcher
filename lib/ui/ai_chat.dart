import 'package:flutter/material.dart';
import 'package:new_launcher/types/ai_types.dart';
import 'package:new_launcher/ai_engine.dart';
import 'package:new_launcher/action_executor.dart';
import 'package:new_launcher/memory_system.dart';
import 'package:new_launcher/providers/provider_app.dart';

class AIChatWidget extends StatefulWidget {
  const AIChatWidget({super.key});

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: 'Hello! I\'m your AI assistant. Tell me what you want to do - launch apps, check weather, toggle settings, or anything else!',
      isUser: false,
    ));
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
  
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    _inputController.clear();
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    
    try {
      final context = aiEngine?.buildContext(
        currentTime: DateTime.now(),
      ) ?? {};
      
      final response = await aiEngine?.processCommand(text, context);
      
      if (response != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: response.text,
            isUser: false,
            actions: response.actions,
            confidence: response.confidence,
          ));
          _isLoading = false;
        });
        
        // Save to memory
        await memorySystem?.addConversation(text, response.text);
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: 'AI engine not initialized. Please configure API keys in settings.',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
  }
  
  Future<void> _executeAction(AIAction action) async {
    final success = await actionExecutor?.executeAction(action);
    
    setState(() {
      _messages.add(ChatMessage(
        text: success == true
          ? 'Executed: ${action.explanation}'
          : 'Failed to execute action. Accessibility service may not be enabled.',
        isUser: false,
      ));
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 200,
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: Card.filled(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text(
                    "AI thinking...",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: 'Ask AI...',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessage(ChatMessage message) {
    // Check if this is an error message
    if (!message.isUser && (message.text.startsWith('Error:') || message.text.contains('Error'))) {
      return _buildErrorMessage(message);
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: message.isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
        children: [
          if (message.isUser)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message.text),
            ),
          if (!message.isUser)
            Card.filled(
              color: Theme.of(context).cardColor,
              child: ListTile(
                leading: Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
                title: Text("AI Response", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(message.text),
                trailing: message.actions != null && message.actions!.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: message.actions!.map((action) {
                        return IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () => _executeAction(action),
                          tooltip: _getActionLabel(action),
                        );
                      }).toList(),
                    )
                  : null,
              ),
            ),
          // Display related cards below AI response
          if (!message.isUser && message.actions != null)
            ..._getRelatedCards(message),
        ],
      ),
    );
  }
  
  List<Widget> _getRelatedCards(ChatMessage message) {
    if (message.actions == null || message.actions!.isEmpty) {
      return [];
    }
    
    List<Widget> relatedCards = [];
    
    for (var action in message.actions!) {
      if (action.type == AIActionType.LAUNCH_APP) {
        // Find app by packageName
        final matchingApps = allAppsModel.apps.where(
          (app) => app.packageName == action.target,
        );
        
        if (matchingApps.isNotEmpty) {
          final app = matchingApps.first;
          relatedCards.add(
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Card.filled(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: Image.memory(
                    app.icon,
                    width: 40,
                    height: 40,
                  ),
                  title: Text(app.appName),
                  subtitle: Text(action.explanation),
                  trailing: IconButton(
                    icon: Icon(Icons.launch),
                    onPressed: () => _executeAction(action),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    
    return relatedCards;
  }
  
  Widget _buildErrorMessage(ChatMessage message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card.outlined(
        color: Theme.of(context).cardColor,
        child: ListTile(
          leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          title: Text("Error", style: TextStyle(color: Theme.of(context).colorScheme.error)),
          subtitle: Text(message.text),
        ),
      ),
    );
  }
  
  String _getActionLabel(AIAction action) {
    switch (action.type) {
      case AIActionType.LAUNCH_APP:
        return 'Launch ${action.target}';
      case AIActionType.TOGGLE_SETTING:
        return 'Toggle ${action.target}';
      case AIActionType.QUERY_WEATHER:
        return 'Show Weather';
      case AIActionType.SHOW_INFO:
        return 'Show Info';
      case AIActionType.OPEN_FILE:
        return 'Open File';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final List<AIAction>? actions;
  final double? confidence;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    this.actions,
    this.confidence,
  });
}