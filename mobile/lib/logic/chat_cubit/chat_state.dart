/// ChatState: Trạng thái phòng chat chung.
///
/// Kiến trúc 2 nguồn dữ liệu:
/// - [messages]: Tích lũy từ fetchMessages (pagination) + onNewMessage (realtime)
/// - ChatCubit merge 2 nguồn vào 1 list duy nhất, sắp mới nhất cuối
library;

import 'package:equatable/equatable.dart';

import '../../data/models/chat_message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Chưa mở chat
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Đang load tin nhắn lần đầu
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Đã load xong — UI hiển thị danh sách tin nhắn
class ChatLoaded extends ChatState {
  /// Tin nhắn sắp xếp cũ → mới (item cuối = tin mới nhất, hiển thị ở dưới)
  final List<ChatMessage> messages;

  /// Còn tin nhắn cũ để load thêm (scroll lên trên)
  final bool hasMore;

  /// Đang load thêm tin cũ (spinner ở trên cùng)
  final bool isLoadingMore;

  /// Đang gửi tin nhắn (disable nút gửi)
  final bool isSending;

  const ChatLoaded({
    required this.messages,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isSending = false,
  });

  /// Cursor cho trang cũ hơn = created_at của tin nhắn cũ nhất (item đầu tiên)
  String? get oldestCursor =>
      messages.isNotEmpty ? messages.first.createdAt.toIso8601String() : null;

  /// Thêm tin nhắn mới vào cuối list (từ realtime)
  ChatLoaded addNewMessage(ChatMessage message) => ChatLoaded(
        messages: [...messages, message],
        hasMore: hasMore,
      );

  /// Prepend tin cũ vào đầu list (từ pagination)
  ChatLoaded prependOlderMessages(List<ChatMessage> older) => ChatLoaded(
        // older trả về mới nhất trước → reverse để cũ nhất ở đầu
        messages: [...older.reversed, ...messages],
        hasMore: older.length >= 30,
        isLoadingMore: false,
      );

  /// Toggle trạng thái sending
  ChatLoaded copyWithSending(bool sending) => ChatLoaded(
        messages: messages,
        hasMore: hasMore,
        isSending: sending,
      );

  /// Toggle trạng thái loading more
  ChatLoaded copyWithLoadingMore() => ChatLoaded(
        messages: messages,
        hasMore: hasMore,
        isLoadingMore: true,
      );

  @override
  List<Object?> get props => [messages.length, hasMore, isLoadingMore, isSending];
}

/// Lỗi chat
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
