/// ChatRepository: CRUD + Realtime cho phòng chat chung.
///
/// Tại sao dùng Supabase Realtime thay vì polling:
/// - Tiết kiệm bandwidth: chỉ nhận tin mới thay vì re-query toàn bộ
/// - UX mượt: tin nhắn xuất hiện tức thì (< 200ms trong cùng region)
/// - Supabase Realtime dựa trên Phoenix Channels (Elixir), rất ổn định
///
/// Kiến trúc 2 lớp cho chat:
/// 1. [fetchMessages] — Load batch tin nhắn cũ (cursor pagination, infinite scroll)
/// 2. [onNewMessage] stream — Tin nhắn mới realtime (INSERT events)
/// ChatCubit sẽ merge 2 nguồn này vào 1 danh sách UI.
///
/// Thứ tự method chain Supabase:
///   .from → .select → FILTERS (.lt) → .order → .limit
library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client;

  /// Số tin nhắn mỗi lần load (infinite scroll)
  static const int pageSize = 30;
  static const String _table = 'messages';

  /// Channel realtime — giữ reference để unsubscribe khi cần
  RealtimeChannel? _channel;

  /// StreamController broadcast: nhiều listener cùng lắng nghe được
  final _newMessageController = StreamController<ChatMessage>.broadcast();

  ChatRepository(this._client);

  /// Stream tin nhắn mới realtime — ChatCubit subscribe vào đây
  Stream<ChatMessage> get onNewMessage => _newMessageController.stream;

  // ═══════════════════════════════════════════
  // READ — Load tin nhắn cũ (Infinite Scroll)
  // ═══════════════════════════════════════════

  /// Load batch tin nhắn, mới nhất trước.
  ///
  /// [before]: ISO8601 created_at của tin nhắn cũ nhất đang hiển thị
  ///           → load tiếp phần CŨ hơn (scroll lên trên).
  /// Trả về list rỗng = hết tin nhắn (dừng scroll).
  Future<List<ChatMessage>> fetchMessages({
    String? before,
    int limit = pageSize,
  }) async {
    try {
      // Supabase chain: select → FILTERS → order → limit
      var query = _client.from(_table).select();

      // Cursor pagination: chỉ lấy tin nhắn CŨ hơn cursor
      if (before != null) {
        query = query.lt('created_at', before);
      }

      // Transform cuối cùng: sắp xếp + giới hạn
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ChatRepositoryException('Lỗi tải tin nhắn: $e');
    }
  }

  // ═══════════════════════════════════════════
  // CREATE — Gửi tin nhắn
  // ═══════════════════════════════════════════

  /// Gửi tin nhắn vào phòng chat chung.
  /// RLS yêu cầu auth.uid() IS NOT NULL → user phải đăng nhập.
  Future<ChatMessage> sendMessage({
    required String content,
    required String username,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      final response = await _client
          .from(_table)
          .insert({
            'content': content.trim(),
            'username': username,
            if (userId != null) 'user_id': userId,
          })
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      throw ChatRepositoryException('Lỗi gửi tin nhắn: $e');
    }
  }

  // ═══════════════════════════════════════════
  // REALTIME — Lắng nghe tin nhắn mới
  // ═══════════════════════════════════════════

  /// Bật realtime subscription cho bảng messages.
  /// Gọi 1 lần khi vào phòng chat — mỗi INSERT mới sẽ đẩy vào [onNewMessage].
  ///
  /// Tại sao chỉ lắng nghe INSERT (không UPDATE/DELETE):
  /// - Chat chung: tin nhắn gửi rồi không sửa/xóa
  /// - Giảm tải processing cho client
  void subscribeToNewMessages() {
    // Hủy channel cũ nếu đang subscribe (phòng double-subscribe)
    _channel?.unsubscribe();

    _channel = _client
        .channel('public:$_table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: _table,
          callback: (payload) {
            try {
              final message = ChatMessage.fromJson(payload.newRecord);
              _newMessageController.add(message);
            } catch (_) {
              // Bỏ qua message lỗi parse — không crash app vì 1 tin rác
            }
          },
        )
        .subscribe();
  }

  /// Tắt realtime — gọi khi rời phòng chat để tiết kiệm WebSocket connection.
  void unsubscribeFromMessages() {
    _channel?.unsubscribe();
    _channel = null;
  }

  /// Dispose hoàn toàn — gọi khi app tắt.
  void dispose() {
    unsubscribeFromMessages();
    _newMessageController.close();
  }
}

/// Exception riêng cho ChatRepository.
class ChatRepositoryException implements Exception {
  final String message;
  const ChatRepositoryException(this.message);

  @override
  String toString() => 'ChatRepositoryException: $message';
}
