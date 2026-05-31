class Subscription {
  final int id;
  final int userId;
  final String userEmail;
  final String? userFullName;
  final String packageName;
  final int subscriptionPackageId;
  final String packageKey;
  final int maxZoneLevel;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final int? transactionId;
  final String? transactionNumber;

  Subscription({
    required this.id,
    required this.userId,
    required this.userEmail,
    this.userFullName,
    required this.packageName,
    this.subscriptionPackageId = 0,
    this.packageKey = '',
    this.maxZoneLevel = 0,
    required this.price,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancelReason,
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
      subscriptionPackageId: json['subscriptionPackageId'] as int? ?? 0,
      packageKey: json['packageKey'] as String? ?? '',
      maxZoneLevel: json['maxZoneLevel'] as int? ?? json['maxZoneId'] as int? ?? 0,
      price: (json['price'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
      cancelReason: json['cancelReason'] as String?,
      transactionId: json['transactionId'] as int?,
      transactionNumber: json['transactionNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userFullName': userFullName,
      'packageName': packageName,
      'subscriptionPackageId': subscriptionPackageId,
      'packageKey': packageKey,
      'maxZoneLevel': maxZoneLevel,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'transactionId': transactionId,
      'transactionNumber': transactionNumber,
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return status.toLowerCase() == 'active' && endDate.isAfter(now);
  }

  int get remainingDays {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }
}

class SubscriptionPackage {
  final int id;
  final String key;
  final String displayName;
  final int durationDays;
  final double price;
  final int maxZoneLevel;
  final bool isActive;

  SubscriptionPackage({
    required this.id,
    required this.key,
    required this.displayName,
    required this.durationDays,
    required this.price,
    required this.maxZoneLevel,
    required this.isActive,
  });

  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackage(
      id: json['id'] as int,
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      durationDays: json['durationDays'] as int,
      price: (json['price'] as num).toDouble(),
      maxZoneLevel: json['maxZoneLevel'] as int? ?? json['maxZoneId'] as int? ?? 0,
      isActive: json['isActive'] as bool,
    );
  }

  double get pricePerDay => price / durationDays;
}
