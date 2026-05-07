import 'package:isar/isar.dart';

import '../../services/database_service.dart';
import '../models/expense.dart';

/// Repository pattern — tách biệt logic truy vấn database khỏi UI/Cubit.
///
/// Tại sao dùng Repository thay vì gọi Isar trực tiếp trong Cubit:
///   - Cubit chỉ quản lý state, không biết về Isar
///   - Dễ swap database engine (Isar → SQLite) mà không sửa Cubit
///   - Dễ mock khi viết unit test
class ExpenseRepository {
  Isar get _db => DatabaseService.instance;

  /// Thêm khoản chi tiêu/thu nhập mới.
  Future<void> add(Expense expense) async {
    await _db.writeTxn(() => _db.expenses.put(expense));
  }

  /// Cập nhật khoản chi tiêu đã tồn tại.
  Future<void> update(Expense expense) async {
    await _db.writeTxn(() => _db.expenses.put(expense));
  }

  /// Xóa khoản chi tiêu theo ID.
  Future<void> delete(int id) async {
    await _db.writeTxn(() => _db.expenses.delete(id));
  }

  /// Lấy tất cả chi tiêu trong khoảng thời gian, sắp xếp mới nhất trước.
  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    return _db.expenses
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Lấy tất cả chi tiêu của 1 tháng cụ thể.
  Future<List<Expense>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getByDateRange(start, end);
  }

  /// Tổng chi tiêu (chỉ khoản chi, không tính thu nhập) trong khoảng thời gian.
  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final expenses = await _db.expenses
        .filter()
        .dateBetween(start, end)
        .isIncomeEqualTo(false)
        .findAll();

    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  /// Tổng thu nhập trong khoảng thời gian.
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final incomes = await _db.expenses
        .filter()
        .dateBetween(start, end)
        .isIncomeEqualTo(true)
        .findAll();

    return incomes.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  /// Thống kê chi tiêu theo danh mục (cho biểu đồ tròn).
  Future<Map<String, double>> getExpenseByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await _db.expenses
        .filter()
        .dateBetween(start, end)
        .isIncomeEqualTo(false)
        .findAll();

    final result = <String, double>{};
    for (final e in expenses) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  /// Stream theo dõi thay đổi (trigger rebuild UI khi data thay đổi).
  Stream<void> watchChanges() {
    return _db.expenses.watchLazy();
  }
}
