import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/expense_grouper.dart';
import '../../data/models/expense.dart';

/// Widget hiển thị lịch sử giao dịch gộp nhóm theo ngày.
///
/// Cấu trúc giống app ngân hàng:
///   ┌─────────────────────────────────────┐
///   │  3 THÁNG 5               -250.000 ₫ │  ← Header ngày
///   ├─────────────────────────────────────┤
///   │  🍔 Ăn uống   Cơm trưa   -50.000 ₫ │  ← Item giao dịch
///   │  🚗 Di chuyển  Grab      -100.000 ₫ │
///   │  💰 Thu nhập   Lương    +200.000 ₫  │
///   └─────────────────────────────────────┘
class GroupedTransactionList extends StatelessWidget {
  final List<Expense> expenses;

  /// Số giao dịch tối đa hiển thị (null = hiện tất cả).
  final int? maxItems;

  /// Callback khi nhấn vào 1 giao dịch.
  final void Function(Expense)? onTap;

  /// Callback khi nhấn giữ 1 giao dịch (VD: xóa).
  final void Function(Expense)? onLongPress;

  const GroupedTransactionList({
    super.key,
    required this.expenses,
    this.maxItems,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _buildEmptyState(context);
    }

    // Giới hạn số lượng nếu cần
    final displayExpenses =
        maxItems != null ? expenses.take(maxItems!).toList() : expenses;

    // Gom nhóm theo ngày
    final grouped = groupExpensesByDate(displayExpenses);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: grouped.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final dayExpenses = grouped[date]!;

        return _DayGroup(
          date: date,
          expenses: dayExpenses,
          onTap: onTap,
          onLongPress: onLongPress,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có giao dịch nào',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhóm giao dịch trong 1 ngày — Header + danh sách items.
class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<Expense> expenses;
  final void Function(Expense)? onTap;
  final void Function(Expense)? onLongPress;

  const _DayGroup({
    required this.date,
    required this.expenses,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayBalance = calculateDayBalance(expenses);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ngày ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDayHeader(date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                formatVNDSigned(dayBalance),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: dayBalance >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Đường kẻ phân cách mỏng
        Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),

        // ── Danh sách giao dịch trong ngày ──
        ...expenses.map((expense) => _TransactionItem(
              expense: expense,
              onTap: onTap != null ? () => onTap!(expense) : null,
              onLongPress:
                  onLongPress != null ? () => onLongPress!(expense) : null,
            )),
      ],
    );
  }

  /// Format ngày theo kiểu "7 THÁNG 5".
  String _formatDayHeader(DateTime date) {
    return '${date.day} THÁNG ${date.month}';
  }
}

/// Item hiển thị 1 giao dịch.
class _TransactionItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _TransactionItem({
    required this.expense,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = getCategoryById(expense.category);
    final isIncome = expense.isIncome;

    // Màu số tiền: xanh lá cho thu nhập, dùng theme cho chi tiêu
    final amountColor = isIncome
        ? const Color(0xFF10B981)
        : theme.colorScheme.onSurface.withValues(alpha: 0.8);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // ── Icon danh mục ──
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // ── Tên + ghi chú ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      expense.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Số tiền ──
            Text(
              '${isIncome ? '+' : '-'}${formatVND(expense.amount)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
