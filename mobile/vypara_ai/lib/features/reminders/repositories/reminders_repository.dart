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
    String? recurrence,
  });
  Future<ReminderModel> updateReminder({
    required String reminderId,
    String? title,
    String? description,
    DateTime? dueAt,
    double? amount,
    String? partyName,
    String? reminderType,
    String? recurrence,
    String? status,
  });
  Future<ReminderModel> updateReminderStatus({
    required String reminderId,
    required String status,
  });
  Future<void> deleteReminder(String reminderId);
}

