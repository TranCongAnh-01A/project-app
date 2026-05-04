/// AudioListCubit: Quản lý state danh sách audio + search + favorites.
///
/// Tách logic khỏi home_screen.dart (đang 25KB).
/// Controller cho: infinite scroll, search debounce, toggle favorite inline.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/audio_repository.dart';
import 'audio_list_state.dart';

class AudioListCubit extends Cubit<AudioListState> {
  final AudioRepository _audioRepo;

  AudioListCubit({required AudioRepository audioRepo})
      : _audioRepo = audioRepo,
        super(const AudioListInitial());

  /// Load trang đầu tiên (gọi khi mở Home screen)
  Future<void> loadInitial({String? search}) async {
    try {
      emit(const AudioListLoading());

      final tracks = await _audioRepo.fetchPage(search: search);

      emit(AudioListLoaded(
        tracks: tracks,
        hasMore: tracks.length >= AudioRepository.pageSize,
        searchQuery: search,
      ));
    } catch (e) {
      emit(AudioListError('Lỗi tải danh sách: $e'));
    }
  }

  /// Load thêm trang tiếp theo (infinite scroll trigger)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! AudioListLoaded) return;
    if (!currentState.hasMore || currentState.isLoadingMore) return;

    try {
      emit(currentState.copyWithLoadingMore());

      final newTracks = await _audioRepo.fetchPage(
        cursor: currentState.nextCursor,
        search: currentState.searchQuery,
      );

      emit(currentState.appendPage(newTracks));
    } catch (e) {
      // Lỗi load more → giữ data hiện tại, chỉ tắt loading spinner
      emit(AudioListLoaded(
        tracks: currentState.tracks,
        hasMore: currentState.hasMore,
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  /// Tìm kiếm — reload danh sách với keyword mới
  Future<void> search(String query) async {
    final trimmed = query.trim();
    await loadInitial(search: trimmed.isEmpty ? null : trimmed);
  }

  /// Toggle yêu thích inline (không reload toàn bộ list)
  Future<void> toggleFavorite(int index) async {
    final currentState = state;
    if (currentState is! AudioListLoaded) return;
    if (index < 0 || index >= currentState.tracks.length) return;

    try {
      final track = currentState.tracks[index];
      final updated = await _audioRepo.toggleFavorite(
        track.id,
        currentValue: track.isFavorite,
      );

      emit(currentState.updateTrackAt(index, updated));
    } catch (e) {
      // Lỗi toggle → giữ nguyên state (optimistic UI rollback)
    }
  }

  /// Xóa track khỏi danh sách
  Future<void> deleteTrack(String trackId) async {
    final currentState = state;
    if (currentState is! AudioListLoaded) return;

    try {
      await _audioRepo.delete(trackId);
      emit(currentState.removeTrack(trackId));
    } catch (e) {
      // Lỗi xóa → giữ nguyên
    }
  }

  /// Refresh danh sách (pull-to-refresh)
  Future<void> refresh() async {
    final currentState = state;
    final search = currentState is AudioListLoaded
        ? currentState.searchQuery
        : null;
    await loadInitial(search: search);
  }
}
