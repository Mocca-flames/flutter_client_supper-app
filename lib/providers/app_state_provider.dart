import 'package:flutter/material.dart';

class AppStateProvider with ChangeNotifier {
  String _currentScreen = '/'; // Default to a home or initial route
  bool _isOffline = false;
  final List<String> _notifications = [];

  // Getters
  String get currentScreen => _currentScreen;
  bool get isOffline => _isOffline;
  List<String> get notifications => List.unmodifiable(_notifications); // Return unmodifiable list

  // Methods
  void navigateToScreen(String screenRoute) {
    _currentScreen = screenRoute;
    // Actual navigation will be handled by a dedicated Router class,
    // this provider primarily holds the state.
    // However, if direct navigation control from here is desired,
    // a GlobalKey<NavigatorState> could be used.
    notifyListeners();
  }

  void showNotification(String message) {
    _notifications.add(message);
    notifyListeners();
    // Optionally, clear notification after some time
    // Future.delayed(Duration(seconds: 5), () {
    //   if (_notifications.contains(message)) {
    //     _notifications.remove(message);
    //     notifyListeners();
    //   }
    // });
  }

  void clearNotification(String message) {
    _notifications.remove(message);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void setOfflineMode(bool status) {
    _isOffline = status;
    notifyListeners();
  }
}
