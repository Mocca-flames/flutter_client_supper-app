enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
  cancelled
}

enum PaymentMethod {
  credit_card,
  paypal,
  bank_transfer,
  mobile_money,
  cash
}

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final String paymentType;
  final String amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? transactionDetails;
  final String? gateway;
  final String? accessCode;
  final String? authorizationUrl;
  final String? totalPaid;
  final String? totalRefunded;
  final String? paymentStatus;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.paymentType,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    required this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.transactionDetails,
    this.gateway,
    this.accessCode,
    this.authorizationUrl,
    this.totalPaid,
    this.totalRefunded,
    this.paymentStatus,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      paymentType: json['payment_type'] ?? 'client_payment',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency'] ?? 'ZAR',
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      status: _parsePaymentStatus(json['status']),
      transactionId: json['transaction_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      transactionDetails: json['transaction_details'] != null
          ? Map<String, dynamic>.from(json['transaction_details'])
          : null,
      gateway: json['gateway'],
      accessCode: json['access_code'],
      authorizationUrl: json['authorization_url'],
      totalPaid: json['total_paid']?.toString(),
      totalRefunded: json['total_refunded']?.toString(),
      paymentStatus: json['payment_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'payment_type': paymentType,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'transaction_details': transactionDetails,
      'gateway': gateway,
      'access_code': accessCode,
      'authorization_url': authorizationUrl,
      'total_paid': totalPaid,
      'total_refunded': totalRefunded,
      'payment_status': paymentStatus,
    };
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => PaymentStatus.pending,
    );
  }

  static PaymentMethod _parsePaymentMethod(String method) {
    return PaymentMethod.values.firstWhere(
      (e) => e.toString().split('.').last == method,
      orElse: () => PaymentMethod.credit_card,
    );
  }

  String getStatusText() {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}