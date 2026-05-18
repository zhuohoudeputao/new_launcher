import 'package:flutter/material.dart';

AppDrawerModel appDrawerModel = AppDrawerModel();

/// Model for managing drawer state
class AppDrawerModel extends ChangeNotifier {
  bool _isDrawerOpen = false;
  double _drawerHeight = 0.0;

  bool get isDrawerOpen => _isDrawerOpen;
  double get drawerHeight => _drawerHeight;

  /// Open the drawer
  void openDrawer() {
    _isDrawerOpen = true;
    _drawerHeight = 0.7;
    notifyListeners();
  }

  /// Close the drawer
  void closeDrawer() {
    _isDrawerOpen = false;
    _drawerHeight = 0.0;
    notifyListeners();
  }

  /// Toggle drawer state
  void toggleDrawer() {
    if (_isDrawerOpen) {
      closeDrawer();
    } else {
      openDrawer();
    }
  }
}