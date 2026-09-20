class ChatActionButton {
  final String label;
  final String? route;
  final String? query;

  ChatActionButton({
    required this.label,
    this.route,
    this.query,
  });

  factory ChatActionButton.fromJson(Map<String, dynamic> json) {
    return ChatActionButton(
      label: json['label']?.toString() ?? '',
      route: json['route']?.toString(),
      query: json['query']?.toString(),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatActionButton> actionButtons;
  final Map<String, dynamic>? data;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionButtons = const [],
    this.data,
  });
}
