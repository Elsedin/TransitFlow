class RefundRequest {
  final int id;
  final int userId;
  final String userEmail;
  final int ticketId;
  final String ticketNumber;
  final String ticketPublicId;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNote;

  RefundRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.ticketId,
    required this.ticketNumber,
    required this.ticketPublicId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminNote,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String,
      ticketId: json['ticketId'] as int,
      ticketNumber: json['ticketNumber'] as String,
      ticketPublicId: json['ticketPublicId'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String).toLocal() : null,
      adminNote: json['adminNote'] as String?,
    );
  }
}

