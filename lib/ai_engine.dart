/// AI Engine for AI-powered launcher
/// Handles communication with AI providers (OpenAI, Gemini, Claude, custom)

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:new_launcher/types/ai_types.dart';
import 'package:new_launcher/action.dart';
import 'package:new_launcher/data.dart';

/// Abstract interface for AI providers
abstract class AIProvider {
  String get name;
  Future<AIResponse> sendRequest(String query, Map<String, dynamic> context);
  bool validateKey(String apiKey);
}

/// AI Engine configuration
class AIEngineConfig {
  String provider;
  String apiKey;
  String? customUrl;
  Duration timeout;
  int maxRetries;
  bool enableFallback;

  AIEngineConfig({
    this.provider = 'openai',
    this.apiKey = '',
    this.customUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableFallback = true,
  });
}

/// AI Engine - manages AI provider communication
class AIEngine {
  final AIEngineConfig config;
  final Map<String, AIProvider> _providers = {};
  final http.Client _client = http.Client();
  
  // Fallback to keyword matching
  final Map<String, MyAction> _fallbackActions = {};
  
  AIEngine({AIEngineConfig? config}) : config = config ?? AIEngineConfig();
  
  /// Register an AI provider
  void registerProvider(String name, AIProvider provider) {
    _providers[name] = provider;
  }
  
  /// Register fallback action for keyword matching
  void registerFallbackAction(MyAction action) {
    _fallbackActions[action.name] = action;
  }
  
  /// Get current provider
  AIProvider? get currentProvider => _providers[config.provider];
  
  /// Build context payload for AI request
  Map<String, dynamic> buildContext({
    List<String>? installedApps,
    String? location,
    DateTime? currentTime,
    List<String>? recentQueries,
  }) {
    return {
      'apps': installedApps ?? [],
      'location': location ?? 'unknown',
      'time': (currentTime ?? DateTime.now()).toIso8601String(),
      'hour': (currentTime ?? DateTime.now()).hour,
      'day_of_week': (currentTime ?? DateTime.now()).weekday,
      'recent_queries': recentQueries ?? [],
    };
  }
  
  /// Process user command through AI
  Future<AIResponse> processCommand(
    String query,
    Map<String, dynamic> context,
  ) async {
    final provider = currentProvider;
    
    Global.loggerModel.info('[AI] processCommand: provider=$provider, apiKey=${config.apiKey.isNotEmpty ? "present" : "empty"}', source: 'AI');
    
    if (provider == null || config.apiKey.isEmpty) {
      // Use fallback keyword matching
      Global.loggerModel.warning('[AI] No provider or API key, using fallback', source: 'AI');
      return _fallbackMatch(query);
    }
    
    // Try AI request with retry logic
    int retries = 0;
    while (retries < config.maxRetries) {
      try {
        final response = await provider.sendRequest(query, context)
            .timeout(config.timeout);
        return response;
      } on TimeoutException catch (_) {
        retries++;
        if (retries >= config.maxRetries) {
          // Timeout exceeded, use fallback
          if (config.enableFallback) {
            return _fallbackMatch(query);
          }
          return AIResponse(
            text: 'Request timed out. Please try again.',
            success: false,
            error: 'timeout',
          );
        }
        // Exponential backoff
        await Future.delayed(Duration(seconds: retries * 2));
      } catch (e) {
        retries++;
        if (retries >= config.maxRetries) {
          // Error occurred, use fallback
          if (config.enableFallback) {
            return _fallbackMatch(query);
          }
          return AIResponse(
            text: 'Error processing request: $e',
            success: false,
            error: e.toString(),
          );
        }
        // Exponential backoff
        await Future.delayed(Duration(seconds: retries * 2));
      }
    }
    
    // Should not reach here, but return fallback
    return _fallbackMatch(query);
  }
  
  /// Fallback keyword matching when AI unavailable
  AIResponse _fallbackMatch(String query) {
    final matches = <AIAction>[];
    final queryLower = query.toLowerCase();
    
    for (final action in _fallbackActions.values) {
      if (action.canIdentifyBy(queryLower)) {
        // Determine action type based on keywords
        AIActionType type = AIActionType.SHOW_INFO;
        if (queryLower.contains('launch') || queryLower.contains('open')) {
          type = AIActionType.LAUNCH_APP;
        } else if (queryLower.contains('toggle') || queryLower.contains('turn')) {
          type = AIActionType.TOGGLE_SETTING;
        } else if (queryLower.contains('weather')) {
          type = AIActionType.QUERY_WEATHER;
        }
        
        matches.add(AIAction(
          type: type,
          target: action.name,
          explanation: 'Matched keyword: ${action.name}',
          isValid: true,
        ));
      }
    }
    
    if (matches.isEmpty) {
      return AIResponse(
        text: 'No matching action found for "$query". Try being more specific.',
        success: false,
        error: 'no_match',
      );
    }
    
    return AIResponse(
      text: 'Found ${matches.length} matching action(s) for "$query"',
      actions: matches,
      confidence: 0.5, // Lower confidence for keyword matching
      success: true,
    );
  }
  
  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// OpenAI Provider implementation
class OpenAIProvider implements AIProvider {
  final String apiKey;
  final String baseUrl;
  
  OpenAIProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
  });
  
  @override
  String get name => 'openai';
  
  @override
  bool validateKey(String key) {
    return key.startsWith('sk-') && key.length > 20;
  }
  
  @override
  Future<AIResponse> sendRequest(String query, Map<String, dynamic> context) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': _buildSystemPrompt(),
            },
            {
              'role': 'user',
              'content': _buildUserPrompt(query, context),
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode != 200) {
        return AIResponse(
          text: 'API error: ${response.statusCode}',
          success: false,
          error: 'api_error_${response.statusCode}',
        );
      }
      
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      
      // Parse response for actions
      return _parseResponse(content);
    } finally {
      client.close();
    }
  }
  
  String _buildSystemPrompt() {
    return '''You are an AI assistant for a mobile launcher app. Your job is to understand user commands and suggest actions.

Available action types:
- LAUNCH_APP: Launch an app (target: app name or package)
- TOGGLE_SETTING: Toggle a setting (target: wifi, bluetooth, flashlight, airplane)
- QUERY_WEATHER: Get weather information
- SHOW_INFO: Display information
- OPEN_FILE: Open a file (target: file path)

Respond in JSON format:
{
  "text": "Your response to the user",
  "actions": [{"type": "ACTION_TYPE", "target": "target_value", "explanation": "why"}],
  "confidence": 0.0-1.0
}

If unsure, set confidence < 0.8 to require user confirmation.''';
  }
  
  String _buildUserPrompt(String query, Map<String, dynamic> context) {
    return '''User query: "$query"

Context:
- Installed apps: ${context['apps']}
- Location: ${context['location']}
- Time: ${context['time']} (hour: ${context['hour']}, day: ${context['day_of_week']})

What action should I take?''';
  }
  
  AIResponse _parseResponse(String content) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        return AIResponse.fromJson(json);
      }
      
      // No JSON found, return as text
      return AIResponse(
        text: content,
        confidence: 0.3,
        success: true,
      );
    } catch (e) {
      return AIResponse(
        text: content,
        confidence: 0.3,
        success: true,
      );
    }
  }
}

/// Gemini Provider implementation
class GeminiProvider implements AIProvider {
  final String apiKey;
  final String baseUrl;
  
  GeminiProvider({
    required this.apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
  });
  
  @override
  String get name => 'gemini';
  
  @override
  bool validateKey(String key) {
    return key.length > 10;
  }
  
  @override
  Future<AIResponse> sendRequest(String query, Map<String, dynamic> context) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/models/gemini-pro:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': _buildPrompt(query, context)},
              ],
            },
          ],
        }),
      );
      
      if (response.statusCode != 200) {
        return AIResponse(
          text: 'API error: ${response.statusCode}',
          success: false,
          error: 'api_error_${response.statusCode}',
        );
      }
      
      final data = jsonDecode(response.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'] as String;
      
      return _parseResponse(content);
    } finally {
      client.close();
    }
  }
  
  String _buildPrompt(String query, Map<String, dynamic> context) {
    return '''You are an AI assistant for a mobile launcher app.

User query: "$query"
Context: apps=${context['apps']}, location=${context['location']}, time=${context['time']}

Respond in JSON: {"text": "...", "actions": [...], "confidence": 0.0-1.0}
Action types: LAUNCH_APP, TOGGLE_SETTING, QUERY_WEATHER, SHOW_INFO, OPEN_FILE''';
  }
  
  AIResponse _parseResponse(String content) {
    try {
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        return AIResponse.fromJson(json);
      }
      return AIResponse(text: content, confidence: 0.3, success: true);
    } catch (e) {
      return AIResponse(text: content, confidence: 0.3, success: true);
    }
  }
}

/// Claude Provider implementation
class ClaudeProvider implements AIProvider {
  final String apiKey;
  final String baseUrl;
  
  ClaudeProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com/v1',
  });
  
  @override
  String get name => 'claude';
  
  @override
  bool validateKey(String key) {
    return key.length > 10;
  }
  
  @override
  Future<AIResponse> sendRequest(String query, Map<String, dynamic> context) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 500,
          'messages': [
            {
              'role': 'user',
              'content': _buildPrompt(query, context),
            },
          ],
        }),
      );
      
      if (response.statusCode != 200) {
        return AIResponse(
          text: 'API error: ${response.statusCode}',
          success: false,
          error: 'api_error_${response.statusCode}',
        );
      }
      
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'] as String;
      
      return _parseResponse(content);
    } finally {
      client.close();
    }
  }
  
  String _buildPrompt(String query, Map<String, dynamic> context) {
    return '''You are an AI assistant for a mobile launcher app.

User query: "$query"
Context: apps=${context['apps']}, location=${context['location']}, time=${context['time']}

Respond in JSON: {"text": "...", "actions": [...], "confidence": 0.0-1.0}
Action types: LAUNCH_APP, TOGGLE_SETTING, QUERY_WEATHER, SHOW_INFO, OPEN_FILE''';
  }
  
  AIResponse _parseResponse(String content) {
    try {
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        return AIResponse.fromJson(json);
      }
      return AIResponse(text: content, confidence: 0.3, success: true);
    } catch (e) {
      return AIResponse(text: content, confidence: 0.3, success: true);
    }
  }
}

/// Global AI Engine instance
AIEngine? aiEngine;

/// Initialize AI Engine
Future<void> initAIEngine(AIEngineConfig config) async {
  aiEngine = AIEngine(config: config);
  
  // Register providers
  if (config.apiKey.isNotEmpty) {
    if (config.provider == 'openai') {
      aiEngine!.registerProvider('openai', OpenAIProvider(apiKey: config.apiKey));
    } else if (config.provider == 'gemini') {
      aiEngine!.registerProvider('gemini', GeminiProvider(apiKey: config.apiKey));
    } else if (config.provider == 'claude') {
      aiEngine!.registerProvider('claude', ClaudeProvider(apiKey: config.apiKey));
    }
  }
}
/// Alibaba/GLM Provider
class AlibabaProvider implements AIProvider {
  final String apiKey;
  final String baseUrl;
  final String model;
  
  AlibabaProvider({
    required this.apiKey,
    this.baseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    this.model = 'glm-5',
  });
  
  @override
  String get name => 'alibaba';
  
  @override
  bool validateKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.startsWith('sk-');
  }
  
  @override
  Future<AIResponse> sendRequest(String query, Map<String, dynamic> context) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': _buildSystemPrompt(),
            },
            {
              'role': 'user',
              'content': _buildUserPrompt(query, context),
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        return AIResponse(
          text: 'API error: ${response.statusCode} - ${response.body}',
          success: false,
          error: 'api_error_${response.statusCode}',
        );
      }
      
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      
      return _parseResponse(content);
    } catch (e) {
      return AIResponse(
        text: 'Error: $e',
        success: false,
        error: e.toString(),
      );
    } finally {
      client.close();
    }
  }
  
  String _buildSystemPrompt() {
    return '''You are an AI assistant for a mobile launcher app. Your job is to understand user commands and suggest actions.

Available action types:
- LAUNCH_APP: Launch an app (target: app name or package)
- TOGGLE_SETTING: Toggle a setting (target: wifi, bluetooth, flashlight, airplane)

Respond in this format:
ACTION: [action type]
TARGET: [target app/setting]
EXPLANATION: [brief explanation]

Or if no action needed:
TEXT: [your response text]''';
  }
  
  String _buildUserPrompt(String query, Map<String, dynamic> context) {
    final apps = context['apps'] as List? ?? [];
    final time = context['time'] as String? ?? '';
    
    return '''User query: $query

Context:
- Available apps: ${apps.take(10).join(', ')}
- Current time: $time

Determine the appropriate action and respond in the specified format.''';
  }
  
  AIResponse _parseResponse(String content) {
    // Simple parsing
    if (content.contains('ACTION:')) {
      final lines = content.split('\n');
      String? actionType;
      String? target;
      String? explanation;
      
      for (final line in lines) {
        if (line.startsWith('ACTION:')) {
          actionType = line.substring(7).trim();
        } else if (line.startsWith('TARGET:')) {
          target = line.substring(7).trim();
        } else if (line.startsWith('EXPLANATION:')) {
          explanation = line.substring(12).trim();
        }
      }
      
      if (actionType != null) {
        return AIResponse(
          text: explanation ?? 'Action: $actionType',
          success: true,
          actions: [
            AIAction(
              type: AIActionType.values.firstWhere(
                (t) => t.name.toUpperCase() == actionType?.toUpperCase(),
                orElse: () => AIActionType.LAUNCH_APP,
              ),
              target: target ?? '',
              explanation: explanation ?? '',
            ),
          ],
        );
      }
    }
    
    return AIResponse(
      text: content,
      success: true,
    );
  }
}

/// Load saved AI config and initialize engine
Future<void> loadAIConfig() async {
  final storage = FlutterSecureStorage();
  
  final apiKey = await storage.read(key: 'api_key') ?? '';
  final provider = await storage.read(key: 'api_provider');
  final model = await storage.read(key: 'api_model');
  final endpoint = await storage.read(key: 'api_endpoint');
  
  // Debug logging
  Global.loggerModel.info('[AI] Loading config: apiKey=${apiKey.isNotEmpty ? "present" : "empty"}, provider=$provider', source: 'AI');
  
  if (apiKey.isEmpty) {
    Global.loggerModel.warning('[AI] No API key found, engine not initialized', source: 'AI');
    aiEngine = null;
    return;
  }
  
  // Initialize with detected config
  // Use lowercase provider key for config to match registered provider key
  final providerKey = provider?.toLowerCase().split('/').first ?? 'alibaba';
  Global.loggerModel.info('[AI] Initializing engine with providerKey=$providerKey', source: 'AI');
  
  initAIEngine(AIEngineConfig(
    provider: providerKey,
    apiKey: apiKey,
    customUrl: endpoint,
  ));
  
  // Register appropriate provider
  if (provider == 'Alibaba/GLM') {
    Global.loggerModel.info('[AI] Registering Alibaba provider', source: 'AI');
    aiEngine!.registerProvider('alibaba', AlibabaProvider(
      apiKey: apiKey,
      model: model ?? 'glm-5',
      baseUrl: endpoint?.replaceFirst('/chat/completions', '') ?? 
                'https://dashscope.aliyuncs.com/compatible-mode/v1',
    ));
  } else if (provider == 'OpenAI') {
    Global.loggerModel.info('[AI] Registering OpenAI provider', source: 'AI');
    aiEngine!.registerProvider('openai', OpenAIProvider(apiKey: apiKey));
  } else if (provider == 'Gemini') {
    Global.loggerModel.info('[AI] Registering Gemini provider', source: 'AI');
    aiEngine!.registerProvider('gemini', GeminiProvider(apiKey: apiKey));
  } else if (provider == 'Claude') {
    Global.loggerModel.info('[AI] Registering Claude provider', source: 'AI');
    aiEngine!.registerProvider('claude', ClaudeProvider(apiKey: apiKey));
  } else {
    // Default to alibaba if provider unknown
    Global.loggerModel.info('[AI] Registering default Alibaba provider', source: 'AI');
    aiEngine!.registerProvider('alibaba', AlibabaProvider(
      apiKey: apiKey,
      model: model ?? 'glm-5',
      baseUrl: endpoint?.replaceFirst('/chat/completions', '') ?? 
                'https://dashscope.aliyuncs.com/compatible-mode/v1',
    ));
  }
  
  Global.loggerModel.info('[AI] Engine initialized, currentProvider=${aiEngine?.currentProvider}', source: 'AI');
}
