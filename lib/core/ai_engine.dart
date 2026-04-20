import 'package:flutter/material.dart';
import 'context_manager.dart';

class AIResponse {
  final String message;
  final List<Widget>? actions;
  final bool needsInput;

  AIResponse({
    required this.message,
    this.actions,
    this.needsInput = false,
  });
}

class AIRule {
  final List<String> keywords;
  final String Function(String input, LauncherContext context) responseGenerator;
  final List<String>? actionNames;

  AIRule({
    required this.keywords,
    required this.responseGenerator,
    this.actionNames,
  });
}

class AIEngine extends ChangeNotifier {
  final ContextManager contextManager;
  final List<AIRule> _rules = [];
  final Map<String, List<String>> _patterns = <String, List<String>>{};
  String _lastInput = '';

  AIEngine({required this.contextManager}) {
    _initRules();
  }

  String get lastInput => _lastInput;

  void _initRules() {
    _rules.addAll([
      AIRule(
        keywords: ['hello', 'hi', 'hey', 'start'],
        responseGenerator: (input, context) {
          final greeting = context.getGreeting();
          return '$greeting How can I help you today?';
        },
      ),
      AIRule(
        keywords: ['time', 'clock', 'hour'],
        responseGenerator: (input, context) {
          final now = context.currentTime;
          final hour = now.hour.toString().padLeft(2, '0');
          final minute = now.minute.toString().padLeft(2, '0');
          return 'The current time is $hour:$minute';
        },
      ),
      AIRule(
        keywords: ['date', 'day', 'today'],
        responseGenerator: (input, context) {
          final now = context.currentTime;
          final weekdays = [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
          ];
          return 'Today is ${weekdays[now.weekday - 1]}, ${now.month}/${now.day}/${now.year}';
        },
      ),
      AIRule(
        keywords: ['weather', 'temperature', 'temp', 'sunny', 'rainy'],
        responseGenerator: (input, context) {
          return 'Check the weather card for current conditions';
        },
      ),
      AIRule(
        keywords: ['music', 'play', 'song', 'spotify', 'youtube'],
        responseGenerator: (input, context) {
          if (input.contains('play')) {
            return 'Playing music...';
          } else if (input.contains('stop')) {
            return 'Music stopped';
          }
          return 'Say "play" to start music or "stop" to stop';
        },
      ),
      AIRule(
        keywords: ['app', 'launch', 'open', 'start'],
        responseGenerator: (input, context) {
          return 'Type the app name to launch it';
        },
      ),
      AIRule(
        keywords: ['search', 'find', 'look'],
        responseGenerator: (input, context) {
          return 'What would you like to search for?';
        },
      ),
      AIRule(
        keywords: ['help', '?', 'what can you do'],
        responseGenerator: (input, context) {
          return '''I can help you with:
• Launching apps
• Checking time and weather
• Playing music
• Searching the web
• And more...""";
        },
      ),
      AIRule(
        keywords: ['where', 'location', 'am i'],
        responseGenerator: (input, context) {
          return 'You are at ${context.getLocationString()}';
        },
      ),
      AIRule(
        keywords: ['frequent', 'often', 'used'],
        responseGenerator: (input, context) {
          final frequent = contextManager.getFrequentApps();
          if (frequent.isEmpty) {
            return 'Start using some apps and I will learn your favorites';
          }
          return 'Your frequently used apps: ${frequent.length} apps';
        },
      ),
    ]);
  }

  void addRule(AIRule rule) {
    _rules.add(rule);
    notifyListeners();
  }

  void learnPattern(String input, List<String> matchedActions) {
    _patterns[input] = matchedActions;
    notifyListeners();
  }

  List<String> getLearnedActions(String input) {
    return _patterns[input] ?? [];
  }

  AIResponse processInput(String input) {
    _lastInput = input;
    final context = contextManager.context;
    final lowerInput = input.toLowerCase();

    for (final rule in _rules) {
      for (final keyword in rule.keywords) {
        if (lowerInput.contains(keyword)) {
          return AIResponse(
            message: rule.responseGenerator(input, context),
          );
        }
      }
    }

    List<String> learnedActions = getLearnedActions(lowerInput);
    if (learnedActions.isNotEmpty) {
      return AIResponse(
        message: 'Running your usual action...',
        actions: [],
      );
    }

    String suggestion = _getSuggestion(lowerInput, context);
    return AIResponse(
      message: suggestion,
      needsInput: true,
    );
  }

  String _getSuggestion(String input, LauncherContext context) {
    if (input.isEmpty) {
      return context.getGreeting();
    }

    if (_matchesAppName(input)) {
      return 'Launch "$input"?';
    }

    return 'I\'m not sure. Try "help" for available commands.';
  }

  bool _matchesAppName(String input) {
    return contextManager.getFrequentApps().any(
          (app) => app.toLowerCase().contains(input.toLowerCase()),
        );
  }

  void processVoiceInput(String transcript) {
    _lastInput = transcript;
    notifyListeners();
  }
}