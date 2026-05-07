import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/fixed_expense.dart';
import '../../../logic/budget/budget_cubit.dart';
import '../../../logic/budget/budget_state.dart';
import '../../../logic/expense/expense_cubit.dart';
import '../../../logic/expense/expense_state.dart';
import '../../../logic/fixed_expense/fixed_expense_cubit.dart';
import '../../../logic/fixed_expense/fixed_expense_state.dart';
import '../../widgets/budget_progress_card.dart';
import '../../widgets/category_picker.dart';
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
        actions: [
          // Nút thêm template chi tiêu cố định
          IconButton(
            onPressed: () => _showTemplateSheet(context),
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Thêm chi tiêu cố định',
          ),
        ],
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
              Text(
                '${templates.length} mục',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final template = templates[index];
              return FixedExpenseCard(
                template: template,
                onTap: () => _showConfirmDialog(context, template),
                onLongPress: () => _showTemplateOptionsDialog(
                  context,
                  template,
                ),
              );
            },
          ),
        ),
      ],
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
      text: editAmount != null ? editAmount.toStringAsFixed(0) : '',
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
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(
                                    color: Color(0xFFEF4444),
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
                                final amount = double.tryParse(
                                  amountController.text.trim(),
                                );
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Số tiền phải lớn hơn 0',
                                      ),
                                      backgroundColor:
                                          const Color(0xFFEF4444),
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

  /// Dialog xác nhận thanh toán chi tiêu cố định.
  void _showConfirmDialog(BuildContext context, FixedExpense template) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.payment, size: 36),
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Ghi nhận ${formatVND(template.amount)} cho "${template.title}"?\n\n'
          'Giao dịch sẽ được lưu vào lịch sử ngay lập tức.',
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
                  .confirmFixedExpense(template);
              Navigator.pop(dialogContext);

              // Hiện snackbar xác nhận
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
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expenseRed,
            ),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet tùy chọn khi long press template (Sửa / Xóa).
  void _showTemplateOptionsDialog(
    BuildContext context,
    FixedExpense template,
  ) {
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
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Tiêu đề
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  template.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(),
              // Sửa
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF60A5FA)),
                title: const Text('Chỉnh sửa'),
                subtitle: const Text('Thay đổi tên, số tiền, danh mục'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showTemplateSheet(context, editTemplate: template);
                },
              ),
              // Xóa
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                title: const Text('Xóa mẫu'),
                subtitle: const Text('Lịch sử giao dịch không bị ảnh hưởng'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteTemplate(context, template);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog xác nhận xóa template.
  void _confirmDeleteTemplate(BuildContext context, FixedExpense template) {
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
      _amountController.text = t.amount.toStringAsFixed(0);
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  backgroundColor: const Color(0xFF10B981),
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

    final amount = double.tryParse(amountText);
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
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
