import 'dart:async';
import 'dart:convert'; // For jsonDecode
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart'; // Import ApiConstants

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  // Callback for order status updates
  Function(Map<String, dynamic>)? onOrderUpdate;

  // Updated WebSocket server URL
  static const String _baseWebSocketUrl = ApiConstants.baseWebSocketUrl;

  bool get isConnected => _isConnected;

  WebSocketService();

  Future<void> connect(String orderId) async {
    if (_isConnected) {
      if (kDebugMode) {
        var logger = Logger();
        logger.i('WebSocketService: Already connected.');
      }
      return;
    }

    final String fullWebSocketUrl = '$_baseWebSocketUrl/track/$orderId';

    if (kDebugMode) {
      var logger = Logger();
      logger.i('WebSocketService: Connecting to $fullWebSocketUrl');
    }
    try {
      _channel = WebSocketChannel.connect(Uri.parse(fullWebSocketUrl));
      _isConnected = true;
      if (kDebugMode) {
        var logger = Logger();
        logger.i('WebSocketService: Connection attempt initiated to $fullWebSocketUrl');
      }

      _channel!.stream.listen(
        (message) {
          _processIncomingMessage(message);
        },
        onDone: () {
          if (kDebugMode) {
            var logger = Logger();
            logger.i('WebSocketService: Connection closed by server.');
          }
          _isConnected = false;
        },
        onError: (error) {
          if (kDebugMode) {
            var logger = Logger();
            logger.e('WebSocketService: Error - $error');
          }
          _isConnected = false;
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (kDebugMode) {
        var logger = Logger();
        logger.e('WebSocketService: Connection error - $e');
      }
      _isConnected = false;
    }
  }

  void _processIncomingMessage(dynamic message) {
    if (kDebugMode) {
      var logger = Logger();
      logger.i('WebSocketService: Received raw message - $message');
    }
    try {
      if (message is String) {
        final decodedMessage = jsonDecode(message);

        if (decodedMessage is Map<String, dynamic>) {
          final type = decodedMessage['type'] as String?;
          final data = decodedMessage['data'];

          if (data is Map<String, dynamic>) {
            if (type == 'order_status') { // Changed to 'order_status' as per guide
              onOrderUpdate?.call(data);
            }
          } else {
            if (kDebugMode) {
              var logger = Logger();
              logger.e('WebSocketService: "data" field is not a map or is missing for type $type.');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        var logger = Logger();
        logger.e('WebSocketService: Error decoding or processing message: $e. Message: $message');
      }
    }
  }

  void subscribeToDriverLocation(String orderId) {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) {
        var logger = Logger();
        logger.e('WebSocketService: Cannot subscribe to driver location. Not connected.');
      }
      return;
    }
    sendMessage({
      'type': 'subscribe_driver_location',
      'order_id': orderId,
    });
    if (kDebugMode) {
      var logger = Logger();
      logger.i('WebSocketService: Subscribed to driver location updates for order $orderId');
    }
  }

  void requestOrderStatus() {
    if (!_isConnected || _channel == null) {
      if (kDebugMode) {
        var logger = Logger();
        logger.e('WebSocketService: Cannot request status. Not connected.');
      }
      return;
    }
    sendMessage({'type': 'get_status'});
    if (kDebugMode) {
      var logger = Logger();
      logger.i('WebSocketService: Sent get_status request.');
    }
  }

  void sendMessage(dynamic message) {
    if (_channel != null && _isConnected) {
      if (kDebugMode) {
        var logger = Logger();
        logger.i('WebSocketService: Sending message - $message');
      }
      _channel!.sink.add(jsonEncode(message)); // Ensure message is JSON encoded
    } else {
      if (kDebugMode) {
        var logger = Logger();
        logger.e('WebSocketService: Cannot send message. Not connected.');
      }
    }
  }

  void disconnect() {
    if (kDebugMode) {
      var logger = Logger();
      logger.i('WebSocketService: Disconnecting...');
    }
    _channel?.sink.close();
    _isConnected = false;
    if (kDebugMode) {
      var logger = Logger();
      logger.i('WebSocketService: Disconnected.');
    }
  }
}
