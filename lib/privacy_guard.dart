class PrivacyGuard {
  static Map<String, dynamic> filterSensitiveData(Map<String, dynamic> context) {
    final filtered = Map<String, dynamic>.from(context);
    
    // Filter file paths
    _filterFilePaths(filtered);
    
    // Filter notification content
    _filterNotificationContent(filtered);
    
    // Remove API keys
    _removeAPIKeys(filtered);
    
    // Remove password references
    _removePasswords(filtered);
    
    return filtered;
  }
  
  static void _filterFilePaths(Map<String, dynamic> context) {
    for (final key in context.keys) {
      final value = context[key];
      if (value is String && _containsFilePath(value)) {
        context[key] = _sanitizeFilePath(value);
      } else if (value is List) {
        context[key] = value.map((item) {
          if (item is String && _containsFilePath(item)) {
            return _sanitizeFilePath(item);
          }
          return item;
        }).toList();
      }
    }
  }
  
  static bool _containsFilePath(String text) {
    return text.contains('/data/') ||
           text.contains('/storage/') ||
           text.contains('/sdcard/') ||
           text.contains('/home/') ||
           text.contains('C:\\') ||
           text.contains('/Users/');
  }
  
  static String _sanitizeFilePath(String path) {
    return '[FILE]';
  }
  
  static void _filterNotificationContent(Map<String, dynamic> context) {
    if (context.containsKey('notifications')) {
      context['notifications'] = '[NOTIFICATIONS]';
    }
  }
  
  static void _removeAPIKeys(Map<String, dynamic> context) {
    final sensitiveKeys = ['api_key', 'apiKey', 'token', 'secret', 'password'];
    for (final key in sensitiveKeys) {
      context.remove(key);
    }
  }
  
  static void _removePasswords(Map<String, dynamic> context) {
    for (final key in context.keys) {
      final value = context[key];
      if (value is String && value.toLowerCase().contains('password')) {
        context[key] = '[REDACTED]';
      }
    }
  }
  
  static String sanitizeText(String text) {
    var sanitized = text;
    
    if (_containsFilePath(sanitized)) {
      sanitized = sanitized.replaceAll(
        RegExp(r'/[\w/.-]+'),
        '[FILE]',
      );
    }
    
    if (sanitized.toLowerCase().contains('password')) {
      sanitized = sanitized.replaceAll(
        RegExp(r'password[:\s]*[\w]+', caseSensitive: false),
        'password: [REDACTED]',
      );
    }
    
    return sanitized;
  }
}