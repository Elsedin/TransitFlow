class Transaction {
  final int id;
  final String transactionNumber;
  final int userId;
  final String userEmail;
  final String? userFullName;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final int ticketCount;

  Transaction({
    required this.id,
    required this.transactionNumber,
    required this.userId,
    required this.userEmail,
    this.userFullName,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes,
    required this.ticketCount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      transactionNumber: json['transactionNumber'] as String,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String,
      userFullName: json['userFullName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      notes: json['notes'] as String?,
      ticketCount: json['ticketCount'] as int,
    );
  }
}

class TransactionMetrics {
  final int totalTransactions;
  final int completedTransactions;
  final int pendingTransactions;
  final double totalRevenue;
  final double revenueThisMonth;

  TransactionMetrics({
    required this.totalTransactions,
    required this.completedTransactions,
    required this.pendingTransactions,
    required this.totalRevenue,
    required this.revenueThisMonth,
  });

  factory TransactionMetrics.fromJson(Map<String, dynamic> json) {
    return TransactionMetrics(
      totalTransactions: json['totalTransactions'] as int,
      completedTransactions: json['completedTransactions'] as int,
      pendingTransactions: json['pendingTransactions'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      revenueThisMonth: (json['revenueThisMonth'] as num).toDouble(),
    );
  }
}
