import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../data/models/expense.dart';
import '../../../data/repositories/expense_repository.dart';
import 'expense_action_sheet.dart';
import 'grouped_transaction_list.dart';

class FilterTransactionSheet extends StatefulWidget {
  const FilterTransactionSheet({super.key});

  @override
  State<FilterTransactionSheet> createState() => _FilterTransactionSheetState();
}

class _FilterTransactionSheetState extends State<FilterTransactionSheet> {
  final _noteController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  String? _selectedCategory;

  bool _minAmountError = false;
  bool _maxAmountError = false;
  String? _formError;

  List<Expense>? _results;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _onFilter() async {
    final note = _noteController.text.trim();
    final minAmountStr = _minAmountController.text.trim().replaceAll('.', '');
    final maxAmountStr = _maxAmountController.text.trim().replaceAll('.', '');
    
    final minAmount = double.tryParse(minAmountStr);
    final maxAmount = double.tryParse(maxAmountStr);

    setState(() {
      _minAmountError = false;
      _maxAmountError = false;
      _formError = null;
    });

    // Validate 1: Nếu nhập 1 ô số tiền mà ô kia trống
    if (minAmount != null && maxAmount == null) {
      setState(() => _maxAmountError = true);
      return;
    }
    if (minAmount == null && maxAmount != null) {
      setState(() => _minAmountError = true);
      return;
    }

    // Validate 2: Phải điền ít nhất 1 trường
    if (note.isEmpty && minAmount == null && maxAmount == null && _selectedCategory == null) {
      setState(() => _formError = 'Vui lòng nhập ít nhất 1 điều kiện để lọc');
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final repo = ExpenseRepository();
      final expenses = await repo.searchExpenses(
        note: note,
        minAmount: minAmount,
        maxAmount: maxAmount,
        categoryId: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _results = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lọc: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle bar ──
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lọc giao dịch',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // ── Form Area (Scrollable) ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Ghi chú
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Tên ghi chú',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Khoảng tiền (Row 2 ô)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            onChanged: (_) {
                              if (_minAmountError) setState(() => _minAmountError = false);
                            },
                            decoration: InputDecoration(
                              labelText: 'Từ (đ)',
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _minAmountError ? AppTheme.dangerRed : theme.colorScheme.outline,
                                  width: _minAmountError ? 2.0 : 1.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            onChanged: (_) {
                              if (_maxAmountError) setState(() => _maxAmountError = false);
                            },
                            decoration: InputDecoration(
                              labelText: 'Đến (đ)',
                              prefixIcon: const Icon(Icons.money_off),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _maxAmountError ? AppTheme.dangerRed : theme.colorScheme.outline,
                                  width: _maxAmountError ? 2.0 : 1.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Danh mục
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Danh mục',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Tất cả danh mục'),
                        ),
                        ...defaultExpenseCategories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color),
                                const SizedBox(width: 8),
                                Text(cat.name),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Lỗi Form chung
                    if (_formError != null) ...[
                      Text(
                        _formError!,
                        style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nút Lọc
                    FilledButton.icon(
                      onPressed: _onFilter,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Lọc kết quả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // ── Kết quả tìm kiếm ──
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_results != null) ...[
                      Row(
                        children: [
                          Text(
                            'Kết quả',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_results!.length} giao dịch',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_results!.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
                                const SizedBox(height: 8),
                                Text('Không tìm thấy giao dịch nào', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        )
                      else
                        GroupedTransactionList(
                          expenses: _results!,
                          onTap: (expense) => showExpenseActionSheet(context, expense),
                          onLongPress: (expense) => showExpenseActionSheet(context, expense),
                        ),
                      const SizedBox(height: 40), // Padding bottom
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
