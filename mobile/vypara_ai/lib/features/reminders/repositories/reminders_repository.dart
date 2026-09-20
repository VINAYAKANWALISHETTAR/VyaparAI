import 'package:vypara_ai/features/reminders/data/models/reminder_model.dart';

abstract class RemindersRepository {
  Future<List<ReminderModel>> getReminders({String? status});
  Future<ReminderModel> createReminder({
    required String title,
    required String description,
    DateTime? dueAt,
    double? amount,
    String? partyName,
    String? reminderType,
  });
  Future<ReminderModel> updateReminderStatus({
    required String reminderId,
    required String status,
  });
  Future<void> deleteReminder(String reminderId);
}
