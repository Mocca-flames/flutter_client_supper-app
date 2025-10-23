import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/order_model.dart'; // Assuming OrderModel is in lib/models/order_model.dart
import '../models/user_model.dart'; // Assuming UserModel is in lib/models/user_model.dart

class CacheProvider extends ChangeNotifier {
  List<OrderModel>? _cachedOrders;
  UserModel? _cachedUserProfile;

  // Generic cache map for other data types if needed in the future
  final Map<String, dynamic> _genericCache = {};
  var logger = Logger();

  List<OrderModel>? get cachedOrders => _cachedOrders != null ? List.unmodifiable(_cachedOrders!) : null;
  UserModel? get cachedUserProfile => _cachedUserProfile;

  // Specific cache for orders
  void cacheOrderData(List<OrderModel> orders) {
    _cachedOrders = List.from(orders); // Create a copy
    logger.d("Order data cached.");
    notifyListeners();
  }

  List<OrderModel>? getCachedOrders() {
    if (_cachedOrders != null) {
      logger.d("Retrieved orders from cache.");
      return List.unmodifiable(_cachedOrders!);
    }
    logger.d("No orders found in cache.");
    return null;
  }

  void invalidateOrdersCache() {
    if (_cachedOrders != null) {
      _cachedOrders = null;
      logger.d("Orders cache invalidated.");
      notifyListeners();
    }
  }

  // Specific cache for user profile
  void cacheUserProfile(UserModel userProfile) {
    _cachedUserProfile = userProfile.copyWith(); // Create a copy
    logger.d("User profile data cached.");
    notifyListeners();
  }

  UserModel? getCachedUserProfile() {
    if (_cachedUserProfile != null) {
      logger.d("Retrieved user profile from cache.");
      return _cachedUserProfile!.copyWith(); // Return a copy
    }
    logger.d("No user profile found in cache.");
    return null;
  }

  void invalidateUserProfileCache() {
    if (_cachedUserProfile != null) {
      _cachedUserProfile = null;
      logger.d("User profile cache invalidated.");
      notifyListeners();
    }
  }

  // Generic cache methods
  void cacheData(String key, dynamic data) {
    _genericCache[key] = data;
    logger.d("Data cached for key: $key");
    notifyListeners(); // Consider if this is always needed for generic cache
  }

  dynamic getCachedData(String key) {
    final data = _genericCache[key];
    if (data != null) {
      logger.d("Retrieved data from cache for key: $key");
    } else {
      logger.d("No data found in cache for key: $key");
    }
    return data;
  }

  void invalidateCache(String key) {
    if (_genericCache.containsKey(key)) {
      _genericCache.remove(key);
      logger.d("Cache invalidated for key: $key");
      notifyListeners(); // Consider if this is always needed
    }
  }

  void invalidateAllCache() {
    _cachedOrders = null;
    _cachedUserProfile = null;
    _genericCache.clear();
    logger.d("All caches invalidated.");
    notifyListeners();
  }
}
