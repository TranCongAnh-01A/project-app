/// PlayerCubit: Quản lý state Audio Player + tương tác just_audio.
///
/// Tách logic player khỏi UI screens. Cubit lắng nghe just_audio streams
/// (position, duration, playerState) và emit PlayerState tương ứng.
///
/// Tại sao cần getStreamUrl mỗi lần play:
/// - Telegram getFile trả về URL tạm (~1 giờ validity)
/// - Nếu URL hết hạn giữa chừng → catch lỗi, gọi lại getStreamUrl → retry
library;

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;

import '../../data/models/audio_metadata.dart';
import '../../services/storage/telegram_storage_provider.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayer _audioPlayer;
  final TelegramStorageProvider _storage;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  /// Track hiện tại (giữ reference để retry)
  AudioMetadata? _currentTrack;
  String? _currentStreamUrl;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;

  PlayerCubit({
    required AudioPlayer audioPlayer,
    required TelegramStorageProvider storage,
  })  : _audioPlayer = audioPlayer,
        _storage = storage,
        super(const PlayerIdle()) {
    _listenToAudioStreams();
  }

  /// Lắng nghe position/duration streams từ just_audio
  void _listenToAudioStreams() {
    // Position stream: cập nhật thanh progress mỗi giây
    _positionSub = _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _emitCurrentPlayState();
    });

    // Duration stream: cập nhật khi track load xong
    _durationSub = _audioPlayer.durationStream.listen((duration) {
      _currentDuration = duration ?? Duration.zero;
      _emitCurrentPlayState();
    });

    // Player state: detect khi track kết thúc
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        // Track kết thúc → pause tại cuối (không auto-next vì chưa có queue)
        if (_currentTrack != null && _currentStreamUrl != null) {
          emit(PlayerPaused(
            track: _currentTrack!,
            position: _currentDuration,
            duration: _currentDuration,
            streamUrl: _currentStreamUrl!,
          ));
        }
      }
    });
  }

  /// Emit state hiện tại dựa trên playing/paused
  void _emitCurrentPlayState() {
    if (_currentTrack == null || _currentStreamUrl == null) return;

    if (_audioPlayer.playing) {
      emit(PlayerPlaying(
        track: _currentTrack!,
        position: _currentPosition,
        duration: _currentDuration,
        streamUrl: _currentStreamUrl!,
      ));
    } else if (state is PlayerPlaying || state is PlayerPaused) {
      emit(PlayerPaused(
        track: _currentTrack!,
        position: _currentPosition,
        duration: _currentDuration,
        streamUrl: _currentStreamUrl!,
      ));
    }
  }

  /// Phát track mới (hoặc replay track hiện tại)
  Future<void> play(AudioMetadata track) async {
    try {
      // Nếu đang phát cùng track → chỉ resume
      if (_currentTrack?.id == track.id && state is PlayerPaused) {
        await _audioPlayer.play();
        return;
      }

      emit(PlayerLoadingTrack(track));
      _currentTrack = track;

      // Lấy URL stream từ Telegram (URL tạm ~1h)
      _currentStreamUrl = await _storage.getStreamUrl(track.telegramFileId);

      // Set source và phát
      await _audioPlayer.setUrl(_currentStreamUrl!);
      await _audioPlayer.play();
    } catch (e) {
      emit(PlayerError(message: 'Lỗi phát nhạc: $e', track: track));
    }
  }

  /// Pause
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Resume (toggle play/pause)
  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else if (_currentTrack != null) {
      await _audioPlayer.play();
    }
  }

  /// Seek tới vị trí cụ thể
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Seek tương đối (± giây)
  Future<void> seekRelative(int seconds) async {
    final newPosition = _currentPosition + Duration(seconds: seconds);
    final clamped = newPosition.isNegative ? Duration.zero : newPosition;
    await _audioPlayer.seek(
      clamped > _currentDuration ? _currentDuration : clamped,
    );
  }

  /// Dừng hoàn toàn
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrack = null;
    _currentStreamUrl = null;
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
    emit(const PlayerIdle());
  }

  /// Retry phát lại track bị lỗi (lấy URL mới từ Telegram)
  Future<void> retry() async {
    final track = _currentTrack ?? (state is PlayerError ? (state as PlayerError).track : null);
    if (track != null) {
      await play(track);
    }
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
