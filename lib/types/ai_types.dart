/// AI response and action types for AI-powered launcher
/// These types represent the structured output from AI providers

/// Types of actions the AI can execute
enum AIActionType {
  LAUNCH_APP,
  TOGGLE_SETTING,
  QUERY_WEATHER,
  SHOW_INFO,
  OPEN_FILE,
}

/// Represents a single action from AI response
class AIAction {
  final AIActionType type;
  final String target;
  final Map<String, dynamic> parameters;
  final String explanation;
  final bool isValid;

  AIAction({
    required this.type,
    required this.target,
    Map<String, dynamic>? parameters,
    this.explanation = '',
    this.isValid = true,
  }) : parameters = parameters ?? const {};

  factory AIAction.fromJson(Map<String, dynamic> json) {
    return AIAction(
      type: AIActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AIActionType.SHOW_INFO,
      ),
      target: json['target'] ?? '',
      parameters: json['parameters'] ?? {},
      explanation: json['explanation'] ?? '',
      isValid: json['isValid'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'target': target,
      'parameters': parameters,
      'explanation': explanation,
      'isValid': isValid,
    };
  }

  /// Validate action parameters
  bool validate() {
    if (target.isEmpty) return false;
    switch (type) {
      case AIActionType.LAUNCH_APP:
        return target.isNotEmpty; // Package name must exist
      case AIActionType.TOGGLE_SETTING:
        return ['wifi', 'bluetooth', 'flashlight', 'airplane'].contains(target.toLowerCase());
      case AIActionType.QUERY_WEATHER:
        return true; // Always valid
      case AIActionType.SHOW_INFO:
        return target.isNotEmpty;
      case AIActionType.OPEN_FILE:
        return target.isNotEmpty; // File path must exist
    }
  }
}

/// Represents the full AI response
class AIResponse {
  final String text;
  final List<AIAction> actions;
  final double confidence;
  final bool success;
  final String? error;

  AIResponse({
    required this.text,
    List<AIAction>? actions,
    this.confidence = 0.0,
    this.success = true,
    this.error,
  }) : actions = actions ?? const [];

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      text: json['text'] ?? '',
      actions: (json['actions'] as List<dynamic>?)
          ?.map((a) => AIAction.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      success: json['success'] ?? true,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'actions': actions.map((a) => a.toJson()).toList(),
      'confidence': confidence,
      'success': success,
      'error': error,
    };
  }

  /// Check if AI is confident enough for auto-execution
  bool canAutoExecute() {
    return confidence >= 0.8 && actions.every((a) => a.validate());
  }

  /// Get actions that need user confirmation
  List<AIAction> getActionsNeedingConfirmation() {
    return actions.where((a) => !a.validate() || confidence < 0.8).toList();
  }
}