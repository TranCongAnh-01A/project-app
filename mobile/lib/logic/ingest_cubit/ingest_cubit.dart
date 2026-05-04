/// IngestCubit: Điều phối quá trình ingest video qua Server API.
///
/// Pipeline (Server-side):
///   1. fetchMetadata(url) → preview cho user, kiểm tra trùng lặp
///   2. startPipeline()    → gửi yêu cầu cho Backend chạy yt-dlp + FFmpeg
///   3. Lấy dữ liệu mới    → tìm lại trong Supabase sau khi xử lý xong
library;

import 'package:flutter_bloc/flutter_bloc.dart';


import '../../data/repositories/audio_repository.dart';
import '../../services/supabase_service.dart';
import '../../services/youtube_service.dart';
import 'ingest_state.dart';

class IngestCubit extends Cubit<IngestState> {
  final YouTubeService _youtubeService;
  final AudioRepository _audioRepo;

  IngestCubit({
    required YouTubeService youtubeService,
    required AudioRepository audioRepo,
  })  : _youtubeService = youtubeService,
        _audioRepo = audioRepo,
        super(const IngestInitial());

  /// Bước 1: Lấy metadata video để preview
  Future<void> fetchMetadata(String url) async {
    try {
      emit(const IngestFetchingMetadata());

      final metadata = await _youtubeService.fetchMetadata(url);

      // Kiểm tra video đã tồn tại trong DB chưa (tránh nén lại)
      final existing = await _audioRepo.findByVideoId(metadata.videoId);
      if (existing != null) {
        emit(IngestError(
          message: 'Audio "${existing.displayName}" đã tồn tại trong thư viện.',
        ));
        return;
      }

      emit(IngestMetadataReady(metadata));
    } catch (e) {
      emit(IngestError(message: e.toString()));
    }
  }

  /// Bước 2: Bắt đầu gửi lệnh nén cho Server
  ///
  /// Gọi [processOnServer] truyền [url] và [userId].
  /// Server sẽ chịu trách nhiệm: tải, nén, đẩy lên Telegram và lưu db.
  Future<void> startPipeline({String? customName}) async {
    final currentState = state;
    if (currentState is! IngestMetadataReady) return;

    final metadata = currentState.metadata;

    try {
      // ── Báo cho UI là đang xử lý ──
      // Do không chia ra nhiều state nữa (tùy thuộc backend),
      // gom chung vào "Processing" (sửa dụng trạng thái Downloading báo fake progress 
      // để UI không bị vỡ do expect Downloading / Compressing).
      emit(IngestDownloading(metadata: metadata, progress: 0));

      final userId = SupabaseService().currentUser?.id;
      if (userId == null) {
        throw Exception('Chưa đăng nhập! Vui lòng đăng nhập lại.');
      }

      await _youtubeService.processOnServer(
        'https://youtube.com/watch?v=${metadata.videoId}',
        userId,
      );

      // ── Server đã lưu vào DB xong, fetch local DB lại ──
      emit(IngestSaving(metadata: metadata));
      
      final track = await _audioRepo.findByVideoId(metadata.videoId);
      if (track == null) {
        throw Exception('Server báo hoàn thành nhưng không tìm thấy file trong DB.');
      }

      emit(IngestSuccess(track));
    } catch (e) {
      emit(IngestError(message: e.toString(), previousState: state));
    }
  }

  /// Reset về trạng thái ban đầu (nhập URL mới)
  void reset() => emit(const IngestInitial());

  @override
  Future<void> close() {
    _youtubeService.dispose();
    return super.close();
  }
}
