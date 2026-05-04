/// AuthState: Trạng thái xác thực người dùng.
///
/// Luồng chuyển đổi:
///   App khởi động → checkSession() → Authenticated / Unauthenticated
///   Unauthenticated → signIn/signUp → Loading → Authenticated / Error
///   Authenticated → signOut → Unauthenticated
library;

import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Đang kiểm tra session (splash)
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Đang gọi API sign in / sign up
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Đã đăng nhập — chứa thông tin user
class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;

  const AuthAuthenticated({required this.userId, required this.email});

  @override
  List<Object?> get props => [userId, email];
}

/// Chưa đăng nhập hoặc session hết hạn
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Lỗi auth (sai password, email trùng, mạng lỗi...)
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
