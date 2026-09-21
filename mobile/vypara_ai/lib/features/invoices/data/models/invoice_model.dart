class InvoiceModel {
  final String id;
  final String businessId;
  final String customerName;
  final String? invoiceNumber;
  final double amount;
  final double paidAmount;
  final double outstandingAmount;
  final DateTime? dueDate;
  final String? description;
  final String status; // 'paid', 'unpaid', 'overdue', 'partially_paid'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvoiceModel({
    required this.id,
    required this.businessId,
    required this.customerName,
    this.invoiceNumber,
    required this.amount,
    this.paidAmount = 0.0,
    required this.outstandingAmount,
    this.dueDate,
    this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      return DateTime.tryParse(d.toString());
    }

    final amt = json['amount'] != null ? (json['amount'] as num).toDouble() : 0.0;
    final paid = json['paid_amount'] != null ? (json['paid_amount'] as num).toDouble() : 0.0;
    final outstanding = json['outstanding_amount'] != null
        ? (json['outstanding_amount'] as num).toDouble()
        : (amt - paid);

    return InvoiceModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Customer',
      invoiceNumber: json['invoice_number']?.toString(),
      amount: amt,
      paidAmount: paid,
      outstandingAmount: outstanding,
      dueDate: parseDate(json['due_date']),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'unpaid',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'customer_name': customerName,
      if (invoiceNumber != null && invoiceNumber!.isNotEmpty) 'invoice_number': invoiceNumber,
      'amount': amount,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T').first,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }
}
