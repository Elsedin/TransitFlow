class Notification {
  final int id;
  final int? userId;
  final String? userEmail;
  final String? userName;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isActive;

  Notification({
    required this.id,
    this.userId,
    this.userEmail,
    this.userName,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    required this.isActive,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      userEmail: json['userEmail'] as String?,
      userName: json['userName'] as String?,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      isActive: json['isActive'] as bool,
    );
  }
}

class NotificationMetrics {
  final int totalNotifications;
  final int unreadNotifications;
  final int readNotifications;
  final int activeNotifications;
  final Map<String, int> notificationsByType;
  final int broadcastNotifications;
  final int userSpecificNotifications;

  NotificationMetrics({
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.readNotifications,
    required this.activeNotifications,
    required this.notificationsByType,
    required this.broadcastNotifications,
    required this.userSpecificNotifications,
  });

  factory NotificationMetrics.fromJson(Map<String, dynamic> json) {
    return NotificationMetrics(
      totalNotifications: json['totalNotifications'] as int,
      unreadNotifications: json['unreadNotifications'] as int,
      readNotifications: json['readNotifications'] as int,
      activeNotifications: json['activeNotifications'] as int,
      notificationsByType: Map<String, int>.from(json['notificationsByType'] as Map),
      broadcastNotifications: json['broadcastNotifications'] as int,
      userSpecificNotifications: json['userSpecificNotifications'] as int,
    );
  }
}

class CreateNotificationRequest {
  final String title;
  final String message;
  final String type;
  final int? userId;
  final bool sendToAllUsers;

  CreateNotificationRequest({
    required this.title,
    required this.message,
    required this.type,
    this.userId,
    required this.sendToAllUsers,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'type': type,
      if (userId != null) 'userId': userId,
      'sendToAllUsers': sendToAllUsers,
    };
  }
}

class UpdateNotificationRequest {
  final String title;
  final String message;
  final String type;
  final bool isActive;

  UpdateNotificationRequest({
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'isActive': isActive,
    };
  }
}
