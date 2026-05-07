import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';

/// Card tổng hợp thu/chi/balance — gradient hồng pastel.
///
/// Layout: Balance lớn chính giữa, bên dưới 2 cột Thu nhập / Chi tiêu.
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Số dư ──
          Text(
            'Số dư hiện tại',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatVND(balance),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 24),
          Divider(color: Theme.of(context).colorScheme.outline, height: 1),
          const SizedBox(height: 16),

          // ── Thu nhập vs Chi tiêu ──
          Row(
            children: [
              Expanded(
                child: _buildSubItem(
                  context: context,
                  icon: Icons.arrow_downward_rounded,
                  label: 'Thu nhập',
                  amount: formatVND(totalIncome),
                  color: AppTheme.incomeGreen,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outline,
              ),
              Expanded(
                child: _buildSubItem(
                  context: context,
                  icon: Icons.arrow_upward_rounded,
                  label: 'Chi tiêu',
                  amount: formatVND(totalExpense),
                  color: AppTheme.expenseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

