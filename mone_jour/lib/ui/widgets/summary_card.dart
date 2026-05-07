import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';

/// Card tổng hợp thu/chi/balance ở đầu màn hình.
///
/// Thiết kế gradient nền tối → tạo cảm giác premium.
/// 3 cột: Chi tiêu | Balance | Thu nhập.
class SummaryCard extends StatelessWidget {
  final double totalExpense;
  final double totalIncome;
  final double balance;

  const SummaryCard({
    super.key,
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Balance lớn ở giữa ──
          Text(
            'Số dư',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatVND(balance),
            style: TextStyle(
              color: balance >= 0
                  ? const Color(0xFF34D399)
                  : const Color(0xFFF87171),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          // ── Thu nhập vs Chi tiêu ──
          Row(
            children: [
              // Thu nhập
              Expanded(
                child: _buildSubItem(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF34D399),
                  label: 'Thu nhập',
                  amount: formatVND(totalIncome),
                  amountColor: const Color(0xFF34D399),
                ),
              ),

              // Divider dọc
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),

              // Chi tiêu
              Expanded(
                child: _buildSubItem(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFF87171),
                  label: 'Chi tiêu',
                  amount: formatVND(totalExpense),
                  amountColor: const Color(0xFFF87171),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
    required Color amountColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
