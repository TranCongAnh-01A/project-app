/// ChatCubit: Quản lý state phòng chat chung.
///
/// Merge 2 nguồn dữ liệu:
/// 1. fetchMessages() — load batch tin cũ (cursor pagination)
/// 2. onNewMessage stream — tin nhắn mới realtime (Supabase Realtime)
///
/// Lifecycle:
///   enterChat() → subscribe realtime + load initial
///   loadOlderMessages() → infinite scroll lên trên
///   sendMessage() → gửi tin → Supabase → realtime broadcast về
///   leaveChat() → unsubscribe tiết kiệm connection
library;

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepo;
  String _currentUsername;

  StreamSubscription<ChatMessage>? _realtimeSub;

  ChatCubit({
    required ChatRepository chatRepo,
    required String currentUsername,
  })  : _chatRepo = chatRepo,
        _currentUsername = currentUsername,
        super(const ChatInitial());

  /// Cập nhật username (gọi sau khi auth thành công)
  void updateUsername(String username) {
    _currentUsername = username;
  }

  /// Vào phòng chat: subscribe realtime + load tin nhắn gần nhất.
  Future<void> enterChat() async {
    try {
      emit(const ChatLoading());

      // 1. Load batch tin nhắn mới nhất
      final messages = await _chatRepo.fetchMessages();

      // 2. Bật realtime subscription
      _chatRepo.subscribeToNewMessages();

      // 3. Lắng nghe tin mới từ realtime
      _realtimeSub = _chatRepo.onNewMessage.listen(_onRealtimeMessage);

      // messages trả về mới nhất trước → reverse để cũ nhất ở đầu list
      emit(ChatLoaded(
        messages: messages.reversed.toList(),
        hasMore: messages.length >= ChatRepository.pageSize,
      ));
    } catch (e) {
      emit(ChatError('Lỗi mở phòng chat: $e'));
    }
  }

  /// Xử lý tin nhắn realtime mới
  void _onRealtimeMessage(ChatMessage message) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      // Kiểm tra trùng lặp (tin mình gửi có thể đã được thêm trước đó)
      final alreadyExists = currentState.messages.any((m) => m.id == message.id);
      if (!alreadyExists) {
        emit(currentState.addNewMessage(message));
      }
    }
  }

  /// Load thêm tin nhắn cũ (infinite scroll lên trên)
  Future<void> loadOlderMessages() async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    try {
      emit(currentState.copyWithLoadingMore());

      final older = await _chatRepo.fetchMessages(
        before: currentState.oldestCursor,
      );

      emit(currentState.prependOlderMessages(older));
    } catch (_) {
      // Lỗi load more → giữ data hiện tại, tắt spinner
      emit(ChatLoaded(
        messages: currentState.messages,
        hasMore: currentState.hasMore,
      ));
    }
  }

  /// Gửi tin nhắn mới
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final currentState = state;
    if (currentState is! ChatLoaded) return;

    try {
      emit(currentState.copyWithSending(true));

      await _chatRepo.sendMessage(
        content: content,
        username: _currentUsername,
      );

      // Không cần add message vào list ở đây
      // → Supabase Realtime sẽ broadcast INSERT event
      // → _onRealtimeMessage sẽ nhận và add vào list
      emit(currentState.copyWithSending(false));
    } catch (e) {
      emit(currentState.copyWithSending(false));
      // Có thể emit error toast ở đây nếu cần
    }
  }

  /// Rời phòng chat: hủy subscription tiết kiệm WebSocket
  void leaveChat() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    _chatRepo.unsubscribeFromMessages();
  }

  @override
  Future<void> close() {
    leaveChat();
    return super.close();
  }
}
