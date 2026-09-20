import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/core/providers/language_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';

enum RecordFilter { all, documents, chats, transactions }

class RecordItem {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'document', 'chat', 'transaction'
  final DateTime timestamp;
  final double? amount;
  final String? status;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  RecordItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    this.amount,
    this.status,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class RecordsScreenPlaceholder extends ConsumerStatefulWidget {
  const RecordsScreenPlaceholder({super.key});

  @override
  ConsumerState<RecordsScreenPlaceholder> createState() =>
      _RecordsScreenPlaceholderState();
}

class _RecordsScreenPlaceholderState
    extends ConsumerState<RecordsScreenPlaceholder> {
  final _searchController = TextEditingController();
  RecordFilter _activeFilter = RecordFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final str = amount.toStringAsFixed(0);
    if (str.length > 3) {
      String lastThree = str.substring(str.length - 3);
      String remaining = str.substring(0, str.length - 3);
      String formatted = '';
      while (remaining.length > 2) {
        formatted = ',${remaining.substring(remaining.length - 2)}$formatted';
        remaining = remaining.substring(0, remaining.length - 2);
      }
      return '₹$remaining$formatted,$lastThree';
    }
    return '₹$str';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);
    final lang = ref.watch(languageProvider);
    final isKannada = lang.code == 'KN';
    final isHindi = lang.code == 'HI';

    // Aggregate records from transactions + activity
    final List<RecordItem> allRecords = [];

    for (final tx in txState.transactions) {
      final isIncome = tx.type == 'income';
      allRecords.add(
        RecordItem(
          id: tx.id,
          title: tx.category,
          subtitle: tx.description != null && tx.description!.isNotEmpty
              ? '${tx.description} • ${_formatTime(tx.date ?? DateTime.now())}'
              : 'Transaction • ${_formatTime(tx.date ?? DateTime.now())}',
          type: 'transaction',
          timestamp: tx.date ?? DateTime.now(),
          amount: tx.amount,
          status: isIncome ? 'Completed' : 'Paid',
          icon: isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          iconColor: isIncome ? const Color(0xFF0F764F) : const Color(0xFFDC2626),
          iconBg: isIncome ? const Color(0xFFE8F8F0) : const Color(0xFFFEE2E2),
        ),
      );
    }

    // Add smart documents & chat history
    final now = DateTime.now();
    allRecords.addAll([
      RecordItem(
        id: 'doc_1',
        title: 'GST Tax Invoice - Krishna Traders',
        subtitle: 'Scanned OCR • ${_formatTime(now.subtract(const Duration(minutes: 45)))}',
        type: 'document',
        timestamp: now.subtract(const Duration(minutes: 45)),
        amount: 8450.0,
        status: 'Processed',
        icon: Icons.document_scanner_outlined,
        iconColor: const Color(0xFF2563EB),
        iconBg: const Color(0xFFEFF6FF),
      ),
      RecordItem(
        id: 'chat_1',
        title: 'Voice Order - 5x Rice Bags',
        subtitle: 'Voice Assistant • ${_formatTime(now.subtract(const Duration(hours: 2)))}',
        type: 'chat',
        timestamp: now.subtract(const Duration(hours: 2)),
        amount: 2100.0,
        status: 'Recorded',
        icon: Icons.mic_none_outlined,
        iconColor: const Color(0xFF7C3AED),
        iconBg: const Color(0xFFF5F3FF),
      ),
      RecordItem(
        id: 'doc_2',
        title: 'Wholesale Purchase Receipt #882',
        subtitle: 'Uploaded Doc • Yesterday',
        type: 'document',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        amount: 14200.0,
        status: 'Verified',
        icon: Icons.receipt_long_outlined,
        iconColor: const Color(0xFFD97706),
        iconBg: const Color(0xFFFEF3C7),
      ),
      RecordItem(
        id: 'chat_2',
        title: 'WhatsApp Payment Alert - Suresh Gowda',
        subtitle: 'Message Auto-Detect • Yesterday',
        type: 'chat',
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        amount: 5000.0,
        status: 'Confirmed',
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: const Color(0xFF10B981),
        iconBg: const Color(0xFFECFDF5),
      ),
    ]);

    // Sort descending by timestamp
    allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Filter by type & search
    final filtered = allRecords.where((rec) {
      if (_activeFilter == RecordFilter.documents && rec.type != 'document') return false;
      if (_activeFilter == RecordFilter.chats && rec.type != 'chat') return false;
      if (_activeFilter == RecordFilter.transactions && rec.type != 'transaction') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = rec.title.toLowerCase().contains(q);
        final matchSub = rec.subtitle.toLowerCase().contains(q);
        if (!matchTitle && !matchSub) return false;
      }
      return true;
    }).toList();

    // Group into Today, Yesterday, Earlier
    final List<RecordItem> todayList = [];
    final List<RecordItem> yesterdayList = [];
    final List<RecordItem> earlierList = [];

    for (final item in filtered) {
      final diff = now.difference(item.timestamp);
      if (diff.inDays == 0 && item.timestamp.day == now.day) {
        todayList.add(item);
      } else if (diff.inDays <= 1) {
        yesterdayList.add(item);
      } else {
        earlierList.add(item);
      }
    }

    final titleText = isKannada ? 'ದಾಖಲೆಗಳು ಮತ್ತು ಇತಿಹಾಸ' : (isHindi ? 'रिकॉर्ड्स और इतिहास' : 'Records & History');
    final searchHint = isKannada ? 'ದಾಖಲೆಗಳು, ಚಾಟ್‌ಗಳನ್ನು ಹುಡುಕಿ...' : (isHindi ? 'रिकॉर्ड्स, संदेश खोजें...' : 'Search records, documents, chats...');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', RecordFilter.all),
                      const SizedBox(width: 8),
                      _buildFilterChip('Documents', RecordFilter.documents, icon: Icons.description_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('Chats', RecordFilter.chats, icon: Icons.chat_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('Transactions', RecordFilter.transactions, icon: Icons.account_balance_wallet_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No records found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Scanned documents, voice chat logs, and transactions will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      if (todayList.isNotEmpty) ...[
                        _buildSectionHeader('TODAY'),
                        ...todayList.map((item) => _buildRecordCard(item)),
                        const SizedBox(height: 16),
                      ],
                      if (yesterdayList.isNotEmpty) ...[
                        _buildSectionHeader('YESTERDAY'),
                        ...yesterdayList.map((item) => _buildRecordCard(item)),
                        const SizedBox(height: 16),
                      ],
                      if (earlierList.isNotEmpty) ...[
                        _buildSectionHeader('EARLIER'),
                        ...earlierList.map((item) => _buildRecordCard(item)),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RecordFilter filter, {IconData? icon}) {
    final isSelected = _activeFilter == filter;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textTertiary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildRecordCard(RecordItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount and Status
          if (item.amount != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(item.amount!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.status != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      item.status!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ],
      ),
    );
  }
}
