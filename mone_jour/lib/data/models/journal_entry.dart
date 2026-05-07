import 'package:isar/isar.dart';

part 'journal_entry.g.dart';

/// Nhật ký cảm xúc — gắn liền với trải nghiệm chi tiêu hoặc viết tự do.
///
/// Tại sao tách riêng thay vì nhúng vào Expense:
///   - Người dùng có thể viết nhật ký mà không cần giao dịch
///   - Một nhật ký có thể liên quan đến nhiều giao dịch trong ngày
///   - Tách biệt giúp query + filter dễ hơn
@collection
class JournalEntry {
  Id id = Isar.autoIncrement;

  /// Tiêu đề ngắn gọn
  late String title;

  /// Nội dung nhật ký (plain text)
  late String content;

  /// Mức cảm xúc: 1 = Rất tệ, 2 = Buồn, 3 = Bình thường, 4 = Vui, 5 = Tuyệt vời
  @Index()
  late int mood;

  /// Ngày viết nhật ký
  @Index()
  late DateTime date;

  /// Đường dẫn ảnh đính kèm (local file, Phase 2)
  String? imagePath;

  /// Thời điểm tạo record
  late DateTime createdAt;
}
