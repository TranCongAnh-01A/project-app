/// ChatMessage: Model cho bảng messages trên Supabase.
///
/// Phòng chat chung (global room) — mọi user cùng đọc/gửi realtime.
/// RLS policy: ai cũng đọc được, chỉ user đăng nhập mới gửi được.
library;

import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String? userId;
  final String username;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  /// Kiểm tra tin nhắn có phải của user hiện tại không (để phân biệt "bong bóng" trái/phải)
  bool isOwnMessage(String? currentUserId) =>
      userId != null && userId == currentUserId;

  /// Thời gian hiển thị ngắn gọn (HH:mm)
  String get formattedTime {
    final h = createdAt.toLocal().hour.toString().padLeft(2, '0');
    final m = createdAt.toLocal().minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Serialization ──

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      username: json['username'] as String? ?? 'Anonymous',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Serialize cho INSERT — không gửi id, created_at (server auto-gen).
  /// user_id inject bởi ChatRepository.
  Map<String, dynamic> toInsertJson() {
    return {
      'content': content,
      'username': username,
    };
  }

  @override
  List<Object?> get props => [id, userId, content, createdAt];
}
