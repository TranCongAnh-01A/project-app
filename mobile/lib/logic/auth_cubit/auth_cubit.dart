/// AuthCubit: Quản lý xác thực Supabase Email/Password.
///
/// Chức năng:
/// - checkSession(): Kiểm tra session hiện tại khi app mở
/// - signIn(): Đăng nhập bằng email/password
/// - signUp(): Đăng ký tài khoản mới
/// - signOut(): Đăng xuất + clear session
/// - Tự động lắng nghe onAuthStateChange từ Supabase
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SupabaseClient _client;
  StreamSubscription<AuthState>? _authSub;

  AuthCubit({required SupabaseClient client})
      : _client = client,
        super(const AuthInitial()) {
    // Lắng nghe thay đổi auth từ Supabase (login/logout/token refresh)
    _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        emit(AuthAuthenticated(
          userId: session.user.id,
          email: session.user.email ?? '',
        ));
      } else if (data.event == AuthChangeEvent.signedOut) {
        emit(const AuthUnauthenticated());
      }
    });
  }

  /// Kiểm tra session đã lưu (gọi khi app khởi động)
  void checkSession() {
    final session = _client.auth.currentSession;
    if (session != null) {
      emit(AuthAuthenticated(
        userId: session.user.id,
        email: session.user.email ?? '',
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Đăng nhập bằng email + password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      emit(const AuthLoading());

      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      // Không cần emit Authenticated ở đây
      // → onAuthStateChange listener sẽ tự emit khi nhận event signedIn
    } catch (e) {
      emit(AuthError(_parseAuthError(e)));
    }
  }

  /// Đăng ký tài khoản mới
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      emit(const AuthLoading());

      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      // Supabase mặc định yêu cầu xác nhận email
      // Nếu project đã tắt email confirmation → sẽ tự signedIn
      // Nếu chưa tắt → emit thông báo cho user kiểm tra email
      final session = _client.auth.currentSession;
      if (session != null) {
        // Đã tự đăng nhập (email confirmation đã tắt)
        emit(AuthAuthenticated(
          userId: session.user.id,
          email: session.user.email ?? '',
        ));
      } else {
        // Cần xác nhận email trước
        emit(const AuthError(
          'Đăng ký thành công! Vui lòng kiểm tra email để xác nhận tài khoản.',
        ));
      }
    } catch (e) {
      emit(AuthError(_parseAuthError(e)));
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      debugPrint('[AuthCubit] Lỗi signOut: $e');
      // Vẫn emit unauthenticated để user có thể login lại
      emit(const AuthUnauthenticated());
    }
  }

  /// Parse lỗi Supabase thành tiếng Việt dễ hiểu
  String _parseAuthError(Object error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Email này đã được đăng ký. Hãy đăng nhập.';
    }
    if (msg.contains('password should be at least')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (msg.contains('unable to validate email')) {
      return 'Địa chỉ email không hợp lệ.';
    }
    if (msg.contains('email rate limit exceeded')) {
      return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Không có kết nối mạng. Kiểm tra Internet.';
    }

    return 'Lỗi xác thực: $error';
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
