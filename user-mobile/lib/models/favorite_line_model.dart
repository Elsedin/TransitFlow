class FavoriteLine {
  final int id;
  final int userId;
  final String userEmail;
  final int transportLineId;
  final String transportLineNumber;
  final String transportLineName;
  final String origin;
  final String destination;
  final String transportTypeName;
  final DateTime createdAt;

  FavoriteLine({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.transportLineId,
    required this.transportLineNumber,
    required this.transportLineName,
    required this.origin,
    required this.destination,
    required this.transportTypeName,
    required this.createdAt,
  });

  factory FavoriteLine.fromJson(Map<String, dynamic> json) {
    return FavoriteLine(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userEmail: json['userEmail'] as String,
      transportLineId: json['transportLineId'] as int,
      transportLineNumber: json['transportLineNumber'] as String,
      transportLineName: json['transportLineName'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      transportTypeName: json['transportTypeName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'transportLineId': transportLineId,
      'transportLineNumber': transportLineNumber,
      'transportLineName': transportLineName,
      'origin': origin,
      'destination': destination,
      'transportTypeName': transportTypeName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
