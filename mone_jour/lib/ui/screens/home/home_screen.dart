import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../data/models/fixed_expense.dart';
import '../../../logic/budget/budget_cubit.dart';
import '../../../logic/budget/budget_state.dart';
import '../../../logic/expense/expense_cubit.dart';
import '../../../logic/expense/expense_state.dart';
import '../../../logic/fixed_expense/fixed_expense_cubit.dart';
import '../../../logic/fixed_expense/fixed_expense_state.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/expense_action_sheet.dart';
import '../../widgets/fixed_expense_card.dart';
import '../../widgets/grouped_transaction_list.dart';
import '../../widgets/summary_card.dart';

/// Màn hình Trang chủ — Dashboard tổng quan + Chi tiêu cố định.
///
/// Layout (cuộn dọc):
///   1. Lời chào theo thời gian trong ngày
///   2. SummaryCard (Balance, Thu nhập, Chi tiêu tháng này)
///   3. Section "Chi tiêu cố định" (cuộn ngang)
///   4. Danh sách giao dịch gần đây (5 gần nhất)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MoneJour',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Lời chào ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                _getGreeting(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // ── Summary Card ──
            BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                if (state is ExpenseLoaded) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SummaryCard(
                      totalExpense: state.totalExpense,
                      totalIncome: state.totalIncome,
                      balance: state.balance,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ── Section: Chi tiêu cố định ──
            BlocBuilder<FixedExpenseCubit, FixedExpenseState>(
              builder: (context, state) {
                if (state is FixedExpenseLoaded && state.templates.isNotEmpty) {
                  return _buildFixedExpenseSection(context, state.templates);
                }
                // Nếu chưa có template → hiển thị gợi ý tạo
                return _buildEmptyTemplateHint(context, theme);
              },
            ),

            // ── Section: Hạn mức chi tiêu ──
            BlocBuilder<BudgetCubit, BudgetState>(
              builder: (context, state) {
                if (state is BudgetLoaded && state.progresses.isNotEmpty) {
                  return _buildBudgetSection(context, state.progresses);
                }
                // Chưa có budget → gợi ý tạo
                return _buildEmptyBudgetHint(context, theme);
              },
            ),

            // ── Section: Giao dịch gần đây ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: Text(
                'Giao dịch gần đây',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) {
                if (state is ExpenseLoaded) {
                  return GroupedTransactionList(
                    expenses: state.expenses,
                    maxItems: 10,
                    onTap: (expense) => showExpenseActionSheet(context, expense),
                    onLongPress: (expense) => showExpenseActionSheet(context, expense),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Lời chào theo thời gian trong ngày.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng ☀️';
    if (hour < 18) return 'Chào buổi chiều 🌤️';
    return 'Chào buổi tối 🌙';
  }



  /// Section cuộn ngang hiển thị danh sách template.
  ///
  /// Hiển thị tối đa 3 card vừa màn hình, lướt ngang để xem thêm.
  /// Khi có >3 mục → hiện nút "Xem tất cả" mở bottom sheet danh sách đầy đủ.
  Widget _buildFixedExpenseSection(
    BuildContext context,
    List<FixedExpense> templates,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiêu cố định',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chỉ hiện "Xem tất cả" khi có nhiều hơn 3 mục
                  if (templates.length > 3)
                    TextButton(
                      onPressed: () =>
                          _showAllFixedExpenses(context, templates),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: Text(
                        'Tất cả (${templates.length})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _showTemplateSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: PageController(viewportFraction: 1.0),
            itemCount: (templates.length / 3).ceil(),
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 3;
              final endIndex =
                  (startIndex + 3).clamp(0, templates.length);
              final pageTemplates =
                  templates.sublist(startIndex, endIndex);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (int i = 0; i < pageTemplates.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: FixedExpenseCard(
                          template: pageTemplates[i],
                          onTap: () => _showFixedExpenseActions(
                            context,
                            pageTemplates[i],
                          ),
                        ),
                      ),
                    ],
                    // Giữ layout cân bằng khi trang cuối ít hơn 3 mục
                    for (int i = pageTemplates.length; i < 3; i++) ...[
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox()),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Bottom sheet hiển thị tất cả chi tiêu cố định dạng danh sách dọc.
  void _showAllFixedExpenses(
    BuildContext context,
    List<FixedExpense> templates,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chi tiêu cố định (${templates.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Danh sách
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final template = templates[index];
                  final category = getCategoryById(template.categoryId);

                  return ListTile(
                    leading: Container(
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
                    title: Text(
                      template.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Text(
                      formatVND(template.amount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.expenseRed,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showFixedExpenseActions(context, template);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gợi ý tạo template khi danh sách trống.
  Widget _buildEmptyTemplateHint(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => _showTemplateSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bookmark_add_outlined,
                  color: AppTheme.primaryPastel,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo chi tiêu cố định',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tiền trọ, điện nước, Netflix... thanh toán 1 chạm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  /// Gợi ý tạo hạn mức khi chưa có budget nào.
  Widget _buildEmptyBudgetHint(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: InkWell(
        onTap: () => _showSetBudgetDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.primaryPastel,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết lập hạn mức chi tiêu',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kiểm soát ngân sách theo danh mục mỗi tháng',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  /// Section hiển thị danh sách hạn mức chi tiêu với progress bar.
  Widget _buildBudgetSection(
    BuildContext context,
    List<BudgetProgress> progresses,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hạn mức chi tiêu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showSetBudgetDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: progresses
                .map((p) => BudgetProgressCard(
                      progress: p,
                      onTap: () => _showSetBudgetDialog(
                        context,
                        editCategoryId: p.categoryId,
                        editAmount: p.amountLimit,
                        editBudgetId: p.budgetId,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Dialog thêm/sửa hạn mức chi tiêu.
  void _showSetBudgetDialog(
    BuildContext context, {
    String? editCategoryId,
    double? editAmount,
    int? editBudgetId,
  }) {
    final isEdit = editCategoryId != null;
    String selectedCategory = editCategoryId ?? 'food';
    final amountController = TextEditingController(
      text: editAmount != null
          ? NumberFormat('#,###', 'vi_VN').format(editAmount.round())
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit
                          ? 'Chỉnh sửa hạn mức'
                          : 'Thiết lập hạn mức',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Danh mục
                    Text(
                      'Danh mục',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Chỉ cho chọn danh mục nếu đang thêm mới
                    AbsorbPointer(
                      absorbing: isEdit,
                      child: Opacity(
                        opacity: isEdit ? 0.6 : 1.0,
                        child: CategoryPicker(
                          selectedCategoryId: selectedCategory,
                          onSelected: (id) {
                            setSheetState(() => selectedCategory = id);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Số tiền
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      autofocus: !isEdit,
                      decoration: InputDecoration(
                        labelText: 'Hạn mức tháng (VND)',
                        hintText: 'VD: 1000000',
                        suffixText: '₫',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút hành động
                    Row(
                      children: [
                        // Nút xóa (chỉ hiện khi edit)
                        if (isEdit && editBudgetId != null)
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () {
                                  context
                                      .read<BudgetCubit>()
                                      .removeBudget(editBudgetId);
                                  Navigator.pop(sheetContext);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.dangerRed,
                                  side: const BorderSide(
                                    color: AppTheme.dangerRed,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Xóa'),
                              ),
                            ),
                          ),
                        if (isEdit) const SizedBox(width: 12),

                        // Nút lưu
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: FilledButton(
                              onPressed: () {
                                final cleanText = amountController.text
                                    .trim()
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                final amount = double.tryParse(cleanText);
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Số tiền phải lớn hơn 0',
                                      ),
                                      backgroundColor:
                                          AppTheme.dangerRed,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                context.read<BudgetCubit>().setBudget(
                                      categoryId: selectedCategory,
                                      amountLimit: amount,
                                    );
                                Navigator.pop(sheetContext);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryPastel,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isEdit ? 'Cập nhật' : 'Thiết lập',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom sheet hành động khi nhấn vào chi tiêu cố định.
  ///
  /// Gộp 3 chức năng: Xác nhận thanh toán + Chỉnh sửa + Xóa
  /// vào 1 sheet duy nhất thay vì tách tap/longpress riêng biệt.
  void _showFixedExpenseActions(BuildContext context, FixedExpense template) {
    final category = getCategoryById(template.categoryId);

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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Thông tin template
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatVND(template.amount),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.expenseRed,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),

              // Xác nhận thanh toán
              ListTile(
                leading: const Icon(
                  Icons.payment_rounded,
                  color: AppTheme.incomeGreen,
                ),
                title: const Text('Xác nhận thanh toán'),
                subtitle: Text(
                  'Ghi nhận ${formatVND(template.amount)} vào hôm nay',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context
                      .read<FixedExpenseCubit>()
                      .confirmFixedExpense(template);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Đã ghi nhận ${formatVND(template.amount)} — ${template.title}',
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppTheme.incomeGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Chỉnh sửa
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF60A5FA),
                ),
                title: const Text('Chỉnh sửa'),
                subtitle: const Text('Thay đổi tên, số tiền, danh mục'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showTemplateSheet(context, editTemplate: template);
                },
              ),

              // Xóa
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.dangerRed,
                ),
                title: const Text('Xóa mẫu'),
                subtitle: const Text('Lịch sử giao dịch không bị ảnh hưởng'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  // Dialog xác nhận xóa
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Xóa chi tiêu cố định?'),
                      content: Text(
                        'Xóa mẫu "${template.title}"?\n'
                        'Lịch sử giao dịch đã tạo từ mẫu này sẽ không bị ảnh hưởng.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          onPressed: () {
                            context
                                .read<FixedExpenseCubit>()
                                .deleteTemplate(template.id);
                            Navigator.pop(dialogContext);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.expenseRed,
                          ),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet thêm/sửa template chi tiêu cố định.
  void _showTemplateSheet(
    BuildContext context, {
    FixedExpense? editTemplate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<FixedExpenseCubit>(),
        child: _TemplateSheet(editTemplate: editTemplate),
      ),
    );
  }
}

/// Bottom Sheet thêm/sửa template chi tiêu cố định.
///
/// Hỗ trợ 2 chế độ:
///   - Thêm mới: editTemplate = null
///   - Chỉnh sửa: editTemplate != null → điền sẵn dữ liệu cũ
class _TemplateSheet extends StatefulWidget {
  final FixedExpense? editTemplate;

  const _TemplateSheet({this.editTemplate});

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'bills';

  bool get _isEditMode => widget.editTemplate != null;

  @override
  void initState() {
    super.initState();

    // Edit mode → điền dữ liệu cũ vào form
    if (_isEditMode) {
      final t = widget.editTemplate!;
      _titleController.text = t.title;
      _amountController.text = NumberFormat('#,###', 'vi_VN').format(t.amount.round());
      _noteController.text = t.note ?? '';
      _selectedCategory = t.categoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditMode ? 'Chỉnh sửa chi tiêu cố định' : 'Tạo chi tiêu cố định',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // ── Tên khoản chi ──
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tên khoản chi',
                hintText: 'VD: Tiền trọ, Netflix, Điện nước...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
              ),
              autofocus: !_isEditMode,
            ),
            const SizedBox(height: 16),

            // ── Số tiền ──
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Số tiền (VND)',
                hintText: '0',
                suffixText: '₫',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Danh mục ──
            Text(
              'Danh mục',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            CategoryPicker(
              selectedCategoryId: _selectedCategory,
              onSelected: (id) => setState(() => _selectedCategory = id),
            ),
            const SizedBox(height: 16),

            // ── Ghi chú ──
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            // ── Nút lưu ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.actionGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isEditMode ? 'Cập nhật' : 'Tạo mẫu',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty) {
      _showError('Vui lòng nhập tên khoản chi');
      return;
    }

    final cleanAmountText = amountText.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.tryParse(cleanAmountText);
    if (amount == null || amount <= 0) {
      _showError('Số tiền phải lớn hơn 0');
      return;
    }

    final cubit = context.read<FixedExpenseCubit>();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (_isEditMode) {
      // Edit mode: cập nhật template hiện có
      final updated = widget.editTemplate!
        ..title = title
        ..amount = amount
        ..categoryId = _selectedCategory
        ..note = note;
      cubit.updateTemplate(updated);
    } else {
      // Add mode: tạo mới
      cubit.addTemplate(
        title: title,
        amount: amount,
        categoryId: _selectedCategory,
        note: note,
      );
    }

    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
