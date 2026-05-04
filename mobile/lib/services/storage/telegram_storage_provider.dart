/// TelegramStorageProvider: Dùng Telegram Bot API làm "ổ cứng" miễn phí.
///
/// Chiến lược lưu trữ zero-cost:
///   1. Upload file .opus vào chat riêng (CHAT_ID) → Telegram giữ vĩnh viễn
///   2. Mỗi file có [file_id] duy nhất → lưu vào Supabase audio_metadata
///   3. Khi phát nhạc: getFile API → URL tạm (~1h) → just_audio stream
///
/// Giới hạn Telegram Bot API:
///   - Upload tối đa 50MB per file (Opus 64kbps mono 1h ≈ 28MB → đủ dùng)
///   - Download URL tạm thời (phải gọi getFile lại khi hết hạn)
///   - Không hỗ trợ xóa file đã gửi (chấp nhận — storage Telegram miễn phí)
///   - Rate limit: ~30 requests/giây (đủ cho single user)
library;

import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/config/env_config.dart';
import 'base_storage_service.dart';

class TelegramStorageProvider implements BaseStorageService {
  late final Dio _dio;
  late final String _botToken;
  late final String _chatId;

  /// Base URL cố định của Telegram Bot API
  static const String _telegramApi = 'https://api.telegram.org';

  TelegramStorageProvider() {
    _botToken = EnvConfig.telegramBotToken;
    _chatId = EnvConfig.telegramChatId;

    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      // Upload file lớn (20-40MB Opus) cần timeout dài
      sendTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  /// URL gốc cho Bot API calls: /bot{TOKEN}/method
  String get _apiBase => '$_telegramApi/bot$_botToken';

  /// URL gốc cho file download: /file/bot{TOKEN}/path
  String get _fileBase => '$_telegramApi/file/bot$_botToken';

  // ═══════════════════════════════════════════
  // UPLOAD — POST /sendAudio
  // ═══════════════════════════════════════════

  /// Upload file .opus lên Telegram chat, parse JSON lấy file_id.
  ///
  /// Flow:
  ///   1. Validate kích thước file (< 50MB)
  ///   2. POST multipart/form-data lên /sendAudio
  ///   3. Parse response.result.audio.file_id
  ///   4. Trả về [StorageUploadResult] chứa fileId + sizeBytes
  @override
  Future<StorageUploadResult> uploadAudio({
    required File file,
    required String title,
    String? performer,
  }) async {
    try {
      final fileSize = await file.length();

      // Guard: Telegram giới hạn 50MB cho bot upload
      if (fileSize > 50 * 1024 * 1024) {
        throw TelegramStorageException(
          'File quá lớn (${(fileSize / 1048576).toStringAsFixed(1)} MB). '
          'Telegram Bot API giới hạn 50MB.',
        );
      }

      // Sanitize filename: loại bỏ ký tự đặc biệt, giữ lại chữ/số/dấu gạch
      final safeName = title
          .replaceAll(RegExp(r'[^\w\sàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ-]', caseSensitive: false), '_')
          .trim();

      final formData = FormData.fromMap({
        'chat_id': _chatId,
        'audio': await MultipartFile.fromFile(
          file.path,
          filename: '$safeName.opus',
        ),
        'title': title,
        if (performer != null && performer.isNotEmpty)
          'performer': performer,
        // Tắt notification để không spam chat
        'disable_notification': true,
      });

      final response = await _dio.post(
        '$_apiBase/sendAudio',
        data: formData,
      );

      // Validate response
      if (response.statusCode != 200 || response.data['ok'] != true) {
        throw TelegramStorageException(
          'Upload thất bại: ${response.data['description'] ?? 'Lỗi không xác định'}',
        );
      }

      // Parse file_id từ cấu trúc: { ok: true, result: { audio/voice/document: { file_id, file_size } } }
      final result = response.data['result'] as Map<String, dynamic>;
      final fileData = result['audio'] ?? result['voice'] ?? result['document'] as Map<String, dynamic>?;

      if (fileData == null || fileData['file_id'] == null) {
        throw TelegramStorageException(
          'Telegram response thiếu định dạng file_id hợp lệ (không có audio/voice/document). '
          'Chi tiết: $result',
        );
      }

      return StorageUploadResult(
        fileId: fileData['file_id'] as String,
        sizeBytes: fileData['file_size'] as int? ?? fileSize,
      );
    } on DioException catch (e) {
      throw TelegramStorageException(_parseDioError(e));
    }
  }

  // ═══════════════════════════════════════════
  // STREAM URL — GET /getFile
  // ═══════════════════════════════════════════

  /// Convert file_id → URL stream trực tiếp cho just_audio.
  ///
  /// Flow:
  ///   1. GET /getFile?file_id=xxx → lấy file_path tạm
  ///   2. Ghép URL: https://api.telegram.org/file/bot{TOKEN}/{file_path}
  ///
  /// Lưu ý: URL valid khoảng 1 giờ. Nếu just_audio gặp 403 → cần gọi lại.
  @override
  Future<String> getStreamUrl(String fileId) async {
    try {
      final response = await _dio.get(
        '$_apiBase/getFile',
        queryParameters: {'file_id': fileId},
      );

      if (response.statusCode != 200 || response.data['ok'] != true) {
        throw TelegramStorageException(
          'Không lấy được file path: '
          '${response.data['description'] ?? 'Lỗi không xác định'}',
        );
      }

      final filePath = response.data['result']['file_path'] as String?;
      if (filePath == null) {
        throw TelegramStorageException(
          'Telegram response thiếu file_path cho file_id: $fileId',
        );
      }

      // URL download trực tiếp — just_audio stream được từ URL này
      return '$_fileBase/$filePath';
    } on DioException catch (e) {
      throw TelegramStorageException(_parseDioError(e));
    }
  }

  // ═══════════════════════════════════════════
  // DELETE — Không hỗ trợ
  // ═══════════════════════════════════════════

  @override
  Future<bool> deleteFile(String fileId) async {
    // Telegram Bot API KHÔNG hỗ trợ xóa file đã gửi.
    //
    // Chiến lược chấp nhận:
    // - Chỉ cần xóa metadata ở Supabase → user không thấy trong app nữa
    // - File "mồ côi" trên Telegram tồn tại vĩnh viễn, nhưng cost = 0
    // - Nếu cần xóa thật → dùng deleteMessage API xóa cả message chứa audio
    //   (nhưng cần lưu message_id, phức tạp hơn → TODO nếu cần)
    return false;
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════

  /// Parse DioException thành thông báo tiếng Việt dễ hiểu.
  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Không thể kết nối Telegram. Kiểm tra kết nối mạng.';
    }
    if (e.type == DioExceptionType.sendTimeout) {
      return 'Upload quá chậm, đã timeout. Thử lại với mạng nhanh hơn.';
    }
    if (e.response?.statusCode == 401) {
      return 'Bot token không hợp lệ. Kiểm tra TELEGRAM_BOT_TOKEN trong .env.';
    }
    if (e.response?.statusCode == 400) {
      final desc = e.response?.data?['description'] ?? '';
      return 'Telegram từ chối request: $desc';
    }
    return 'Lỗi mạng Telegram: ${e.message}';
  }
}

/// Exception riêng cho Telegram storage — dễ phân biệt khi debug.
class TelegramStorageException implements Exception {
  final String message;
  const TelegramStorageException(this.message);

  @override
  String toString() => 'TelegramStorageException: $message';
}
