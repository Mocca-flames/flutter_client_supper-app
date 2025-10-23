import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ErrorProvider extends ChangeNotifier {
  dynamic _currentError;
  final List<dynamic> _errorHistory = [];
  VoidCallback? _lastAction;
  var logger = Logger();

  dynamic get currentError => _currentError;
  List<dynamic> get errorHistory => List.unmodifiable(_errorHistory);

  void setError(dynamic error, {VoidCallback? retryAction}) {
    _currentError = error;
    _errorHistory.add(error);
    _lastAction = retryAction;
    logger.i("Error set in Provider: $error"); // For debugging
    notifyListeners();
  }

  void clearError() {
    if (_currentError != null) {
      _currentError = null;
      _lastAction = null;
      notifyListeners();
    }
  }

  void retryLastAction() {
    if (_lastAction != null) {
      logger.i("Retrying last action..."); // For debugging
      _lastAction!();
      // Optionally clear the error after attempting retry,
      // or let the action itself clear it upon success.
      // clearError();
    } else {
      logger.i("No last action to retry."); // For debugging
    }
  }
}
