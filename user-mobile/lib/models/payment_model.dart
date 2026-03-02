class PaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;
  final int transactionId;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.transactionId,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['clientSecret'] as String,
      paymentIntentId: json['paymentIntentId'] as String,
      transactionId: json['transactionId'] as int,
    );
  }
}

class PaymentResult {
  final bool success;
  final String? message;
  final int transactionId;
  final String? paymentIntentId;

  PaymentResult({
    required this.success,
    this.message,
    required this.transactionId,
    this.paymentIntentId,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] as bool,
      message: json['message'] as String?,
      transactionId: json['transactionId'] as int,
      paymentIntentId: json['paymentIntentId'] as String?,
    );
  }
}

class PayPalOrderResponse {
  final String orderId;
  final String approvalUrl;
  final int transactionId;

  PayPalOrderResponse({
    required this.orderId,
    required this.approvalUrl,
    required this.transactionId,
  });

  factory PayPalOrderResponse.fromJson(Map<String, dynamic> json) {
    return PayPalOrderResponse(
      orderId: json['orderId'] as String,
      approvalUrl: json['approvalUrl'] as String,
      transactionId: json['transactionId'] as int,
    );
  }
}
