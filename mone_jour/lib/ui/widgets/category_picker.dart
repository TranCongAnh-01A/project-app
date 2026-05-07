import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';

/// Grid picker cho danh mục chi tiêu.
///
/// Hiển thị 9 danh mục dạng lưới 3x3, mỗi ô có icon + tên.
/// Ô được chọn có viền highlight màu danh mục đó.
class CategoryPicker extends StatelessWidget {
  final String selectedCategoryId;
  final ValueChanged<String> onSelected;

  const CategoryPicker({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: defaultExpenseCategories.length,
      itemBuilder: (context, index) {
        final category = defaultExpenseCategories[index];
        final isSelected = category.id == selectedCategoryId;

        return GestureDetector(
          onTap: () => onSelected(category.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? category.color.withValues(alpha: 0.15)
                  : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? category.color
                    : theme.colorScheme.outline.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  color: isSelected
                      ? category.color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? category.color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
