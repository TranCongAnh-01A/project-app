import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/fixed_expense.dart';

/// Thẻ chi tiêu cố định — hiển thị trên Home, nhấn để thanh toán nhanh.
///
/// Thiết kế: card nhỏ gọn nằm ngang, icon danh mục + tiêu đề + số tiền.
/// Border trái có màu danh mục để nhận diện nhanh.
class FixedExpenseCard extends StatelessWidget {
  final FixedExpense template;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FixedExpenseCard({
    super.key,
    required this.template,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final category = getCategoryById(template.categoryId);
    final theme = Theme.of(context);

    return SizedBox(
      width: 180,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: category.color, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon + Tiêu đề ──
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        template.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Số tiền ──
                Text(
                  formatVND(template.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ── Hint nhấn ──
                const SizedBox(height: 4),
                Text(
                  'Nhấn để thanh toán',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    fontSize: 10,
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
