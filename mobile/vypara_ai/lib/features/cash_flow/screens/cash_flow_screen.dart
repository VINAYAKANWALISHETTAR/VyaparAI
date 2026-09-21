import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/cash_flow/data/models/cash_flow_model.dart';
import 'package:vypara_ai/features/cash_flow/providers/cash_flow_provider.dart';

class CashFlowScreenPlaceholder extends ConsumerStatefulWidget {
  const CashFlowScreenPlaceholder({super.key});

  @override
  ConsumerState<CashFlowScreenPlaceholder> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreenPlaceholder> {
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

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    final state = ref.watch(cashFlowProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          tr('cash_flow'),
          style: const TextStyle(
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
        actions: [
          // Range Dropdown Pill matching Screen 11: "Next 30 Days ▾"
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: state.selectedDays,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1E293B)),
                    isDense: true,
                    items: [
                      DropdownMenuItem(value: 7, child: Text(tr('next_7_days'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: 15, child: Text(tr('next_15_days'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: 30, child: Text(tr('next_30_days'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      DropdownMenuItem(value: 60, child: Text(tr('next_60_days'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    ],
                    onChanged: (days) {
                      if (days != null) {
                        ref.read(cashFlowProvider.notifier).loadCashFlow(days);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref.read(cashFlowProvider.notifier).loadCashFlow(state.selectedDays),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top KPI Row: Expected Inflow & Expected Outflow
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('expected_inflow'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatAmount(data?.expectedReceivables ?? 0.0),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
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
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('expected_outflow'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatAmount(data?.upcomingLiabilities ?? 0.0),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Projected Balance Chart Card matching Screen 11
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('projected_balance'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatAmount(data?.projectedBalance ?? 0.0),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F8F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${data?.growthRate.abs().toStringAsFixed(0) ?? 0}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Interactive Area Chart
                            if (data != null && data.timeline.isNotEmpty)
                              SizedBox(
                                height: 220,
                                width: double.infinity,
                                child: _InteractiveCashFlowChart(
                                  timeline: data.timeline,
                                  selectedIndex: state.selectedIndex ?? (data.timeline.length - 1),
                                  onPointSelected: (idx) {
                                    ref.read(cashFlowProvider.notifier).selectIndex(idx);
                                  },
                                  formatAmount: _formatAmount,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Business Health / Risk Indicator summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: data?.riskIndicator == 'low'
                                    ? const Color(0xFFE8F8F0)
                                    : (data?.riskIndicator == 'medium'
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFFEE2E2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                data?.riskIndicator == 'low'
                                    ? Icons.verified_user_outlined
                                    : (data?.riskIndicator == 'medium'
                                        ? Icons.trending_up
                                        : Icons.warning_amber_rounded),
                                color: data?.riskIndicator == 'low'
                                    ? const Color(0xFF10B981)
                                    : (data?.riskIndicator == 'medium'
                                        ? AppColors.primary
                                        : Colors.red),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data?.riskIndicator == 'low'
                                        ? tr('healthy_cash_reserve')
                                        : (data?.riskIndicator == 'medium'
                                            ? tr('balanced_working_capital')
                                            : tr('cash_flow_deficit_warning')),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tr('net_profit')}: ${_formatAmount((data?.expectedReceivables ?? 0.0) - (data?.upcomingLiabilities ?? 0.0))}.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _InteractiveCashFlowChart extends StatelessWidget {
  final List<CashFlowTimelinePoint> timeline;
  final int selectedIndex;
  final ValueChanged<int> onPointSelected;
  final String Function(double) formatAmount;

  const _InteractiveCashFlowChart({
    required this.timeline,
    required this.selectedIndex,
    required this.onPointSelected,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
          onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _CashFlowPainter(
              timeline: timeline,
              selectedIndex: selectedIndex,
              formatAmount: formatAmount,
            ),
          ),
        );
      },
    );
  }

  void _handleTouch(Offset localPos, double width) {
    if (timeline.isEmpty) return;
    final usableWidth = width - 40;
    final step = usableWidth / (timeline.length - 1);
    final relativeX = (localPos.dx - 20).clamp(0.0, usableWidth);
    final closest = (relativeX / step).round().clamp(0, timeline.length - 1);
    onPointSelected(closest);
  }
}

class _CashFlowPainter extends CustomPainter {
  final List<CashFlowTimelinePoint> timeline;
  final int selectedIndex;
  final String Function(double) formatAmount;

  _CashFlowPainter({
    required this.timeline,
    required this.selectedIndex,
    required this.formatAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (timeline.isEmpty) return;

    final bottomPadding = 30.0;
    final topPadding = 50.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final usableWidth = size.width - 40;
    final startX = 20.0;

    double minVal = timeline.first.balance;
    double maxVal = timeline.first.balance;
    for (final p in timeline) {
      if (p.balance < minVal) minVal = p.balance;
      if (p.balance > maxVal) maxVal = p.balance;
    }
    if (minVal == maxVal) {
      minVal -= 1000;
      maxVal += 1000;
    }
    final range = maxVal - minVal;

    // Draw horizontal dotted grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(startX, y), Offset(startX + usableWidth, y), gridPaint);
    }

    // Calculate points
    final points = <Offset>[];
    final step = usableWidth / (timeline.length - 1);
    for (int i = 0; i < timeline.length; i++) {
      final x = startX + (i * step);
      final normalized = (timeline[i].balance - minVal) / range;
      final y = topPadding + chartHeight - (normalized * chartHeight);
      points.add(Offset(x, y));
    }

    // Build smooth cubic bezier curve
    final path = Path();
    final fillPath = Path();
    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height - bottomPadding);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
      fillPath.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    fillPath.lineTo(points.last.dx, size.height - bottomPadding);
    fillPath.close();

    // Gradient fill beneath curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.20),
          const Color(0xFF2563EB).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw X-axis date labels
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Color(0xFF94A3B8),
    );

    for (int i = 0; i < timeline.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: timeline[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - (tp.width / 2), size.height - bottomPadding + 8));
    }

    // Selected pinpoint & Tooltip matching Screen 11
    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final selPt = points[selectedIndex];
      final item = timeline[selectedIndex];

      // Draw halo & blue dot
      final haloPaint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selPt, 8, haloPaint);

      final dotPaint = Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selPt, 4.5, dotPaint);

      final innerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selPt, 2, innerDot);

      // Tooltip Card pinned above
      final tooltipWidth = 100.0;
      final tooltipHeight = 44.0;
      double tooltipX = selPt.dx - (tooltipWidth / 2);
      if (tooltipX < 10) tooltipX = 10;
      if (tooltipX + tooltipWidth > size.width - 10) tooltipX = size.width - 10 - tooltipWidth;
      final tooltipY = selPt.dy - tooltipHeight - 12;

      // Dark card bubble
      final bubblePaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, bubblePaint);

      // Triangle pointer
      final pointer = Path()
        ..moveTo(selPt.dx - 5, tooltipY + tooltipHeight)
        ..lineTo(selPt.dx + 5, tooltipY + tooltipHeight)
        ..lineTo(selPt.dx, tooltipY + tooltipHeight + 5)
        ..close();
      canvas.drawPath(pointer, bubblePaint);

      // Amount text inside tooltip
      final amtPainter = TextPainter(
        text: TextSpan(
          text: formatAmount(item.balance),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      amtPainter.paint(
        canvas,
        Offset(tooltipX + (tooltipWidth - amtPainter.width) / 2, tooltipY + 6),
      );

      // Date text inside tooltip
      final datePainter = TextPainter(
        text: TextSpan(
          text: item.fullDate,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      datePainter.paint(
        canvas,
        Offset(tooltipX + (tooltipWidth - datePainter.width) / 2, tooltipY + 24),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.timeline != timeline;
  }
}
