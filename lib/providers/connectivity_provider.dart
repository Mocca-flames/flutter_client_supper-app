import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Define a type for failed requests if more complex retry logic is needed
// typedef FailedRequestCallback = Future<void> Function();

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool _isOnline = true; // Assume online by default
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  // Store failed requests to retry them when connection is back
  // final List<FailedRequestCallback> _failedRequests = [];

  bool get isOnline => _isOnline;
  List<ConnectivityResult> get connectionType => _connectionStatus;
  // String get connectionTypeString {
  //   if (_connectionStatus.contains(ConnectivityResult.mobile)) return "Mobile Data";
  //   if (_connectionStatus.contains(ConnectivityResult.wifi)) return "WiFi";
  //   if (_connectionStatus.contains(ConnectivityResult.ethernet)) return "Ethernet";
  //   if (_connectionStatus.contains(ConnectivityResult.vpn)) return "VPN";
  //   if (_connectionStatus.contains(ConnectivityResult.bluetooth)) return "Bluetooth";
  //   if (_connectionStatus.contains(ConnectivityResult.other)) return "Other";
  //   return "None";
  // }


  ConnectivityProvider() {
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    await checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> checkConnectivity() async {
    List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
      result = [ConnectivityResult.none]; // Assume no connection on error
    }
    _updateConnectionStatus(result);
    return;
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    _connectionStatus = result;
    final bool currentlyOnline = !_connectionStatus.contains(ConnectivityResult.none);

    if (_isOnline != currentlyOnline) {
      _isOnline = currentlyOnline;
      if (kDebugMode) {
        print("Connectivity changed: ${isOnline ? 'Online' : 'Offline'} - Type: $_connectionStatus");
      }
      notifyListeners();

      if (_isOnline) {
        // retryFailedRequests();
      }
    } else if (_isOnline && listEquals(_connectionStatus, result) == false) {
      // Connection type changed but still online
       if (kDebugMode) {
         print("Connection type changed: $_connectionStatus");
       }
       notifyListeners();
    }
  }

  // Example of how failed requests could be managed
  // void addFailedRequest(FailedRequestCallback request) {
  //   _failedRequests.add(request);
  //   print("Request added to retry queue.");
  // }

  // Future<void> retryFailedRequests() async {
  //   if (_failedRequests.isEmpty) {
  //     print("No failed requests to retry.");
  //     return;
  //   }

  //   print("Retrying ${_failedRequests.length} failed requests...");
  //   List<FailedRequestCallback> currentRetries = List.from(_failedRequests);
  //   _failedRequests.clear();

  //   for (var request in currentRetries) {
  //     try {
  //       await request();
  //     } catch (e) {
  //       print("Error retrying request: $e. Adding back to queue.");
  //       // Optionally add back to queue or handle differently
  //       // _failedRequests.add(request); 
  //     }
  //   }
  //   if(_failedRequests.isEmpty) print("All pending requests retried successfully.");
  // }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
