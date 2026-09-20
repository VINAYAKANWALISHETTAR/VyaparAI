class TransactionModel {
  final String id;
  final String businessId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String? description;
  final DateTime? date;
  final String? source;
  final String? referenceId;

  const TransactionModel({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    this.date,
    this.source,
    this.referenceId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString());
    } else if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    }

    return TransactionModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'income',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString(),
      date: parsedDate,
      source: json['source']?.toString(),
      referenceId: json['reference_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'type': type,
      'amount': amount,
      'category': category,
      if (description != null) 'description': description,
      if (date != null) 'date': date!.toIso8601String(),
      if (source != null) 'source': source,
      if (referenceId != null) 'reference_id': referenceId,
    };
  }
}
