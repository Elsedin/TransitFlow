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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userFullName': userFullName,
      'packageName': packageName,
      'price': price,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
  final String name;
  final String displayName;
  final int durationDays;
  final double price;
  final List<String> benefits;
  final String? tag;
  final String? savings;

  SubscriptionPackage({
    required this.name,
    required this.displayName,
    required this.durationDays,
    required this.price,
    required this.benefits,
    this.tag,
    this.savings,
  });

  double get pricePerDay => price / durationDays;
}
