/// EnvConfig: Quản lý tập trung biến môi trường qua flutter_dotenv.
///
/// Tại sao dùng class static thay vì đọc trực tiếp dotenv.get():
/// - Gom tất cả env keys vào 1 nơi duy nhất, tránh typo khi viết string key
/// - IDE autocomplete → giảm lỗi runtime
/// - Crash sớm tại startup nếu thiếu key (fail fast principle)
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  /// Gọi 1 lần trong main() trước khi dùng bất kỳ config nào
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // ── Supabase ──
  static String get supabaseUrl =>
      dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  // ── Backend API ──
  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:8000');

  // ── Telegram Storage ──
  static String get telegramBotToken =>
      dotenv.get('TELEGRAM_BOT_TOKEN', fallback: '');

  static String get telegramChatId =>
      dotenv.get('TELEGRAM_CHAT_ID', fallback: '');

  /// Xác minh tất cả biến bắt buộc đã được cấu hình.
  /// Nếu thiếu → throw StateError ngay tại startup để developer biết sớm.
  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (telegramBotToken.isEmpty) missing.add('TELEGRAM_BOT_TOKEN');
    if (telegramChatId.isEmpty) missing.add('TELEGRAM_CHAT_ID');
    if (apiBaseUrl.isEmpty) missing.add('API_BASE_URL');

    if (missing.isNotEmpty) {
      throw StateError(
        'Thiếu biến môi trường trong .env: ${missing.join(", ")}\n'
        'Hãy copy .env.example → .env và điền giá trị thực.',
      );
    }
  }
}
