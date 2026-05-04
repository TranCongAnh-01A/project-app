/// MiniPlayer: Widget player nhỏ — dùng PlayerCubit thay AudioPlayerService.
/// Glassmorphic floating card góc dưới phải.
///
/// Tương tác:
/// - Tap nút tròn  → Play/Pause
/// - Tap vùng ngoài → (future: mở FullPlayer)
/// - Double Tap    → Play/Pause
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../logic/player_cubit/player_cubit.dart';
import '../../logic/player_cubit/player_state.dart';
import '../../main.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        // Ẩn khi chưa có track
        if (state is PlayerIdle) return const SizedBox.shrink();

        // Lấy thông tin track từ bất kỳ state nào
        final track = _getTrack(state);
        final isPlaying = state is PlayerPlaying;
        final isLoading = state is PlayerLoadingTrack;

        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          onDoubleTap: () => context.read<PlayerCubit>().togglePlayPause(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 14, bottom: 20),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midPurple.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Thumbnail nhỏ bo tròn
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: track.thumbnailUrl != null &&
                                track.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _miniThumb(),
                              )
                            : _miniThumb(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Title + channel
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkText
                                  : const Color(0xFF2D2D2D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.channelName,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Play/Pause button
                    GestureDetector(
                      onTap: () =>
                          context.read<PlayerCubit>().togglePlayPause(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.midPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.midPurple.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
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

  /// Lấy track từ bất kỳ state nào có chứa track
  _getTrack(PlayerState state) {
    if (state is PlayerPlaying) return state.track;
    if (state is PlayerPaused) return state.track;
    if (state is PlayerLoadingTrack) return state.track;
    if (state is PlayerError) return state.track;
    return null;
  }

  Widget _miniThumb() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.cardGradient),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 18),
    );
  }
}
