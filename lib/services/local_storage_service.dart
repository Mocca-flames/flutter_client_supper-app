import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart'; // Assuming UserModel is in lib/models/user_model.dart
import '../models/order_model.dart'; // Assuming OrderModel is in lib/models/order_model.dart

class LocalStorageService {
  static const String _userDataKey = 'userData';
  static const String _orderHistoryKey = 'orderHistory';

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  // User Data
  Future<void> saveUserData(UserModel userData) async {
    final prefs = await _getPrefs();
    final String userJson = jsonEncode(userData.toJson());
    await prefs.setString(_userDataKey, userJson);
    var logger = Logger();
    logger.i("User data saved to local storage.");
  }

  Future<UserModel?> getUserData() async {
    final prefs = await _getPrefs();
    final String? userJson = prefs.getString(_userDataKey);
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        var logger = Logger();
        logger.i("User data retrieved from local storage.");
        return UserModel.fromJson(userMap);
      } catch (e) {
        var logger = Logger();
        logger.e("Error decoding user data from local storage: $e");
        await clearUserData(); // Clear corrupted data
        return null;
      }
    }
    var logger = Logger();
    logger.i("No user data found in local storage.");
    return null;
  }

  Future<void> clearUserData() async {
    final prefs = await _getPrefs();
    await prefs.remove(_userDataKey);
    var logger = Logger();
    logger.i("User data cleared from local storage.");
  }

  // Order History
  Future<void> saveOrderHistory(List<OrderModel> orders) async {
    final prefs = await _getPrefs();
    final String ordersJson = jsonEncode(orders.map((order) => order.toJson()).toList());
    await prefs.setString(_orderHistoryKey, ordersJson);
    var logger = Logger();
    logger.i("Order history saved to local storage.");
  }

  Future<List<OrderModel>> getOrderHistory() async {
    final prefs = await _getPrefs();
    final String? ordersJson = prefs.getString(_orderHistoryKey);
    if (ordersJson != null) {
      try {
        final List<dynamic> ordersList = jsonDecode(ordersJson);
        var logger = Logger();
        logger.i("Order history retrieved from local storage.");
        return ordersList.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        var logger = Logger();
        logger.e("Error decoding order history from local storage: $e");
        await clearOrderHistory(); // Clear corrupted data
        return [];
      }
    }
    var logger = Logger();
    logger.i("No order history found in local storage.");
    return [];
  }

  Future<void> clearOrderHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_orderHistoryKey);
    var logger = Logger();
    logger.i("Order history cleared from local storage.");
  }

  // Clear all stored data
  Future<void> clearAllStorage() async {
    final prefs = await _getPrefs();
    await prefs.clear(); // Clears all data in SharedPreferences
    var logger = Logger();
    logger.i("All data cleared from local storage.");
  }
}
