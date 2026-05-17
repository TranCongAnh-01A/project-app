import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/expense.dart';
import '../../logic/expense/expense_cubit.dart';
import '../screens/expense/add_expense_screen.dart';

import 'package:intl/intl.dart';

/// Hiển thị action sheet khi tap/longpress vào giao dịch.
///
/// Tại sao dùng shared utility thay vì code trong từng screen:
///   - DRY: cùng logic xóa/sửa ở HomeScreen + ExpenseListScreen
///   - Dễ thêm actions mới (undo, share...) chỉ cần sửa 1 nơi
///   - UX nhất quán: mọi nơi đều hiển thị bottom sheet giống nhau
void showExpenseActionSheet(BuildContext context, Expense expense) {
  final theme = Theme.of(context);
  final categoryName = expense.isIncome ? 'Thu nhập' : expense.category;
  final amountColor = expense.isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
  final sign = expense.isIncome ? '+' : '-';

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Thông tin giao dịch + thời gian tạo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.note?.isNotEmpty == true
                              ? expense.note!
                              : categoryName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$sign${formatVND(expense.amount)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Thời gian tạo giao dịch
                  Text(
                    DateFormat('dd/MM/yyyy\nHH:mm').format(expense.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Chỉnh sửa
            ListTile(
              enabled: !expense.isFixed,
              leading: Icon(
                Icons.edit_outlined,
                color: expense.isFixed
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                    : theme.colorScheme.primary,
              ),
              title: Text(
                'Chỉnh sửa',
                style: TextStyle(
                  color: expense.isFixed
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : null,
                ),
              ),
              subtitle: Text(
                expense.isFixed
                    ? 'Không thể sửa khoản thu/chi cố định'
                    : 'Thay đổi số tiền, danh mục, ghi chú',
                style: TextStyle(
                  color: expense.isFixed
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : null,
                ),
              ),
              onTap: expense.isFixed
                  ? null
                  : () {
                      Navigator.pop(sheetContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<ExpenseCubit>(),
                            child: AddExpenseScreen(editExpense: expense),
                          ),
                        ),
                      );
                    },
            ),

            // Xóa
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppTheme.dangerRed,
              ),
              title: const Text('Xóa giao dịch'),
              subtitle: const Text('Không thể hoàn tác'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteConfirmation(context, expense);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// Dialog xác nhận xóa — tách riêng để giữ code gọn.
void _showDeleteConfirmation(BuildContext context, Expense expense) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa giao dịch?'),
      content: const Text('Bạn có chắc muốn xóa khoản này? Không thể hoàn tác.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            context.read<ExpenseCubit>().deleteExpense(expense.id);
            Navigator.pop(dialogContext);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.dangerRed,
          ),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
