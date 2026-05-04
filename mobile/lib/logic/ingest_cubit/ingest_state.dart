/// IngestState: Các trạng thái của pipeline tải + nén + upload audio.
///
/// Mỗi trạng thái tương ứng 1 bước trong pipeline:
///   Initial → FetchingMetadata → MetadataReady → Downloading →
///   Compressing → Uploading → Saving → Success
///
/// Tại sao dùng sealed class:
/// - Dart 3 exhaustive pattern matching → compiler báo lỗi nếu thiếu case
/// - Mỗi state mang đúng data cần cho bước đó (không thừa, không thiếu)
library;

import 'package:equatable/equatable.dart';

import '../../data/models/audio_metadata.dart';
import '../../services/youtube_service.dart';

sealed class IngestState extends Equatable {
  const IngestState();

  @override
  List<Object?> get props => [];
}

/// Chưa bắt đầu — màn hình nhập URL
class IngestInitial extends IngestState {
  const IngestInitial();
}

/// Đang lấy thông tin video từ YouTube
class IngestFetchingMetadata extends IngestState {
  const IngestFetchingMetadata();
}

/// Đã lấy xong metadata — hiển thị preview, chờ user xác nhận tải
class IngestMetadataReady extends IngestState {
  final VideoMetadata metadata;

  const IngestMetadataReady(this.metadata);

  @override
  List<Object?> get props => [metadata.videoId];
}

/// Đang tải audio-only stream từ YouTube
class IngestDownloading extends IngestState {
  final VideoMetadata metadata;

  /// Tiến trình 0.0 → 1.0
  final double progress;

  const IngestDownloading({required this.metadata, required this.progress});

  @override
  List<Object?> get props => [metadata.videoId, progress];
}



/// Đang lưu metadata vào Supabase
class IngestSaving extends IngestState {
  final VideoMetadata metadata;

  const IngestSaving({required this.metadata});

  @override
  List<Object?> get props => [metadata.videoId];
}

/// Pipeline hoàn tất — hiển thị kết quả
class IngestSuccess extends IngestState {
  final AudioMetadata track;

  const IngestSuccess(this.track);

  @override
  List<Object?> get props => [track.id];
}

/// Lỗi ở bất kỳ bước nào
class IngestError extends IngestState {
  final String message;

  /// State trước khi lỗi (để biết lỗi ở bước nào)
  final IngestState? previousState;

  const IngestError({required this.message, this.previousState});

  @override
  List<Object?> get props => [message];
}
