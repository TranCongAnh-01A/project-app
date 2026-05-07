import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';

/// Card hiển thị 1 khoản chi tiêu/thu nhập trong danh sách.
///
/// Thiết kế: icon danh mục bên trái, thông tin ở giữa, số tiền bên phải.
/// Tap → callback onTap (mở edit), Long press → callback onLongPress (xóa).
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final category = getCategoryById(expense.category);
    final theme = Theme.of(context);
    final isIncome = expense.isIncome;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Icon danh mục (hình tròn có màu nền) ──
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // ── Thông tin: tên danh mục + ghi chú + ngày ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (expense.note != null && expense.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          expense.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatDateShort(expense.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Số tiền (xanh = thu nhập, đỏ = chi tiêu) ──
              Text(
                '${isIncome ? '+' : '-'}${formatVND(expense.amount)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isIncome
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
