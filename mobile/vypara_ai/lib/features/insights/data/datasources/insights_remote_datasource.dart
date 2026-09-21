import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';

class InsightItem {
  final String type;
  final String title;
  final String description;
  final String priority;

  InsightItem({
    required this.type,
    required this.title,
    required this.description,
    this.priority = 'medium',
  });

  factory InsightItem.fromJson(Map<String, dynamic> json) {
    return InsightItem(
      type: json['type']?.toString() ?? 'insight',
      title: json['title']?.toString() ?? (json['type']?.toString() ?? 'Business Insight').replaceAll('_', ' ').toUpperCase(),
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
    );
  }
}

class AnomalyItem {
  final String type;
  final String description;
  final String severity;
  final String? relatedId;

  AnomalyItem({
    required this.type,
    required this.description,
    this.severity = 'medium',
    this.relatedId,
  });

  factory AnomalyItem.fromJson(Map<String, dynamic> json) {
    return AnomalyItem(
      type: json['type']?.toString() ?? 'anomaly',
      description: json['description']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'medium',
      relatedId: json['related_id']?.toString(),
    );
  }
}

class InsightsRemoteDataSource {
  final ApiClient apiClient;

  InsightsRemoteDataSource(this.apiClient);

  Future<List<InsightItem>> getInsights() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.financialInsights);
      if (response.data is Map<String, dynamic> && response.data['insights'] is List) {
        return (response.data['insights'] as List)
            .map((item) => InsightItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<AnomalyItem>> getAnomalies() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.financialAnomalies);
      if (response.data is Map<String, dynamic> && response.data['anomalies'] is List) {
        return (response.data['anomalies'] as List)
            .map((item) => AnomalyItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
