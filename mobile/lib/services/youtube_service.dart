/// YouTubeService: Chuyển toàn bộ tải & nén âm thanh lên Server (v0.3 pivot).
///
/// Thay vì tải file về thiết bị (bị YouTube chống bot), app sẽ gọi API
/// của backend xử lý mọi thứ một cách ổn định, sau đó nhận metadata
/// trả về khi hệ thống xử lý xong.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config/env_config.dart';

/// Metadata video YouTube — preview trước khi tải.
class VideoMetadata {
  final String videoId;
  final String title;
  final String channelName;
  final String? thumbnailUrl;
  final Duration duration;

  const VideoMetadata({
    required this.videoId,
    required this.title,
    required this.channelName,
    this.thumbnailUrl,
    required this.duration,
  });
}

class YouTubeService {
  /// HTTP client — dùng EnvConfig để lấy base URL thống nhất với toàn app.
  /// receiveTimeout dài vì pipeline nén video server-side có thể mất vài phút.
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: const Duration(minutes: 1),
    receiveTimeout: const Duration(minutes: 10),
  ));

  /// 1) Lấy metadata video từ Server API
  Future<VideoMetadata> fetchMetadata(String url) async {
    try {
      final response = await _dio.get(
        '/api/v1/ingest/metadata',
        queryParameters: {'url': url},
      );

      final data = response.data;
      return VideoMetadata(
        videoId: data['video_id'],
        title: data['title'],
        channelName: data['channel_name'],
        thumbnailUrl: data['thumbnail_url'],
        duration: Duration(seconds: data['duration_seconds'] ?? 0),
      );
    } catch (e) {
      debugPrint('[YouTubeService] fetchMetadata failed: $e');
      if (e is DioException && e.response != null) {
        throw YouTubeServiceException(e.response?.data['detail'] ??
            'Lỗi server (${e.response?.statusCode})');
      }
      throw YouTubeServiceException('Không thể lấy metadata video: $e');
    }
  }

  /// 2) Gửi yêu cầu Nén Video Server-side
  /// Không trả về file, chỉ báo thành công để Cubit tải DB
  Future<void> processOnServer(String url, String userId) async {
    try {
      final response = await _dio.post(
        '/api/v1/ingest/youtube-v2',
        data: {
          'youtube_url': url,
          'user_id': userId,
        },
      );

      if (response.statusCode != 200) {
        throw YouTubeServiceException('Lỗi hệ thống: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[YouTubeService] processOnServer failed: $e');
      if (e is DioException && e.response != null) {
        throw YouTubeServiceException(e.response?.data['detail'] ??
            'Lỗi server (${e.response?.statusCode})');
      }
      throw YouTubeServiceException('Quá trình nén thất bại: $e');
    }
  }

  void dispose() {
    _dio.close();
  }
}

class YouTubeServiceException implements Exception {
  final String message;
  const YouTubeServiceException(this.message);

  @override
  String toString() => 'YouTubeServiceException: $message';
}
