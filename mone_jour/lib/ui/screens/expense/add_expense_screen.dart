import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/expense.dart';
import '../../../logic/expense/expense_cubit.dart';
import '../../widgets/category_picker.dart';

/// Màn hình thêm/sửa khoản chi tiêu.
///
/// Hỗ trợ 2 chế độ:
///   - Thêm mới: editExpense = null
///   - Chỉnh sửa: editExpense != null → điền sẵn dữ liệu cũ
class AddExpenseScreen extends StatefulWidget {
  final Expense? editExpense;

  const AddExpenseScreen({super.key, this.editExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'food';
  bool _isIncome = false;
  late DateTime _selectedDate;
  bool _isSaving = false;

  /// Viền đỏ khi validation thất bại
  bool _amountError = false;

  bool get _isEditMode => widget.editExpense != null;

  @override
  void initState() {
    super.initState();

    // Edit mode → điền dữ liệu cũ vào form
    if (_isEditMode) {
      final e = widget.editExpense!;
      _amountController.text = CurrencyInputFormatter()
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: e.amount.round().toString()),
          )
          .text;
      _noteController.text = e.note ?? '';
      _selectedCategory = e.category;
      _isIncome = e.isIncome;
      _selectedDate = e.date;
    } else {
      _selectedDate = DateTime.now();
    }

    // Xóa viền đỏ khi user bắt đầu nhập
    _amountController.addListener(() {
      if (_amountError && _amountController.text.isNotEmpty) {
        setState(() => _amountError = false);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        actions: [
          // Nút lưu
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.actionGreen,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Toggle Thu nhập / Chi tiêu ──
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Chi tiêu'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Thu nhập'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
                selected: {_isIncome},
                onSelectionChanged: (value) {
                  setState(() {
                    _isIncome = value.first;
                    // Thu nhập → tự gán category 'income', không cần chọn
                    // Chi tiêu → reset về 'food' nếu đang ở 'income'
                    if (_isIncome) {
                      _selectedCategory = 'income';
                    } else if (_selectedCategory == 'income') {
                      _selectedCategory = 'food';
                    }
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _isIncome
                          ? AppTheme.actionGreen.withValues(alpha: 0.15)
                          : AppTheme.dangerRed.withValues(alpha: 0.15);
                    }
                    return null;
                  }),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Số tiền ──
            Text(
              'Số tiền (VND)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isIncome
                    ? AppTheme.actionGreen
                    : AppTheme.dangerRed,
              ),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: '₫',
                suffixStyle: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _amountError
                        ? AppTheme.dangerRed
                        : theme.colorScheme.outline,
                    width: _amountError ? 2.0 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _amountError
                        ? AppTheme.dangerRed
                        : theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
                filled: true,
              ),
              autofocus: true,
            ),

            const SizedBox(height: 24),

            // ── Danh mục (chỉ hiện khi chi tiêu) ──
            if (!_isIncome) ...[
              Text(
                'Danh mục',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CategoryPicker(
                selectedCategoryId: _selectedCategory,
                onSelected: (id) => setState(() => _selectedCategory = id),
              ),
            ],

            const SizedBox(height: 24),

            // ── Ngày ──
            Text(
              'Ngày',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDateFull(_selectedDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Ghi chú ──
            Text(
              'Ghi chú (tùy chọn)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Cà phê sáng với bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mở DatePicker chọn ngày giao dịch.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Validate + lưu giao dịch vào Isar.
  Future<void> _save() async {
    // Validate số tiền
    final amountText = _amountController.text.trim();
    final cleanAmountText = amountText.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.tryParse(cleanAmountText);

    if (amountText.isEmpty || amount == null || amount <= 0) {
      setState(() => _amountError = true);
      return;
    }

    // Lưu reference cubit trước async gap
    final expenseCubit = context.read<ExpenseCubit>();

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Tạo object mới thay vì mutate trực tiếp Isar managed object
        final updated = Expense()
          ..id = widget.editExpense!.id
          ..amount = amount
          ..category = _selectedCategory
          ..isIncome = _isIncome
          ..date = _selectedDate
          ..note = _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim()
          ..createdAt = widget.editExpense!.createdAt;
        await expenseCubit.updateExpense(updated);
      } else {
        // Add mode: tạo mới
        await expenseCubit.addExpense(
          amount: amount,
          category: _selectedCategory,
          isIncome: _isIncome,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Lỗi lưu dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
