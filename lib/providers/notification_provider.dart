import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    _isInitialized = true;
    notifyListeners();
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap if needed
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'molo_channel',
      'Molo Notifications',
      channelDescription: 'Notifications for Molo app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showDriverFoundNotification(String orderId) async {
    await showNotification(
      title: 'Driver Found!',
      body: 'A driver has been assigned to your order. Tap to view details.',
      payload: 'order:$orderId',
    );
  }

  Future<void> showOrderTimeoutNotification(String orderId) async {
    await showNotification(
      title: 'Order Timeout',
      body: 'No driver was found within 5 minutes. Your order has been cancelled.',
      payload: 'timeout:$orderId',
    );
  }
}