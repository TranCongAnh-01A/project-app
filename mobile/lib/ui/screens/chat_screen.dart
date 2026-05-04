/// ChatScreen: Phòng chat chung realtime.
///
/// Dùng ChatCubit để:
/// - enterChat(): subscribe realtime + load tin nhắn gần nhất
/// - loadOlderMessages(): scroll lên load thêm tin cũ
/// - sendMessage(): gửi tin → Supabase → broadcast qua Realtime
/// - leaveChat(): hủy subscription
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/chat_message.dart';
import '../../logic/chat_cubit/chat_cubit.dart';
import '../../logic/chat_cubit/chat_state.dart';
import '../../main.dart';
import '../../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Vào phòng chat: subscribe realtime + load tin nhắn
    context.read<ChatCubit>().enterChat();

    // Infinite scroll: load tin cũ khi scroll lên đầu
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Rời phòng chat: hủy subscription tiết kiệm connection
    context.read<ChatCubit>().leaveChat();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 50) {
      context.read<ChatCubit>().loadOlderMessages();
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatCubit>().sendMessage(content);
    _messageController.clear();

    // Scroll xuống tin nhắn mới
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.paleBackground;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Phòng Chat',
          style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // ── Danh sách tin nhắn ──
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                // Auto-scroll khi có tin mới (nếu đang ở gần cuối)
                if (state is ChatLoaded && _scrollController.hasClients) {
                  final maxScroll =
                      _scrollController.position.maxScrollExtent;
                  final currentScroll = _scrollController.position.pixels;
                  if (maxScroll - currentScroll < 150) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent + 60,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(state.message,
                            style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () =>
                              context.read<ChatCubit>().enterChat(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ChatLoaded) {
                  return _buildMessageList(state, isDark);
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // ── Thanh nhập tin nhắn ──
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatLoaded state, bool isDark) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Chưa có tin nhắn',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy gửi tin nhắn đầu tiên!',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading spinner ở đầu (load tin cũ)
        if (state.isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
                child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
          );
        }

        final msgIndex = state.isLoadingMore ? index - 1 : index;
        final message = state.messages[msgIndex];
        final isOwn = message.isOwnMessage(
          SupabaseService().client.auth.currentUser?.id,
        );

        return _buildMessageBubble(message, isOwn, isDark);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isOwn, bool isDark) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isOwn
              ? AppColors.midPurple
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Username (chỉ hiện cho tin người khác)
            if (!isOwn)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.username,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.midPurple.withValues(alpha: 0.8),
                  ),
                ),
              ),
            // Nội dung
            Text(
              message.content,
              style: TextStyle(
                color: isOwn
                    ? Colors.white
                    : (isDark ? AppColors.darkText : const Color(0xFF2D2D2D)),
                fontSize: 14,
              ),
            ),
            // Thời gian
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message.formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: isOwn
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurface
                    : AppColors.paleBackground,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final isSending =
                  state is ChatLoaded && state.isSending;
              return IconButton(
                onPressed: isSending ? null : _sendMessage,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.midPurple,
                    shape: BoxShape.circle,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

