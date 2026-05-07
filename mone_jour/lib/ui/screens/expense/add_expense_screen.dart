import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../data/models/expense.dart';
import '../../../logic/expense/expense_cubit.dart';
import '../../widgets/category_picker.dart';

/// Màn hình thêm/sửa khoản chi tiêu.
///
/// Luồng:
///   1. Nhập số tiền (bàn phím số, auto-format VND)
///   2. Chọn danh mục (grid 3x3)
///   3. Toggle Thu nhập / Chi tiêu
///   4. Chọn ngày (DatePicker)
///   5. Ghi chú (tùy chọn)
///   6. Lưu → pop về danh sách
class AddExpenseScreen extends StatefulWidget {
  /// Nếu không null → chế độ sửa (edit mode).
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

  bool get _isEditMode => widget.editExpense != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Nếu edit mode → điền dữ liệu cũ vào form
    if (_isEditMode) {
      final e = widget.editExpense!;
      _amountController.text = e.amount.toStringAsFixed(0);
      _noteController.text = e.note ?? '';
      _selectedCategory = e.category;
      _isIncome = e.isIncome;
      _selectedDate = e.date;
    }
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
                backgroundColor: const Color(0xFF10B981),
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
                  setState(() => _isIncome = value.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _isIncome
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15);
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isIncome
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
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
                filled: true,
              ),
              autofocus: !_isEditMode,
            ),

            const SizedBox(height: 24),

            // ── Danh mục ──
            Text(
              'Danh mục',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CategoryPicker(
              selectedCategoryId: _selectedCategory,
              onSelected: (id) => setState(() => _selectedCategory = id),
            ),

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
    if (amountText.isEmpty) {
      _showError('Vui lòng nhập số tiền');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Số tiền phải lớn hơn 0');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final cubit = context.read<ExpenseCubit>();

      if (_isEditMode) {
        // Edit mode: cập nhật expense hiện có
        final updated = widget.editExpense!
          ..amount = amount
          ..category = _selectedCategory
          ..date = _selectedDate
          ..isIncome = _isIncome
          ..note = _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim();

        await cubit.updateExpense(updated);
      } else {
        // Add mode: tạo mới
        await cubit.addExpense(
          amount: amount,
          category: _selectedCategory,
          date: _selectedDate,
          isIncome: _isIncome,
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
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
