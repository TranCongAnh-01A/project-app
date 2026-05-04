/// PlayerState: Trạng thái Audio Player.
///
/// Quản lý track đang phát, vị trí, duration, trạng thái play/pause.
/// Tách khỏi UI (home_screen.dart đang nhồi state 25KB) → giờ Cubit quản lý.
library;

import 'package:equatable/equatable.dart';

import '../../data/models/audio_metadata.dart';

sealed class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

/// Chưa chọn bài nào
class PlayerIdle extends PlayerState {
  const PlayerIdle();
}

/// Đang load stream URL từ Telegram (getFile API)
class PlayerLoadingTrack extends PlayerState {
  final AudioMetadata track;

  const PlayerLoadingTrack(this.track);

  @override
  List<Object?> get props => [track.id];
}

/// Đang phát nhạc
class PlayerPlaying extends PlayerState {
  final AudioMetadata track;
  final Duration position;
  final Duration duration;

  /// URL stream hiện tại (từ Telegram getFile)
  final String streamUrl;

  const PlayerPlaying({
    required this.track,
    required this.position,
    required this.duration,
    required this.streamUrl,
  });

  /// Tiến trình phát 0.0 → 1.0
  double get progress =>
      duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0;

  /// Thời gian còn lại
  Duration get remaining => duration - position;

  @override
  List<Object?> get props => [track.id, position, duration];
}

/// Đang tạm dừng
class PlayerPaused extends PlayerState {
  final AudioMetadata track;
  final Duration position;
  final Duration duration;
  final String streamUrl;

  const PlayerPaused({
    required this.track,
    required this.position,
    required this.duration,
    required this.streamUrl,
  });

  double get progress =>
      duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0;

  @override
  List<Object?> get props => [track.id, position, duration];
}

/// Lỗi player (URL hết hạn, mạng lỗi, codec lỗi)
class PlayerError extends PlayerState {
  final String message;

  /// Track bị lỗi (để retry)
  final AudioMetadata? track;

  const PlayerError({required this.message, this.track});

  @override
  List<Object?> get props => [message];
}
