class OcrResultModel {
  final String? invoiceNumber;
  final String? customerName;
  final double totalAmount;
  final DateTime? invoiceDate;
  final double confidence;
  final List<String> items;
  final String? rawText;

  const OcrResultModel({
    this.invoiceNumber,
    this.customerName,
    required this.totalAmount,
    this.invoiceDate,
    this.confidence = 0.95,
    this.items = const [],
    this.rawText,
  });

  factory OcrResultModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['invoice_date'] != null) {
      parsedDate = DateTime.tryParse(json['invoice_date'].toString());
    }

    List<String> itemsList = [];
    if (json['items'] is List) {
      itemsList = (json['items'] as List).map((e) => e.toString()).toList();
    }

    return OcrResultModel(
      invoiceNumber: json['invoice_number']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['vendor_name']?.toString(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0.0,
      invoiceDate: parsedDate,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.95,
      items: itemsList,
      rawText: json['raw_text']?.toString(),
    );
  }
}
