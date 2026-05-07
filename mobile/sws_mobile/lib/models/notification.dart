class AppNotification {
  final int id;
  final String message;
  final String type;
  final String timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        message: json['message'],
        type: json['type'],
        timestamp: json['timestamp'],
        isRead: json['is_read'] == 1,
      );
}
