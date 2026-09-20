abstract class PartiesRepository {
  Future<Map<String, dynamic>> getCustomersData();
  Future<Map<String, dynamic>> getSuppliersData();
  Future<bool> addCustomerInvoice({
    required String customerName,
    required double amount,
    String? invoiceNumber,
    String? description,
    DateTime? dueDate,
  });
  Future<bool> addSupplierExpense({
    required String supplierName,
    required double amount,
    String? category,
  });
  Future<bool> recordPayment({
    required String invoiceId,
    required double amount,
  });
}
