class Subscription {
  final int id;
  final int userId;
  final String userEmail;
  final String? userFullName;
  final String packageName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? transactionId;
  final String? transactionNumber;

  Subscription({
    required this.id,
    required this.userId,
    required this.userEmail,
    this.userFullName,
    required this.packageName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.transactionId,
    this.transactionNumber,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String,
      userFullName: json['userFullName'] as String?,
      packageName: json['packageName'] as String,
      price: (json['price'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      transactionId: json['transactionId'] as int?,
      transactionNumber: json['transactionNumber'] as String?,
    );
  }
}

class CreateSubscriptionRequest {
  final int userId;
  final String packageName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int? transactionId;

  CreateSubscriptionRequest({
    required this.userId,
    required this.packageName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'packageName': packageName,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }
}

class UpdateSubscriptionRequest {
  final String packageName;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int? transactionId;

  UpdateSubscriptionRequest({
    required this.packageName,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }
}

class SubscriptionMetrics {
  final int totalSubscriptions;
  final int activeSubscriptions;
  final int expiredSubscriptions;
  final int newSubscriptionsThisMonth;
  final double totalRevenue;

  SubscriptionMetrics({
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.expiredSubscriptions,
    required this.newSubscriptionsThisMonth,
    required this.totalRevenue,
  });

  factory SubscriptionMetrics.fromJson(Map<String, dynamic> json) {
    return SubscriptionMetrics(
      totalSubscriptions: json['totalSubscriptions'] as int,
      activeSubscriptions: json['activeSubscriptions'] as int,
      expiredSubscriptions: json['expiredSubscriptions'] as int,
      newSubscriptionsThisMonth: json['newSubscriptionsThisMonth'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
    );
  }
}
