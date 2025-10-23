class TrackingSessionResponse {
  final String sessionId;
  final String orderId;
  final String trackingUrl;

  const TrackingSessionResponse({
    required this.sessionId,
    required this.orderId,
    required this.trackingUrl,
  });

  factory TrackingSessionResponse.fromJson(Map<String, dynamic> json) {
    return TrackingSessionResponse(
      sessionId: json['session_id'] as String,
      orderId: json['order_id'] as String,
      trackingUrl: json['tracking_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'order_id': orderId,
      'tracking_url': trackingUrl,
    };
  }

  @override
  String toString() {
    return 'TrackingSessionResponse(sessionId: $sessionId, orderId: $orderId, trackingUrl: $trackingUrl)';
  }
}
