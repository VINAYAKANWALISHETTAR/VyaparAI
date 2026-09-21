import 'package:vypara_ai/features/transactions/data/models/transaction_model.dart';

abstract class TransactionsRepository {
  Future<List<TransactionModel>> getTransactions({String? type, String? category});
  Future<TransactionModel?> createTransaction(Map<String, dynamic> data);
  Future<TransactionModel?> updateTransaction(String id, Map<String, dynamic> data);
  Future<bool> deleteTransaction(String id);
}

