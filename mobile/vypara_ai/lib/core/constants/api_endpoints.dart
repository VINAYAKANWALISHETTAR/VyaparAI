class ApiEndpoints {
  static const String health = '/health';
  // Auth
  static const String login = '/auth/login';
  static const String register = '/users/';
  static const String me = '/users/me';

  // Businesses
  static const String businesses = '/businesses/';

  // Transactions
  static const String transactions = '/transactions/';
  static const String transactionSummary = '/transactions/summary';

  // Invoices
  static const String invoices = '/invoices/';

  // OCR
  static const String ocrInvoice = '/ocr/invoice';
  static const String ocrInvoiceConfirm = '/ocr/invoice/confirm';
  static const String ocrPayment = '/ocr/payment';
  static const String ocrPaymentConfirm = '/ocr/payment/confirm';

  // Financials
  static const String financialIncomeToday = '/financials/income/today';
  static const String financialIncomeWeek = '/financials/income/week';
  static const String financialIncomeMonth = '/financials/income/month';
  static const String financialExpensesToday = '/financials/expenses/today';
  static const String financialExpensesWeek = '/financials/expenses/week';
  static const String financialExpensesMonth = '/financials/expenses/month';
  static const String financialProfitToday = '/financials/profit/today';
  static const String financialProfitWeek = '/financials/profit/week';
  static const String financialProfitMonth = '/financials/profit/month';
  static const String financialReceivables = '/financials/receivables';
  static const String financialReceivablesOverdue = '/financials/receivables/overdue';
  static const String financialReceivablesAging = '/financials/receivables/aging';
  static const String financialReceivablesCustomerSummary = '/financials/receivables/customer-summary';
  static const String financialLiabilities = '/financials/liabilities';
  static const String financialLiabilitiesUpcoming = '/financials/liabilities/upcoming';
  static const String financialLiabilitiesOverdue = '/financials/liabilities/overdue';
  static const String financialLiabilitiesSupplierSummary = '/financials/liabilities/supplier-summary';
  static const String financialCashPosition = '/financials/cash-position';
  static const String financialCashFlow = '/financials/cash-flow';
  static const String financialAnomalies = '/financials/anomalies';
  static const String financialInsights = '/financials/insights';

  // Copilot
  static const String copilotChat = '/copilot/chat';

  // Voice
  static const String voiceQuery = '/voice/query';

  // Reminders
  static const String remindersMorningBriefing = '/reminders/morning-briefing';
  static const String reminders = '/reminders/';

  // Notifications
  static const String notifications = '/notifications/';
}
