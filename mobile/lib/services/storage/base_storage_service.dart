/// BaseStorageService: Contract cho mọi nhà cung cấp lưu trữ file.
///
/// Tại sao dùng abstract class (Dependency Inversion — SOLID chữ D):
/// - Business logic phụ thuộc vào abstraction, không phụ thuộc Telegram cụ thể
/// - Dễ swap: Telegram ↔ S3 ↔ Cloudflare R2 ↔ Local mà không sửa code Cubit
/// - Dễ mock khi viết unit test cho Ingest pipeline
///
/// Flow tổng quát:
/// 1. IngestCubit gọi uploadAudio() → nhận StorageUploadResult (chứa fileId)
/// 2. PlayerCubit gọi getStreamUrl(fileId) → nhận URL tạm → feed cho just_audio
library;

import 'dart:io';

/// Kết quả trả về sau khi upload thành công.
class StorageUploadResult {
  /// ID file trên storage provider (VD: Telegram file_id)
  final String fileId;

  /// URL stream tạm thời (nếu provider trả về ngay sau upload)
  final String? streamUrl;

  /// Dung lượng file đã upload (bytes), dùng lưu vào metadata
  final int sizeBytes;

  const StorageUploadResult({
    required this.fileId,
    this.streamUrl,
    required this.sizeBytes,
  });

  @override
  String toString() =>
      'StorageUploadResult(fileId: $fileId, size: $sizeBytes bytes)';
}

/// Contract cho mọi storage provider.
abstract class BaseStorageService {
  /// Upload file audio lên storage, trả về file ID duy nhất.
  ///
  /// [file]: File .opus đã nén trên thiết bị.
  /// [title]: Tên hiển thị (metadata) kèm theo file.
  /// [performer]: Tên kênh/nghệ sĩ (optional).
  ///
  /// Throws [Exception] nếu upload thất bại.
  Future<StorageUploadResult> uploadAudio({
    required File file,
    required String title,
    String? performer,
  });

  /// Lấy URL stream trực tiếp từ file ID.
  ///
  /// URL có thể tạm thời tùy provider:
  /// - Telegram: valid ~1 giờ, cần gọi lại getStreamUrl khi hết hạn
  /// - S3: configurable presigned URL
  ///
  /// Caller nên cache URL và retry nếu bị 403/410.
  Future<String> getStreamUrl(String fileId);

  /// Xóa file khỏi storage (nếu provider hỗ trợ).
  /// Trả về true nếu xóa thành công, false nếu không hỗ trợ.
  Future<bool> deleteFile(String fileId);
}
