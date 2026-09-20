class OcrResultModel {
  final String? invoiceNumber;
  final String? customerName;
  final String? businessName;
  final double totalAmount;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double? subtotal;
  final double? tax;
  final String? currency;
  final double confidence;
  final List<String> items;
  final String? rawText;
  final String ocrStatus; // 'needs_confirmation', 'possible_duplicate', 'low_confidence'
  final String? message;

  const OcrResultModel({
    this.invoiceNumber,
    this.customerName,
    this.businessName,
    required this.totalAmount,
    this.invoiceDate,
    this.dueDate,
    this.subtotal,
    this.tax,
    this.currency,
    this.confidence = 0.0,
    this.items = const [],
    this.rawText,
    this.ocrStatus = 'needs_confirmation',
    this.message,
  });

  factory OcrResultModel.fromJson(Map<String, dynamic> json) {
    // The backend wraps in {status, extracted, raw_text, message}
    // Support both the outer wrapper and a flat extracted map.
    final extracted = (json['extracted'] ?? json) as Map<String, dynamic>;
    final status = json['status']?.toString() ?? 'needs_confirmation';
    final message = json['message']?.toString();
    final rawText =
        json['raw_text']?.toString() ?? extracted['raw_text']?.toString();

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    List<String> parseItems(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    return OcrResultModel(
      invoiceNumber: extracted['invoice_number']?.toString(),
      customerName: extracted['customer_name']?.toString(),
      businessName: extracted['business_name']?.toString(),
      totalAmount: (extracted['total_amount'] as num?)?.toDouble() ?? 0.0,
      invoiceDate: parseDate(extracted['invoice_date']),
      dueDate: parseDate(extracted['due_date']),
      subtotal: (extracted['subtotal'] as num?)?.toDouble(),
      tax: (extracted['tax'] as num?)?.toDouble(),
      currency: extracted['currency']?.toString(),
      items: parseItems(extracted['items']),
      rawText: rawText,
      ocrStatus: status,
      message: message,
    );
  }
}
