class OcrResultModel {
  final String? documentType; // 'invoice', 'receipt', 'payment_screenshot', 'unsupported', 'unreadable'
  final String? invoiceNumber;
  final String? customerName;
  final String? businessName;
  final String? sellerName;
  final String? buyerName;
  final String? sellerGstin;
  final String? buyerGstin;
  final double? totalAmount;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double? subtotal;
  final double? tax;
  final String? currency;
  final double confidence;
  final List<String> items;
  final List<String> validationWarnings;
  final String? rawText;
  final String ocrStatus; // 'extracted', 'needs_confirmation', 'possible_duplicate', 'unsupported', 'unreadable', 'engine_unavailable'
  final String? message;

  const OcrResultModel({
    this.documentType,
    this.invoiceNumber,
    this.customerName,
    this.businessName,
    this.sellerName,
    this.buyerName,
    this.sellerGstin,
    this.buyerGstin,
    this.totalAmount,
    this.invoiceDate,
    this.dueDate,
    this.subtotal,
    this.tax,
    this.currency,
    this.confidence = 0.0,
    this.items = const [],
    this.validationWarnings = const [],
    this.rawText,
    this.ocrStatus = 'needs_confirmation',
    this.message,
  });

  bool get isAmountDetected => totalAmount != null && totalAmount! > 0;
  bool get isPartyDetected =>
      (customerName != null && customerName!.trim().isNotEmpty) ||
      (buyerName != null && buyerName!.trim().isNotEmpty) ||
      (sellerName != null && sellerName!.trim().isNotEmpty);

  factory OcrResultModel.fromJson(Map<String, dynamic> json) {
    // The backend wraps in {status, extracted, raw_text, message}
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
      if (val is List) {
        return val.map((e) {
          if (e is Map) {
            final desc = e['description']?.toString() ?? '';
            final amt = e['amount'];
            if (desc.isNotEmpty && amt != null) {
              return '$desc (₹$amt)';
            }
            return desc;
          }
          return e.toString();
        }).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    List<String> parseWarnings(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return OcrResultModel(
      documentType: extracted['document_type']?.toString(),
      invoiceNumber: extracted['invoice_number']?.toString(),
      customerName: extracted['customer_name']?.toString() ??
          extracted['buyer_name']?.toString() ??
          extracted['seller_name']?.toString(),
      businessName: extracted['business_name']?.toString() ??
          extracted['seller_name']?.toString(),
      sellerName: extracted['seller_name']?.toString(),
      buyerName: extracted['buyer_name']?.toString(),
      sellerGstin: extracted['seller_gstin']?.toString(),
      buyerGstin: extracted['buyer_gstin']?.toString(),
      totalAmount: (extracted['total_amount'] as num?)?.toDouble(),
      invoiceDate: parseDate(extracted['invoice_date']),
      dueDate: parseDate(extracted['due_date']),
      subtotal: (extracted['subtotal'] as num?)?.toDouble(),
      tax: (extracted['tax'] as num?)?.toDouble(),
      currency: extracted['currency']?.toString(),
      confidence: ((extracted['confidence_score'] ?? extracted['confidence']) as num?)?.toDouble() ?? 0.0,
      items: parseItems(extracted['items']),
      validationWarnings: parseWarnings(extracted['validation_warnings']),
      rawText: rawText,
      ocrStatus: status,
      message: message,
    );
  }
}
