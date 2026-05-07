import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';
import '../../core/utils/currency_formatter.dart';
import '../../logic/budget/budget_state.dart';

/// Widget hiển thị tiến trình budget 1 danh mục.
///
/// Gồm: icon danh mục + tên + progress bar + số tiền.
/// Màu tự thay đổi: xanh (safe) → cam (warning ≥80%) → đỏ (exceeded ≥100%).
class BudgetProgressCard extends StatelessWidget {
  final BudgetProgress progress;
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = getCategoryById(progress.categoryId);

    // Màu theo trạng thái
    final statusColor = switch (progress.status) {
      BudgetStatus.safe => const Color(0xFF10B981),
      BudgetStatus.warning => const Color(0xFFF59E0B),
      BudgetStatus.exceeded => const Color(0xFFEF4444),
    };

    // Clamp ratio cho progress bar (max 1.0 để không tràn visual)
    final clampedRatio = progress.ratio.clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Icon + Tên + Phần trăm ──
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
                      category.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Phần trăm
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${progress.percentage}%',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Progress bar ──
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: clampedRatio,
                  backgroundColor:
                      theme.colorScheme.outline.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 8),

              // ── Row 2: Đã chi / Hạn mức ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã chi: ${formatVND(progress.currentSpending)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'Hạn mức: ${formatVND(progress.amountLimit)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),

              // ── Cảnh báo nếu vượt ──
              if (progress.status == BudgetStatus.exceeded) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Vượt ${formatVND(progress.currentSpending - progress.amountLimit)}',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
