import 'dart:async';
import 'package:flutter/services.dart';

class AccessibilityBridge {
  static const MethodChannel _channel = MethodChannel('accessibility_service');
  
  static AccessibilityBridge? _instance;
  static AccessibilityBridge get instance => _instance ??= AccessibilityBridge();
  
  bool _isEnabled = false;
  
  bool get isEnabled => _isEnabled;
  
  Future<void> init() async {
    try {
      _isEnabled = await _channel.invokeMethod('isAccessibilityServiceEnabled') as bool;
    } catch (e) {
      _isEnabled = false;
    }
  }
  
  Future<bool> checkPermission() async {
    try {
      _isEnabled = await _channel.invokeMethod('isAccessibilityServiceEnabled') as bool;
      return _isEnabled;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // Handle error
    }
  }
  
  Future<bool> performGlobalAction(int action) async {
    try {
      return await _channel.invokeMethod('performGlobalAction', {'action': action}) as bool;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> goBack() async {
    return performGlobalAction(1); // GLOBAL_ACTION_BACK
  }
  
  Future<bool> goHome() async {
    return performGlobalAction(2); // GLOBAL_ACTION_HOME
  }
  
  Future<bool> openRecents() async {
    return performGlobalAction(3); // GLOBAL_ACTION_RECENTS
  }
  
  Future<bool> openNotifications() async {
    return performGlobalAction(4); // GLOBAL_ACTION_NOTIFICATIONS
  }
  
  Future<bool> openQuickSettings() async {
    return performGlobalAction(5); // GLOBAL_ACTION_QUICK_SETTINGS
  }
  
  Future<bool> performClick(double x, double y) async {
    try {
      return await _channel.invokeMethod('performClick', {'x': x, 'y': y}) as bool;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> performSwipe(double startX, double startY, double endX, double endY, int duration) async {
    try {
      return await _channel.invokeMethod('performSwipe', {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      }) as bool;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> launchApp(String packageName) async {
    try {
      return await _channel.invokeMethod('launchApp', {'packageName': packageName}) as bool;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> openSettings(String settingsAction) async {
    try {
      return await _channel.invokeMethod('openSettings', {'action': settingsAction}) as bool;
    } catch (e) {
      return false;
    }
  }
}