import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/customers/data/models/party_model.dart';
import 'package:vypara_ai/features/customers/providers/parties_provider.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({
    super.key,
    this.partyId,
    this.name = '',
    this.phone = '',
    this.location = '',
    this.dueAmount = 0.0,
    this.totalSales = 0.0,
  });

  final String? partyId;
  final String name;
  final String phone;
  final String location;
  final double dueAmount;
  final double totalSales;

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    final partiesState = ref.watch(partiesProvider);
    PartyModel? party;
    if (widget.partyId != null && widget.partyId!.isNotEmpty) {
      party = partiesState.currentList.firstWhere(
        (p) => p.id == widget.partyId,
        orElse: () => PartyModel(
          id: widget.partyId!,
          name: widget.name,
          type: 'customer',
          totalAmount: widget.totalSales,
          paidAmount: widget.totalSales - widget.dueAmount,
          outstandingAmount: widget.dueAmount,
          count: 0,
          phone: widget.phone,
        ),
      );
    }
    final displayName = party?.name ?? widget.name;
    final displayPhone = party?.phone ?? widget.phone;
    final displayDue = party?.outstandingAmount ?? widget.dueAmount;
    final displaySales = party?.totalAmount ?? widget.totalSales;
    final hasDue = displayDue > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          displayName,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Person Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName.substring(0, 2).toUpperCase() : 'PS',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: hasDue ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    hasDue ? tr('status_due') : tr('status_settled'),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasDue ? const Color(0xFFD97706) : const Color(0xFF059669)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                              Text(
                                displayPhone.isNotEmpty
                                    ? '${tr('customer_label')} • $displayPhone'
                                    : tr('customer_account'),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            if (displayPhone.isNotEmpty)
                              Text(
                                displayPhone,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Quick Action Circles (Call, WhatsApp, Email, More)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionCircle(Icons.call_outlined, tr('call'), const Color(0xFF2563EB), () {}),
                      _buildActionCircle(Icons.chat_bubble_outline_rounded, tr('whatsapp'), const Color(0xFF25D366), () {}),
                      _buildActionCircle(Icons.email_outlined, tr('email'), const Color(0xFFEA4335), () {}),
                      _buildActionCircle(Icons.more_horiz_rounded, tr('more'), const Color(0xFF64748B), () {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab Bar (Overview, Transactions, Documents)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: tr('overview')),
                  Tab(text: tr('transactions')),
                  Tab(text: tr('documents')),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Financial Summary Row (Outstanding Due vs Total Sales)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('outstanding_due'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹ ${displayDue.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('total_sales'),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹ ${displaySales.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Notes Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('customer_notes'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasDue
                        ? '${tr('payment_due_of')} ₹ ${displayDue.toStringAsFixed(0)}. ${tr('active_account_pending')}'
                        : tr('account_settled'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // AI Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('ai_summary_insights'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasDue
                              ? tr('ai_action_reminder')
                              : tr('ai_healthy_account'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
