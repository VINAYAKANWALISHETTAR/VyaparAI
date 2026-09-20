class ReminderModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueAt;
  final String status; // 'pending' or 'completed'
  final double? amount;
  final String? partyName;
  final String reminderType; // 'supplier', 'customer', 'rent', 'utility', 'general'
  final DateTime? createdAt;

  ReminderModel({
    required this.id,
    required this.title,
    required this.description,
    this.dueAt,
    this.status = 'pending',
    this.amount,
    this.partyName,
    this.reminderType = 'general',
    this.createdAt,
  });

  bool get isCompleted => status == 'completed';

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      return DateTime.tryParse(d.toString());
    }

    return ReminderModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dueAt: parseDate(json['due_at']),
      status: json['status']?.toString() ?? 'pending',
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      partyName: json['party_name']?.toString(),
      reminderType: json['reminder_type']?.toString() ?? 'general',
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'reminder_type': reminderType,
      'status': status,
    };
    if (dueAt != null) map['due_at'] = dueAt!.toIso8601String();
    if (amount != null) map['amount'] = amount;
    if (partyName != null) map['party_name'] = partyName;
    return map;
  }

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueAt,
    String? status,
    double? amount,
    String? partyName,
    String? reminderType,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      partyName: partyName ?? this.partyName,
      reminderType: reminderType ?? this.reminderType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
