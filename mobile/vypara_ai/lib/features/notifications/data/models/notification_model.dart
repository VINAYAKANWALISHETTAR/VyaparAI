class AppNotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.read = false,
    this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    return AppNotificationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
      read: json['read'] == true,
      createdAt: parsedDate,
    );
  }

  AppNotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
