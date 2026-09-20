import 'package:vypara_ai/features/customers/data/datasources/parties_remote_datasource.dart';
import 'package:vypara_ai/features/customers/repositories/parties_repository.dart';

class PartiesRepositoryImpl implements PartiesRepository {
  final PartiesRemoteDataSource remoteDataSource;

  PartiesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> getCustomersData() => remoteDataSource.getCustomersData();

  @override
  Future<Map<String, dynamic>> getSuppliersData() => remoteDataSource.getSuppliersData();

  @override
  Future<bool> addCustomerInvoice({
    required String customerName,
    required double amount,
    String? invoiceNumber,
    String? description,
    DateTime? dueDate,
  }) =>
      remoteDataSource.addCustomerInvoice(
        customerName: customerName,
        amount: amount,
        invoiceNumber: invoiceNumber,
        description: description,
        dueDate: dueDate,
      );

  @override
  Future<bool> addSupplierExpense({
    required String supplierName,
    required double amount,
    String? category,
  }) =>
      remoteDataSource.addSupplierExpense(
        supplierName: supplierName,
        amount: amount,
        category: category,
      );

  @override
  Future<bool> recordPayment({
    required String invoiceId,
    required double amount,
  }) =>
      remoteDataSource.recordPayment(invoiceId: invoiceId, amount: amount);
}
