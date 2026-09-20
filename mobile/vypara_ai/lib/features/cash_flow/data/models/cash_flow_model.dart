class CashFlowTimelinePoint {
  final String date;
  final String label;
  final String fullDate;
  final double balance;

  CashFlowTimelinePoint({
    required this.date,
    required this.label,
    required this.fullDate,
    required this.balance,
  });

  factory CashFlowTimelinePoint.fromJson(Map<String, dynamic> json) {
    return CashFlowTimelinePoint(
      date: json['date']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      fullDate: json['full_date']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CashFlowModel {
  final int days;
  final double currentCash;
  final double expectedReceivables;
  final double upcomingLiabilities;
  final double projectedBalance;
  final String riskIndicator;
  final double growthRate;
  final List<CashFlowTimelinePoint> timeline;

  CashFlowModel({
    required this.days,
    required this.currentCash,
    required this.expectedReceivables,
    required this.upcomingLiabilities,
    required this.projectedBalance,
    required this.riskIndicator,
    required this.growthRate,
    required this.timeline,
  });

  factory CashFlowModel.fromJson(Map<String, dynamic> json) {
    return CashFlowModel(
      days: (json['days'] as num?)?.toInt() ?? 30,
      currentCash: (json['current_cash'] as num?)?.toDouble() ?? 0.0,
      expectedReceivables: (json['expected_receivables'] as num?)?.toDouble() ?? 0.0,
      upcomingLiabilities: (json['upcoming_liabilities'] as num?)?.toDouble() ?? 0.0,
      projectedBalance: (json['projected_balance'] as num?)?.toDouble() ?? 0.0,
      riskIndicator: json['risk_indicator']?.toString() ?? 'medium',
      growthRate: (json['growth_rate'] as num?)?.toDouble() ?? 0.0,
      timeline: (json['timeline'] is List)
          ? (json['timeline'] as List)
              .map((p) => CashFlowTimelinePoint.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
