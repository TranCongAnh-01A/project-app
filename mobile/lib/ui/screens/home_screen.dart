/// HomeScreen: Trang chủ — dùng AudioListCubit + PlayerCubit thay ApiService.
///
/// Giữ nguyên design: header, search bar, highlight cards, list tiles, empty state.
/// Logic đã tách hết vào Cubits → screen chỉ lo render UI.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/audio_metadata.dart';
import '../../logic/audio_list_cubit/audio_list_cubit.dart';
import '../../logic/audio_list_cubit/audio_list_state.dart';
import '../../logic/player_cubit/player_cubit.dart';
import '../../logic/player_cubit/player_state.dart';
import '../../main.dart';
import '../../services/theme_notifier.dart';
import '../widgets/mini_player.dart';
import 'chat_screen.dart';
import 'ingest_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _themeNotifier = ThemeNotifier();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<AudioListCubit>().search(query);
    });
  }

  void _openIngest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IngestScreen()),
    );
    // Refresh danh sách sau khi ingest xong
    if (mounted) {
      context.read<AudioListCubit>().refresh();
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.paleBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: BlocBuilder<AudioListCubit, AudioListState>(
              builder: (context, state) {
                if (state is AudioListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AudioListError) {
                  return _buildError(isDark, state.message);
                }
                if (state is AudioListLoaded) {
                  return _buildContent(isDark, state);
                }
                // AudioListInitial → trigger load
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          // Mini Player cố định ở dưới
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, AudioListLoaded state) {
    final textColor = isDark ? AppColors.darkText : const Color(0xFF2D2D2D);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardTracks = state.tracks.take(4).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<AudioListCubit>().refresh(),
      color: AppColors.midPurple,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Infinite scroll: load thêm khi gần đến cuối
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
            context.read<AudioListCubit>().loadMore();
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Header ──
            _buildHeader(isDark, textColor),
            const SizedBox(height: 12),

            // ── Search Bar ──
            _buildSearchBar(isDark, subColor),
            const SizedBox(height: 20),

            // ── Highlight Cards (Horizontal) ──
            if (cardTracks.isNotEmpty) ...[
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20),
                  itemCount: cardTracks.length,
                  itemBuilder: (context, index) =>
                      _buildBoxCard(cardTracks[index]),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── All Songs (List Tiles) ──
            if (state.tracks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Text(
                  'All songs (${state.tracks.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
              ...state.tracks.asMap().entries.map((entry) =>
                  _buildListTile(entry.value, entry.key)),
            ],

            // Loading more spinner
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Empty state
            if (state.tracks.isEmpty) _buildEmpty(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Listen now',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
          // 🌙/☀ Theme toggle
          _headerButton(
            icon: isDark ? Icons.light_mode : Icons.dark_mode,
            onTap: () => _themeNotifier.toggle(),
            tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
          ),
          // + Nén audio
          _headerButton(
            icon: Icons.add,
            onTap: _openIngest,
            tooltip: 'Nén Audio',
          ),
          // 💬 Chat
          _headerButton(
            icon: Icons.chat_bubble_outline,
            onTap: _openChat,
            tooltip: 'Phòng Chat',
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.midPurple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.midPurple, size: 20),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppColors.midPurple.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            hintStyle: TextStyle(color: subColor, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: subColor, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: subColor, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      context.read<AudioListCubit>().search('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxCard(AudioMetadata track) {


    return GestureDetector(
      onTap: () => context.read<PlayerCubit>().play(track),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.cardGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.midPurple.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Thumbnail
            if (track.thumbnailUrl != null && track.thumbnailUrl!.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    track.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            // Overlay gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Text info
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.channelName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  track.formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(AudioMetadata track, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : const Color(0xFF2D2D2D);

    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        // Check xem track này đang phát hay không
        final isActive = _isTrackActive(playerState, track);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Material(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.read<PlayerCubit>().play(track),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Thumbnail nhỏ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: track.thumbnailUrl != null
                            ? Image.network(
                                track.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.music_note,
                                  color: Colors.white70,
                                ),
                              )
                            : const Icon(
                                Icons.music_note,
                                color: Colors.white70,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + channel
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isActive
                                  ? AppColors.midPurple
                                  : textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${track.channelName} · ${track.formattedDuration}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),

                    // Nút yêu thích
                    IconButton(
                      onPressed: () =>
                          context.read<AudioListCubit>().toggleFavorite(index),
                      icon: Icon(
                        track.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: track.isFavorite
                            ? Colors.redAccent
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),

                    // Playing indicator hoặc more menu
                    if (isActive)
                      const Icon(Icons.equalizer, color: AppColors.midPurple, size: 20)
                    else
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDelete(track);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Xóa'),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isTrackActive(PlayerState playerState, AudioMetadata track) {
    if (playerState is PlayerPlaying) return playerState.track.id == track.id;
    if (playerState is PlayerPaused) return playerState.track.id == track.id;
    if (playerState is PlayerLoadingTrack) return playerState.track.id == track.id;
    return false;
  }

  void _confirmDelete(AudioMetadata track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa "${track.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.midPurple),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AudioListCubit>().deleteTrack(track.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa')),
      );
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.midPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.library_music_outlined,
                size: 56,
                color: AppColors.midPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Không tìm thấy kết quả'
                  : 'Thư viện trống',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Thử từ khóa khác'
                  : 'Nhấn + để thêm audio đầu tiên',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openIngest,
                icon: const Icon(Icons.add),
                label: const Text('Nén Audio'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midPurple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, String error) {
    final textColor = isDark ? AppColors.darkText : const Color(0xFF2D2D2D);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Không thể kết nối',
            style: TextStyle(fontSize: 16, color: textColor),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => context.read<AudioListCubit>().refresh(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
