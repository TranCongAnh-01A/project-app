/// AudioRepository: CRUD + Phân trang cursor-based cho bảng audio_metadata.
///
/// Tại sao cursor-based pagination (thay vì offset):
/// - Offset pagination bị "trôi" khi có INSERT/DELETE giữa các trang
/// - Cursor (dựa trên created_at) đảm bảo nhất quán ngay cả khi data thay đổi
/// - PostgreSQL tận dụng B-tree index trên created_at → O(log n) thay vì O(n)
///
/// Tại sao tách Repository khỏi Service:
/// - Service lo kết nối, Repository lo business logic CRUD
/// - Dễ mock Repository khi test Cubit
/// - SOLID: Single Responsibility
///
/// Thứ tự method chain Supabase (quan trọng):
///   .from → .select → FILTERS (.eq/.lt/.or) → .order → .limit
///   Sai thứ tự sẽ lỗi compile vì PostgrestTransformBuilder không có filter methods.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/audio_metadata.dart';

class AudioRepository {
  final SupabaseClient _client;

  /// Số item mỗi trang — 20 là sweet spot giữa UX và bandwidth
  static const int pageSize = 20;
  static const String _table = 'audio_metadata';

  AudioRepository(this._client);

  // ═══════════════════════════════════════════
  // READ — Danh sách + Phân trang + Tìm kiếm
  // ═══════════════════════════════════════════

  /// Lấy 1 trang audio, sắp xếp mới nhất trước.
  ///
  /// [cursor]: ISO8601 created_at của item cuối trang trước → load trang tiếp.
  /// [search]: Tìm theo title hoặc channel_name (ilike).
  /// Trả về list rỗng khi hết data (dùng để dừng infinite scroll).
  Future<List<AudioMetadata>> fetchPage({
    String? cursor,
    String? search,
    int limit = pageSize,
  }) async {
    try {
      // Supabase method chain: select → FILTERS → order → limit
      // Filter methods (.lt, .or) chỉ có trên PostgrestFilterBuilder,
      // nên phải gọi TRƯỚC .order()/.limit() (trả về TransformBuilder).
      var query = _client.from(_table).select();

      // Cursor pagination: chỉ lấy record có created_at < cursor (cũ hơn)
      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }

      // Full-text search trên title + channel_name + custom_name
      if (search != null && search.trim().isNotEmpty) {
        final pattern = '%${search.trim()}%';
        query = query.or(
          'title.ilike.$pattern,channel_name.ilike.$pattern,'
          'custom_name.ilike.$pattern',
        );
      }

      // Transform: sắp xếp + giới hạn (gọi cuối cùng)
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AudioMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AudioRepositoryException('Lỗi tải danh sách audio: $e');
    }
  }

  /// Lấy danh sách yêu thích (cursor-based).
  Future<List<AudioMetadata>> fetchFavorites({
    String? cursor,
    int limit = pageSize,
  }) async {
    try {
      // Filter trước, transform sau
      var query = _client
          .from(_table)
          .select()
          .eq('is_favorite', true);

      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => AudioMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AudioRepositoryException('Lỗi tải danh sách yêu thích: $e');
    }
  }

  /// Tìm 1 track theo video_id (check trùng trước khi ingest).
  Future<AudioMetadata?> findByVideoId(String videoId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('video_id', videoId)
          .maybeSingle();

      if (response == null) return null;

      return AudioMetadata.fromJson(response);
    } catch (e) {
      throw AudioRepositoryException('Lỗi tìm audio "$videoId": $e');
    }
  }

  // ═══════════════════════════════════════════
  // CREATE — Thêm track mới
  // ═══════════════════════════════════════════

  /// Lưu metadata sau khi pipeline nén + upload Telegram hoàn tất.
  Future<AudioMetadata> insert(AudioMetadata track) async {
    try {
      final data = track.toInsertJson();

      // Gắn user_id từ auth session (RLS cần field này)
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        data['user_id'] = userId;
      }

      final response = await _client
          .from(_table)
          .insert(data)
          .select()
          .single();

      return AudioMetadata.fromJson(response);
    } catch (e) {
      throw AudioRepositoryException('Lỗi lưu metadata audio: $e');
    }
  }

  // ═══════════════════════════════════════════
  // UPDATE — Sửa tên / Toggle yêu thích
  // ═══════════════════════════════════════════

  /// Đổi tên hiển thị (custom_name) cho track.
  Future<AudioMetadata> updateCustomName(String id, String? newName) async {
    try {
      final response = await _client
          .from(_table)
          .update({
            'custom_name': newName,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return AudioMetadata.fromJson(response);
    } catch (e) {
      throw AudioRepositoryException('Lỗi cập nhật tên: $e');
    }
  }

  /// Toggle yêu thích (flip boolean is_favorite).
  Future<AudioMetadata> toggleFavorite(String id, {required bool currentValue}) async {
    try {
      final response = await _client
          .from(_table)
          .update({
            'is_favorite': !currentValue,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return AudioMetadata.fromJson(response);
    } catch (e) {
      throw AudioRepositoryException('Lỗi toggle yêu thích: $e');
    }
  }

  // ═══════════════════════════════════════════
  // DELETE — Xóa track
  // ═══════════════════════════════════════════

  /// Xóa metadata khỏi Supabase.
  /// Lưu ý: file trên Telegram không xóa được (API không hỗ trợ).
  /// → Chi phí storage = 0 vì Telegram không giới hạn lưu trữ.
  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw AudioRepositoryException('Lỗi xóa audio: $e');
    }
  }

  // ═══════════════════════════════════════════
  // STATS — Thống kê
  // ═══════════════════════════════════════════

  /// Đếm tổng số track (cho dashboard).
  Future<int> count() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw AudioRepositoryException('Lỗi đếm audio: $e');
    }
  }
}

/// Exception riêng cho AudioRepository — dễ bắt ngoại lệ cụ thể ở Cubit.
class AudioRepositoryException implements Exception {
  final String message;
  const AudioRepositoryException(this.message);

  @override
  String toString() => 'AudioRepositoryException: $message';
}
