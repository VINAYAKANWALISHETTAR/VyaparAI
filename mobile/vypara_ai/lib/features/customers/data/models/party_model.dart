class PartyModel {
  final String id;
  final String name;
  final String type; // 'customer' or 'supplier'
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final int count;
  final String? phone;
  final String? lastInvoiceId;

  const PartyModel({
    required this.id,
    required this.name,
    required this.type,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.count,
    this.phone,
    this.lastInvoiceId,
  });

  factory PartyModel.fromCustomerJson(Map<String, dynamic> json) {
    return PartyModel(
      id: json['id']?.toString() ?? json['customer_name']?.toString() ?? '',
      name: json['customer_name']?.toString() ?? 'Unknown Customer',
      type: 'customer',
      totalAmount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['invoice_count'] as num?)?.toInt() ?? 1,
      lastInvoiceId: json['invoice_id']?.toString(),
    );
  }

  factory PartyModel.fromSupplierJson(Map<String, dynamic> json) {
    return PartyModel(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? json['supplier_name']?.toString() ?? 'Unknown Supplier',
      type: 'supplier',
      totalAmount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      count: (json['transaction_count'] as num?)?.toInt() ?? (json['invoice_count'] as num?)?.toInt() ?? 1,
    );
  }
}
