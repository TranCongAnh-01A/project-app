import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';

/// Grid picker cho danh mục chi tiêu.
///
/// Hiển thị 9 danh mục dạng lưới 3x3, mỗi ô có icon + tên.
/// Ô được chọn có nền hồng đậm hơn + viền màu danh mục.
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
                  ? category.color.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? category.color
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
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
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected
                        ? category.color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
