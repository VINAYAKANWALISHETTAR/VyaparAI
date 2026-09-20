import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/features/reminders/data/models/reminder_model.dart';
import 'package:vypara_ai/features/reminders/providers/reminders_provider.dart';

class RemindersScreenPlaceholder extends ConsumerStatefulWidget {
  const RemindersScreenPlaceholder({super.key});

  @override
  ConsumerState<RemindersScreenPlaceholder> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreenPlaceholder> {
  String _selectedTab = 'Upcoming'; // 'Upcoming' or 'Completed'

  String _formatAmount(double amount) {
    if (amount == 0) return '₹ 0';
    final absAmount = amount.abs();
    final str = absAmount.toStringAsFixed(0);
    String formatted = '';

    if (str.length > 3) {
      final lastThree = str.substring(str.length - 3);
      String remaining = str.substring(0, str.length - 3);
      while (remaining.length > 2) {
        formatted = ',${remaining.substring(remaining.length - 2)}$formatted';
        remaining = remaining.substring(0, remaining.length - 2);
      }
      formatted = '₹ $remaining$formatted,$lastThree';
    } else {
      formatted = '₹ $str';
    }
    return formatted;
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $period';

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthStr = months[date.month];

    if (diffDays == 0) {
      return 'Today, $timeStr';
    } else if (diffDays == 1) {
      return 'Tomorrow, $timeStr';
    } else if (diffDays == -1) {
      return 'Yesterday, $timeStr';
    } else if (diffDays < 0) {
      return '${date.day} $monthStr ${date.year} (Overdue)';
    } else {
      return '${date.day} $monthStr ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remindersProvider);
    final displayedList = _selectedTab == 'Upcoming'
        ? state.upcomingReminders
        : state.completedReminders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E293B)),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Segmented pill control: Upcoming vs Completed
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentButton(
                        title: 'Upcoming',
                        isSelected: _selectedTab == 'Upcoming',
                        count: state.upcomingReminders.length,
                        onTap: () => setState(() => _selectedTab = 'Upcoming'),
                      ),
                    ),
                    Expanded(
                      child: _buildSegmentButton(
                        title: 'Completed',
                        isSelected: _selectedTab == 'Completed',
                        count: state.completedReminders.length,
                        onTap: () => setState(() => _selectedTab = 'Completed'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reminders List
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => ref.read(remindersProvider.notifier).loadReminders(),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: displayedList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = displayedList[index];
                              return _buildReminderCard(item);
                            },
                          ),
                        ),
            ),

            // Bottom Add Reminder Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddReminderSheet(context),
                  icon: const Icon(Icons.add, size: 22, color: Colors.white),
                  label: const Text(
                    'Add Reminder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel item) {
    Color iconBg;
    Color iconColor;
    IconData iconData;

    switch (item.reminderType.toLowerCase()) {
      case 'supplier':
        iconBg = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFFF9800);
        iconData = Icons.calendar_today_outlined;
        break;
      case 'customer':
        iconBg = const Color(0xFFFFEBEE);
        iconColor = const Color(0xFFE53935);
        iconData = Icons.event_busy_outlined;
        break;
      case 'rent':
        iconBg = const Color(0xFFEDE7F6);
        iconColor = const Color(0xFF5E35B1);
        iconData = Icons.apartment_outlined;
        break;
      case 'utility':
        iconBg = const Color(0xFFFFF8E1);
        iconColor = const Color(0xFFFFA000);
        iconData = Icons.receipt_long_outlined;
        break;
      default:
        iconBg = const Color(0xFFEFF6FF);
        iconColor = AppColors.primary;
        iconData = Icons.notifications_none_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (item.partyName != null && item.partyName!.isNotEmpty)
                  Text(
                    item.partyName!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatDueDate(item.dueAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (item.amount != null && item.amount! > 0) ...[
            const SizedBox(width: 8),
            Text(
              _formatAmount(item.amount!),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (action) {
              if (action == 'toggle') {
                ref.read(remindersProvider.notifier).toggleReminderStatus(item);
              } else if (action == 'whatsapp') {
                _showWhatsAppReminderDialog(context, item);
              } else if (action == 'sms') {
                _showSmsReminderDialog(context, item);
              } else if (action == 'delete') {
                _confirmDeleteReminder(context, item);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      item.isCompleted ? Icons.undo_outlined : Icons.check_circle_outline,
                      size: 18,
                      color: item.isCompleted ? AppColors.primary : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Text(item.isCompleted ? 'Mark Pending' : 'Mark Completed'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                    const SizedBox(width: 8),
                    const Text('Send WhatsApp'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sms',
                child: Row(
                  children: [
                    const Icon(Icons.sms_outlined, size: 18, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    const Text('Send SMS'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedTab == 'Upcoming' ? Icons.check_circle_outline : Icons.inbox_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 'Upcoming' ? 'All caught up!' : 'No completed reminders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTab == 'Upcoming'
                ? 'You have no pending payments or alerts.'
                : 'Reminders you mark as finished will appear here.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddReminderSheet(),
    );
  }

  void _showWhatsAppReminderDialog(BuildContext context, ReminderModel item) {
    final amt = item.amount != null ? _formatAmount(item.amount!) : '';
    final dateStr = _formatDueDate(item.dueAt);

    final text = 'Hello ${item.partyName ?? "Sir/Madam"}, this is a gentle reminder regarding ${item.title} $amt due on $dateStr. Kindly arrange the payment at your earliest convenience. Thank you!';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.chat, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('WhatsApp Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview of the reminder message:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text('Copy & Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WhatsApp message copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSmsReminderDialog(BuildContext context, ReminderModel item) {
    final amt = item.amount != null ? _formatAmount(item.amount!) : '';
    final dateStr = _formatDueDate(item.dueAt);

    final text = 'Payment Reminder: ${item.title} $amt is due on $dateStr. Please clear at your earliest convenience.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sms, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text('SMS Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text('Copy SMS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SMS text copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReminder(BuildContext context, ReminderModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Reminder?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(remindersProvider.notifier).deleteReminder(item.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet();

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _titleController = TextEditingController();
  final _partyController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _reminderType = 'supplier';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSubmitting = false;

  final List<String> _quickSuggestions = [
    'Pay Supplier',
    'Follow up Payment',
    'Rent Payment',
    'Electricity Bill',
    'GST Filing',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _partyController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${_selectedDate.day} ${months[_selectedDate.month]} ${_selectedDate.year}';
    final hour = _selectedTime.hour > 12 ? _selectedTime.hour - 12 : (_selectedTime.hour == 0 ? 12 : _selectedTime.hour);
    final period = _selectedTime.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $period';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Reminder',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick suggestion chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickSuggestions.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor: const Color(0xFFF1F5F9),
                      onPressed: () {
                        setState(() {
                          _titleController.text = s;
                          if (s.contains('Supplier')) _reminderType = 'supplier';
                          if (s.contains('Payment') || s.contains('Follow')) _reminderType = 'customer';
                          if (s.contains('Rent')) _reminderType = 'rent';
                          if (s.contains('Electricity') || s.contains('GST')) _reminderType = 'utility';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Pay Supplier',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Party Name
            TextField(
              controller: _partyController,
              decoration: InputDecoration(
                labelText: 'Party / Reference Name',
                hintText: 'e.g. Acme Stores or Apex Supplies',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Amount & Type Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _reminderType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
                      DropdownMenuItem(value: 'customer', child: Text('Customer')),
                      DropdownMenuItem(value: 'rent', child: Text('Rent')),
                      DropdownMenuItem(value: 'utility', child: Text('Utility')),
                      DropdownMenuItem(value: 'general', child: Text('General')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _reminderType = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Time Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(
                      dateStr,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      timeStr,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes / Description',
                hintText: 'Additional details or invoice reference',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReminder() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder title')),
      );
      return;
    }

    final amt = double.tryParse(_amountController.text.trim());
    final dueDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isSubmitting = true);

    final success = await ref.read(remindersProvider.notifier).createReminder(
      title: title,
      description: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (_partyController.text.trim().isNotEmpty ? _partyController.text.trim() : 'Payment reminder'),
      dueAt: dueDateTime,
      amount: amt,
      partyName: _partyController.text.trim(),
      reminderType: _reminderType,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add reminder')),
      );
    }
  }
}
