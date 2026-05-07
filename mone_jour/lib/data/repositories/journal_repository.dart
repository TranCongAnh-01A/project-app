import 'package:isar/isar.dart';

import '../../services/database_service.dart';
import '../models/journal_entry.dart';

/// Repository pattern cho nhật ký — tách logic truy vấn khỏi UI layer.
class JournalRepository {
  Isar get _db => DatabaseService.instance;

  /// Thêm entry nhật ký mới.
  Future<void> add(JournalEntry entry) async {
    await _db.writeTxn(() => _db.journalEntrys.put(entry));
  }

  /// Cập nhật entry nhật ký.
  Future<void> update(JournalEntry entry) async {
    await _db.writeTxn(() => _db.journalEntrys.put(entry));
  }

  /// Xóa entry nhật ký theo ID.
  Future<void> delete(int id) async {
    await _db.writeTxn(() => _db.journalEntrys.delete(id));
  }

  /// Lấy tất cả nhật ký, sắp xếp mới nhất trước.
  Future<List<JournalEntry>> getAll() async {
    return _db.journalEntrys.where().sortByDateDesc().findAll();
  }

  /// Lấy nhật ký trong khoảng thời gian.
  Future<List<JournalEntry>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _db.journalEntrys
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  }

  /// Lấy nhật ký theo mood (1-5) để filter.
  Future<List<JournalEntry>> getByMood(int mood) async {
    return _db.journalEntrys
        .filter()
        .moodEqualTo(mood)
        .sortByDateDesc()
        .findAll();
  }

  /// Tính mood trung bình trong khoảng thời gian (cho dashboard).
  Future<double> getAverageMood(DateTime start, DateTime end) async {
    final entries = await _db.journalEntrys
        .filter()
        .dateBetween(start, end)
        .findAll();

    if (entries.isEmpty) return 0;

    final total = entries.fold(0, (sum, e) => sum + e.mood);
    return total / entries.length;
  }

  /// Stream theo dõi thay đổi.
  Stream<void> watchChanges() {
    return _db.journalEntrys.watchLazy();
  }
}
