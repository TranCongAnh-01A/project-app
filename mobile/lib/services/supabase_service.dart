/// SupabaseService: Singleton quản lý kết nối Supabase.
///
/// Thay thế hoàn toàn ApiService (đang gọi localhost:8000).
///
/// Tại sao singleton:
/// - Supabase SDK cần khởi tạo 1 lần duy nhất (gọi Supabase.initialize)
/// - Consistency với pattern AudioPlayerService / ThemeNotifier hiện có
/// - Client instance dùng chung cho tất cả Repository
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;

  /// Khởi tạo Supabase — gọi 1 lần duy nhất trong main()
  Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
    _initialized = true;
  }

  /// Client singleton từ Supabase SDK
  SupabaseClient get client => Supabase.instance.client;

  /// User hiện tại (null nếu chưa đăng nhập)
  User? get currentUser => client.auth.currentUser;

  /// Stream auth state — lắng nghe đăng nhập / đăng xuất / token refresh
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Kiểm tra đã đăng nhập chưa
  bool get isAuthenticated => currentUser != null;

  /// Tên hiển thị lấy từ user metadata hoặc email
  String get displayName {
    final user = currentUser;
    if (user == null) return 'Anonymous';
    return user.userMetadata?['username'] as String? ??
        user.userMetadata?['full_name'] as String? ??
        user.email?.split('@').first ??
        'Anonymous';
  }
}
