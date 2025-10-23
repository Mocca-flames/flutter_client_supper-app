import 'package:flutter/foundation.dart';

enum OrderType { delivery, ride }

enum OrderStatus { pending, accepted, inProgress, completed, cancelled }

class OrderModel {
  final String id;
  final String clientId;
  final String? driverId;
  final OrderStatus status;
  final OrderType orderType;
  final String pickupAddress;
  final String? pickupLatitude;
  final String? pickupLongitude;
  final String dropoffAddress;
  final String? dropoffLatitude;
  final String? dropoffLongitude;
  final double? price;
  final double? distanceKm;
  final String? specialInstructions;
  final DateTime createdAt;
  final String? paymentId; // Added payment information
  final String? paymentStatus; // Added payment status

  OrderModel({
    required this.id,
    required this.clientId,
    this.driverId,
    required this.status,
    required this.orderType,
    required this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.dropoffAddress,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.price,
    this.distanceKm,
    this.specialInstructions,
    required this.createdAt,
    this.paymentId, // Added payment information
    this.paymentStatus, // Added payment status
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      clientId: json['client_id'],
      driverId: json['driver_id'],
      status: _parseStatus(json['status']),
      orderType: _parseOrderType(json['order_type']),
      pickupAddress: json['pickup_address'],
      pickupLatitude: _toNullableString(json['pickup_latitude']),
      pickupLongitude: _toNullableString(json['pickup_longitude']),
      dropoffAddress: json['dropoff_address'],
      dropoffLatitude: _toNullableString(json['dropoff_latitude']),
      dropoffLongitude: _toNullableString(json['dropoff_longitude']),
      price: _parseDouble(json['price']),
      distanceKm: _parseDouble(json['distance_km']),
      specialInstructions: json['special_instructions'],
      createdAt: DateTime.parse(json['created_at']),
      paymentId: json['payment_id'], // Added payment information
      paymentStatus: json['payment_status'], // Added payment status
    );
  }

  static double? _parseDouble(dynamic value) {
    debugPrint('Parsing double from value: $value (${value.runtimeType})');
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return null; // Trim before checking emptiness
      try {
        return double.parse(value.trim()); // Trim before parsing
      } catch (e) {
        debugPrint('Error parsing double from string: $e');
        return null;
      }
    }
    debugPrint('Unexpected type for double parsing: ${value.runtimeType}');
    return null;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }

  static OrderStatus _parseStatus(dynamic value) {
    final s = (value?.toString() ?? '').toLowerCase();
    switch (s) {
      case 'pending':
      case 'created':
        return OrderStatus.pending;
      case 'accepted':
      case 'assigned':
        return OrderStatus.accepted;
      case 'in_progress':
      case 'inprogress':
      case 'in-progress':
      case 'enroute':
        return OrderStatus.inProgress;
      case 'completed':
      case 'delivered':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static OrderType _parseOrderType(dynamic value) {
    final s = (value?.toString() ?? '').toLowerCase();
    if (s.contains('deliver')) return OrderType.delivery;
    return OrderType.ride;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'driver_id': driverId,
      'status': status.toString().split('.').last,
      'order_type': orderType == OrderType.delivery ? 'DELIVERY' : 'RIDE',
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'dropoff_address': dropoffAddress,
      'dropoff_latitude': dropoffLatitude,
      'dropoff_longitude': dropoffLongitude,
      'price': price,
      'distance_km': distanceKm,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'payment_id': paymentId, // Added payment information
      'payment_status': paymentStatus, // Added payment status
    };
  }

  String getStatusText() {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool isActive() {
    return status == OrderStatus.pending ||
        status == OrderStatus.accepted ||
        status == OrderStatus.inProgress;
  }
}
