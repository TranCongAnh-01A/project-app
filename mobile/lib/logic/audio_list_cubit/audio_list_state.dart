/// AudioListState: Trạng thái danh sách audio trên Home screen.
///
/// Hỗ trợ:
/// - Load trang đầu + infinite scroll load more
/// - Search filter
/// - Toggle yêu thích inline (không reload toàn bộ list)
library;

import 'package:equatable/equatable.dart';

import '../../data/models/audio_metadata.dart';

sealed class AudioListState extends Equatable {
  const AudioListState();

  @override
  List<Object?> get props => [];
}

/// Chưa load lần nào
class AudioListInitial extends AudioListState {
  const AudioListInitial();
}

/// Đang load trang đầu tiên
class AudioListLoading extends AudioListState {
  const AudioListLoading();
}

/// Đã load xong — chứa dữ liệu cho UI
class AudioListLoaded extends AudioListState {
  /// Danh sách tracks hiện tại (tích lũy qua các trang)
  final List<AudioMetadata> tracks;

  /// Còn data để load thêm không (false = hết → dừng infinite scroll)
  final bool hasMore;

  /// Search keyword hiện tại (null = không filter)
  final String? searchQuery;

  /// Đang load thêm trang tiếp (hiển thị spinner ở cuối list)
  final bool isLoadingMore;

  const AudioListLoaded({
    required this.tracks,
    this.hasMore = true,
    this.searchQuery,
    this.isLoadingMore = false,
  });

  /// Cursor cho trang tiếp = created_at của item cuối cùng
  String? get nextCursor =>
      tracks.isNotEmpty ? tracks.last.createdAt.toIso8601String() : null;

  /// Copy với trạng thái loading more
  AudioListLoaded copyWithLoadingMore() => AudioListLoaded(
        tracks: tracks,
        hasMore: hasMore,
        searchQuery: searchQuery,
        isLoadingMore: true,
      );

  /// Append thêm tracks từ trang mới
  AudioListLoaded appendPage(List<AudioMetadata> newTracks) => AudioListLoaded(
        tracks: [...tracks, ...newTracks],
        hasMore: newTracks.length >= 20,
        searchQuery: searchQuery,
        isLoadingMore: false,
      );

  /// Cập nhật 1 track tại vị trí cụ thể (toggle favorite, rename)
  AudioListLoaded updateTrackAt(int index, AudioMetadata updated) {
    final newList = List<AudioMetadata>.from(tracks);
    newList[index] = updated;
    return AudioListLoaded(
      tracks: newList,
      hasMore: hasMore,
      searchQuery: searchQuery,
    );
  }

  /// Xóa track khỏi danh sách
  AudioListLoaded removeTrack(String trackId) => AudioListLoaded(
        tracks: tracks.where((t) => t.id != trackId).toList(),
        hasMore: hasMore,
        searchQuery: searchQuery,
      );

  @override
  List<Object?> get props => [tracks.length, hasMore, searchQuery, isLoadingMore];
}

/// Lỗi khi load danh sách
class AudioListError extends AudioListState {
  final String message;

  const AudioListError(this.message);

  @override
  List<Object?> get props => [message];
}
