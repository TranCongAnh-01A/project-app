/// AudioMetadata: Model cho bảng audio_metadata trên Supabase.
///
/// Thay thế AudioTrack model cũ bên Python/SQLAlchemy.
/// Khác biệt chính:
/// - [telegramFileId] thay cho filename local (file giờ nằm trên Telegram)
/// - [userId] gắn với Supabase Auth (RLS per-user)
/// - [isFavorite] boolean trên cùng bảng (thay vì bảng Favorite riêng)
library;

import 'package:equatable/equatable.dart';

class AudioMetadata extends Equatable {
  final String id;
  final String videoId;
  final String title;
  final String channelName;
  final String? thumbnailUrl;
  final String? customName;
  final String telegramFileId;
  final int durationSeconds;
  final int sizeBytes;
  final int originalSizeBytes;
  final double compressionRatio;
  final String? userId;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AudioMetadata({
    required this.id,
    required this.videoId,
    required this.title,
    this.channelName = 'Unknown',
    this.thumbnailUrl,
    this.customName,
    required this.telegramFileId,
    this.durationSeconds = 0,
    this.sizeBytes = 0,
    this.originalSizeBytes = 0,
    this.compressionRatio = 0.0,
    this.userId,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Tên hiển thị: ưu tiên custom_name, fallback về title gốc YouTube
  String get displayName => customName?.isNotEmpty == true ? customName! : title;

  /// Dung lượng nén dạng human-readable (B / KB / MB)
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1048576) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / 1048576).toStringAsFixed(2)} MB';
  }

  /// Tỉ lệ nén dạng "%"
  String get formattedRatio => '${compressionRatio.toStringAsFixed(1)}%';

  /// Thời lượng dạng MM:SS
  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── Serialization ──

  /// Deserialize từ Supabase JSON row
  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      id: json['id'] as String,
      videoId: json['video_id'] as String,
      title: json['title'] as String,
      channelName: json['channel_name'] as String? ?? 'Unknown',
      thumbnailUrl: json['thumbnail_url'] as String?,
      customName: json['custom_name'] as String?,
      telegramFileId: json['telegram_file_id'] as String,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      sizeBytes: json['size_bytes'] as int? ?? 0,
      originalSizeBytes: json['original_size_bytes'] as int? ?? 0,
      compressionRatio:
          (json['compression_ratio'] as num?)?.toDouble() ?? 0.0,
      userId: json['user_id'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Serialize cho Supabase INSERT.
  /// Không gửi [id], [createdAt], [updatedAt] (Supabase auto-gen).
  /// [userId] inject bởi Repository (lấy từ auth session).
  Map<String, dynamic> toInsertJson() {
    return {
      'video_id': videoId,
      'title': title,
      'channel_name': channelName,
      'thumbnail_url': thumbnailUrl,
      'custom_name': customName,
      'telegram_file_id': telegramFileId,
      'duration_seconds': durationSeconds,
      'size_bytes': sizeBytes,
      'original_size_bytes': originalSizeBytes,
      'compression_ratio': compressionRatio,
      'is_favorite': isFavorite,
    };
  }

  /// Copy instance với 1 số field thay đổi (immutable pattern)
  AudioMetadata copyWith({
    String? customName,
    bool? isFavorite,
    String? telegramFileId,
    int? sizeBytes,
    int? originalSizeBytes,
    double? compressionRatio,
    int? durationSeconds,
  }) {
    return AudioMetadata(
      id: id,
      videoId: videoId,
      title: title,
      channelName: channelName,
      thumbnailUrl: thumbnailUrl,
      customName: customName ?? this.customName,
      telegramFileId: telegramFileId ?? this.telegramFileId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      userId: userId,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, videoId, isFavorite, customName, telegramFileId];
}
