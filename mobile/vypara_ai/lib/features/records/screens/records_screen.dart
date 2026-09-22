import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
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
    final tr = ref.watch(appTranslationsProvider);
    final txState = ref.watch(transactionsProvider);

    // Aggregate records from real transactions
    final List<RecordItem> allRecords = [];

    for (final tx in txState.transactions) {
      final isIncome = tx.type == 'income';
      final src = (tx.source ?? '').toLowerCase();
      final isDoc = src.contains('ocr') || src.contains('doc') || src.contains('invoice');
      final isChat = src.contains('voice') || src.contains('chat') || src.contains('whatsapp') || src.contains('message');

      final String recType;
      final IconData icon;
      final Color iconColor;
      final Color iconBg;
      final String status;

      if (isDoc) {
        recType = 'document';
        icon = Icons.document_scanner_outlined;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEFF6FF);
        status = tr('verified');
      } else if (isChat) {
        recType = 'chat';
        icon = Icons.mic_none_outlined;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFF5F3FF);
        status = tr('recorded');
      } else {
        recType = 'transaction';
        icon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
        iconColor = isIncome ? const Color(0xFF0F764F) : const Color(0xFFDC2626);
        iconBg = isIncome ? const Color(0xFFE8F8F0) : const Color(0xFFFEE2E2);
        status = isIncome ? tr('completed') : tr('paid');
      }

      final date = tx.date ?? DateTime.now();
      final sub = tx.description != null && tx.description!.isNotEmpty
          ? '${tx.description} • ${_formatTime(date)}'
          : '${tr('transactions')} • ${_formatTime(date)}';

      allRecords.add(
        RecordItem(
          id: tx.id,
          title: tx.category,
          subtitle: sub,
          type: recType,
          timestamp: date,
          amount: tx.amount,
          status: status,
          icon: icon,
          iconColor: iconColor,
          iconBg: iconBg,
        ),
      );
    }

    final now = DateTime.now();

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
                  tr('records_and_history'),
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
                      hintText: tr('search_records'),
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
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(tr('all'), RecordFilter.all),
                      const SizedBox(width: 8),
                      _buildFilterChip(tr('documents'), RecordFilter.documents, icon: Icons.description_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip(tr('voice_chats'), RecordFilter.chats, icon: Icons.chat_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip(tr('transactions'), RecordFilter.transactions, icon: Icons.account_balance_wallet_outlined),
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
                          Text(
                            tr('no_records_found'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('no_records_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      if (todayList.isNotEmpty) ...[
                        _buildSectionHeader(tr('today').toUpperCase()),
                        ...todayList.map((item) => _buildRecordCard(item)),
                        const SizedBox(height: 16),
                      ],
                      if (yesterdayList.isNotEmpty) ...[
                        _buildSectionHeader(tr('yesterday').toUpperCase()),
                        ...yesterdayList.map((item) => _buildRecordCard(item)),
                        const SizedBox(height: 16),
                      ],
                      if (earlierList.isNotEmpty) ...[
                        _buildSectionHeader(tr('earlier').toUpperCase()),
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
