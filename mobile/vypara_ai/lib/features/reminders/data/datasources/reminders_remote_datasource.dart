import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/reminders/data/models/reminder_model.dart';

class RemindersRemoteDataSource {
  final ApiClient apiClient;

  RemindersRemoteDataSource(this.apiClient);

  Future<String?> getDefaultBusinessId() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.businesses);
      if (res.data is List && (res.data as List).isNotEmpty) {
        return (res.data as List).first['id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<List<ReminderModel>> getReminders({String? status}) async {
    final bizId = await getDefaultBusinessId();
    final queryParams = <String, dynamic>{};
    if (bizId != null && bizId.isNotEmpty) {
      queryParams['business_id'] = bizId;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final res = await apiClient.dio.get(
      ApiEndpoints.reminders,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (res.data is List) {
      return (res.data as List)
          .map((item) => ReminderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ReminderModel> createReminder({
    required String title,
    required String description,
    DateTime? dueAt,
    double? amount,
    String? partyName,
    String? reminderType,
  }) async {
    final bizId = await getDefaultBusinessId();
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'reminder_type': reminderType ?? 'general',
    };
    if (dueAt != null) data['due_at'] = dueAt.toIso8601String();
    if (amount != null) data['amount'] = amount;
    if (partyName != null && partyName.isNotEmpty) data['party_name'] = partyName;

    final url = bizId != null
        ? '${ApiEndpoints.reminders}?business_id=$bizId'
        : ApiEndpoints.reminders;

    final res = await apiClient.dio.post(
      url,
      data: data,
    );

    return ReminderModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ReminderModel> updateReminderStatus({
    required String reminderId,
    required String status,
  }) async {
    final res = await apiClient.dio.patch(
      '${ApiEndpoints.reminders}$reminderId',
      data: {'status': status},
    );

    return ReminderModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteReminder(String reminderId) async {
    await apiClient.dio.delete('${ApiEndpoints.reminders}$reminderId');
  }
}
