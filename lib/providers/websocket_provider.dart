import 'dart:async'; // For StreamSubscription
import 'dart:convert'; // For jsonDecode if messages are JSON
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import './map_provider.dart'; // Import MapProvider

enum WebSocketConnectionState {
  initial,
  connecting,
  connected,
  disconnected,
  error,
}

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final MapProvider _mapProvider;

  WebSocketConnectionState _connectionState = WebSocketConnectionState.initial;
  WebSocketConnectionState get connectionState => _connectionState;

  dynamic _lastOrderUpdateData;
  dynamic get lastOrderUpdateData => _lastOrderUpdateData;

  // Constructor
  WebSocketProvider(this._webSocketService, this._mapProvider) {
    // Set the order update callback for WebSocketService
    _webSocketService.onOrderUpdate = (data) {
      _processOrderUpdate(data);
    };
  }

  Future<void> initializeConnection(String orderId) async {
    if (_connectionState == WebSocketConnectionState.connected ||
        _connectionState == WebSocketConnectionState.connecting) {
      if (kDebugMode) {
        print('WebSocketProvider: Connection already active or in progress for order $orderId.');
      }
      return;
    }

    _setConnectionState(WebSocketConnectionState.connecting);
    if (kDebugMode) {
      print('WebSocketProvider: Initializing connection for order $orderId...');
    }

    try {
      await _webSocketService.connect(orderId);
      if (_webSocketService.isConnected) {
        _setConnectionState(WebSocketConnectionState.connected);
        if (kDebugMode) {
          print('WebSocketProvider: WebSocket connection initialized successfully.');
        }
        // Request initial order status after connection
        _webSocketService.requestOrderStatus();
      } else {
        _setConnectionState(WebSocketConnectionState.error);
        if (kDebugMode) {
          print('WebSocketProvider: WebSocket connection failed.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebSocketProvider: Error initializing connection - $e');
      }
      _setConnectionState(WebSocketConnectionState.error);
    }
  }

  void _setConnectionState(WebSocketConnectionState newState) {
    _connectionState = newState;
    notifyListeners();
  }

  void _processOrderUpdate(dynamic data) {
    try {
      final decodedData = (data is String) ? jsonDecode(data) : data;
      final String? orderId = decodedData['order_id'] as String?; // Changed to 'order_id' as per guide
      if (kDebugMode) {
        print('WebSocketProvider: Processing order update for order ${orderId ?? 'N/A'}: $decodedData');
      }
      _lastOrderUpdateData = decodedData;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('WebSocketProvider: Error processing order update - $e. Data: $data');
      }
    }
  }

  void disconnect() {
    _webSocketService.disconnect();
    _setConnectionState(WebSocketConnectionState.disconnected);
    notifyListeners();
    if (kDebugMode) {
      print('WebSocketProvider: WebSocket disconnected by provider.');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  void subscribeToDriverLocation(String orderId) {
    if (_connectionState == WebSocketConnectionState.connected) {
      _webSocketService.subscribeToDriverLocation(orderId);
    } else {
      if (kDebugMode) {
        print('WebSocketProvider: Cannot subscribe to driver location. Not connected.');
      }
    }
  }
}
