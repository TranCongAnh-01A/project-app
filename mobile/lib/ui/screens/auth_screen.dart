/// AuthScreen: Màn hình đăng nhập/đăng ký — Pastel Bloom design.
///
/// Kết nối AuthCubit → Supabase Auth (Email/Password).
/// BlocConsumer xử lý:
/// - listener: navigate sang HomeScreen khi authenticated, show SnackBar lỗi
/// - builder: hiển thị loading spinner trên nút submit
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_cubit/auth_cubit.dart';
import '../../logic/auth_cubit/auth_state.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _rememberMe = true;
  bool _agreeTerms = false;

  // Controllers cho form đăng nhập
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Controllers cho form đăng ký
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();

  // ── Palette Pastel Bloom ──
  final _cPrimary = const Color(0xFFF5AFAF);
  final _cBg = const Color(0xFFFCF8F8);
  final _cCardBg = const Color(0xFFFFFFFF);
  final _cBorder = const Color(0xFFF9DFDF);
  final _cTextDark = const Color(0xFF5e4b4b);
  final _cTextDim = const Color(0xFFa98f8f);
  final _cIconLight = const Color(0xFFe0baba);

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPasswordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ email và mật khẩu.');
      return;
    }

    context.read<AuthCubit>().signIn(email: email, password: password);
  }

  void _handleSignUp() {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final password = _regPasswordCtrl.text;
    final confirm = _regConfirmCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    if (password.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }
    if (password != confirm) {
      _showError('Xác nhận mật khẩu không khớp.');
      return;
    }
    if (!_agreeTerms) {
      _showError('Bạn cần đồng ý với Điều khoản & Chính sách.');
      return;
    }

    context.read<AuthCubit>().signUp(
          email: email,
          password: password,
          displayName: name.isNotEmpty ? name : null,
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFc27b7b),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        // ── Điều hướng khi đăng nhập thành công ──
        if (state is AuthAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        // ── Hiển thị lỗi ──
        if (state is AuthError) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: _cBg,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: _cCardBg,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: const Color(0xFFFBEFEF)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x3FF5AFAF),
                          blurRadius: 40,
                          offset: Offset(0, 20),
                          spreadRadius: -8),
                      BoxShadow(
                          color: Color(0x4DF9DFDF),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                          spreadRadius: -6),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      _buildTabs(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLogin
                              ? _buildLoginForm(isLoading)
                              : _buildRegisterForm(isLoading),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBEFEF),
              borderRadius: BorderRadius.circular(60),
              boxShadow: const [
                BoxShadow(
                    color: Color(0xFFFCF8F8),
                    blurRadius: 3,
                    offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_outlined,
                    color: Color(0xFFb38b8b), size: 20),
                const SizedBox(width: 12),
                Icon(Icons.favorite, color: _cPrimary, size: 20),
                const SizedBox(width: 12),
                const Icon(Icons.spa_outlined,
                    color: Color(0xFFc49b9b), size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _cTextDark,
                  fontFamily: 'sans-serif'),
              children: const [
                TextSpan(text: 'Cuộc sống thiếu Gay\nhồn bay một nửa '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.favorite,
                      color: Color(0xFFF9DFDF), size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'không gian dịu dàng cho bạn',
            style: TextStyle(
                fontSize: 16, color: _cTextDim, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFFBEFEF), width: 2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabBtn("Đăng nhập", Icons.login, true),
            const SizedBox(width: 16),
            _buildTabBtn("Đăng ký", Icons.person_add, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String title, IconData icon, bool isLoginTab) {
    bool isActive = _isLogin == isLoginTab;
    return GestureDetector(
      onTap: () => setState(() => _isLogin = isLoginTab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _cPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(60),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                      color: Color(0x80F5AFAF),
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isActive ? Colors.white : const Color(0xFFa58b8b)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFFa58b8b),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // FORM ĐĂNG NHẬP
  // ══════════════════════════════════════════════

  Widget _buildLoginForm(bool isLoading) {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputGroup(
          'Email',
          Icons.email,
          Icons.alternate_email,
          'you@example.com',
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildInputGroup(
          'Mật khẩu',
          Icons.lock,
          Icons.vpn_key_outlined,
          '••••••••',
          isPassword: true,
          controller: _loginPasswordCtrl,
          onSubmitted: (_) => _handleSignIn(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) =>
                        setState(() => _rememberMe = v ?? false),
                    activeColor: _cPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const Text('Ghi nhớ đăng nhập',
                      style: TextStyle(
                          color: Color(0xFF836f6f),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Quên mật khẩu?',
                  style: TextStyle(
                      color: Color(0xFFb17b7b),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPrimaryBtn(
          'Đăng nhập',
          Icons.send,
          isLoading ? null : _handleSignIn,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _isLogin = false),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFFb29393), fontSize: 13),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.favorite,
                          size: 14, color: Color(0xFFF9DFDF))),
                ),
                TextSpan(text: 'Chưa có tài khoản? Chọn '),
                TextSpan(
                    text: '"Đăng ký"',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: ' nhé!'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // FORM ĐĂNG KÝ
  // ══════════════════════════════════════════════

  Widget _buildRegisterForm(bool isLoading) {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputGroup(
          'Họ và tên',
          Icons.account_circle,
          Icons.edit_outlined,
          'Nguyễn Pastel',
          controller: _regNameCtrl,
        ),
        const SizedBox(height: 16),
        _buildInputGroup(
          'Email',
          Icons.email,
          Icons.alternate_email,
          'you@example.com',
          isRequired: true,
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInputGroup(
                'Mật khẩu',
                Icons.lock,
                Icons.lock_outline,
                'Ít nhất 6 ký tự',
                isPassword: true,
                controller: _regPasswordCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputGroup(
                'Xác nhận',
                Icons.check_circle,
                Icons.security_outlined,
                'Nhập lại',
                isPassword: true,
                controller: _regConfirmCtrl,
                onSubmitted: (_) => _handleSignUp(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => setState(() => _agreeTerms = !_agreeTerms),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _agreeTerms,
                onChanged: (v) =>
                    setState(() => _agreeTerms = v ?? false),
                activeColor: _cPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              const Expanded(
                child: Text.rich(TextSpan(
                  style:
                      TextStyle(color: Color(0xFF836f6f), fontSize: 13),
                  children: [
                    TextSpan(text: 'Tôi đồng ý với '),
                    TextSpan(
                        text: 'Điều khoản',
                        style: TextStyle(
                            color: Color(0xFFc27b7b),
                            fontWeight: FontWeight.bold)),
                    TextSpan(text: ' & '),
                    TextSpan(
                        text: 'Chính sách',
                        style: TextStyle(
                            color: Color(0xFFc27b7b),
                            fontWeight: FontWeight.bold)),
                  ],
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPrimaryBtn(
          'Tạo tài khoản',
          Icons.person_add_alt_1,
          isLoading ? null : _handleSignUp,
          isLoading: isLoading,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _isLogin = true),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFFb29393), fontSize: 13),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.star,
                          size: 14, color: Color(0xFFF9DFDF))),
                ),
                TextSpan(text: 'Đã có tài khoản? Chuyển sang '),
                TextSpan(
                    text: '"Đăng nhập"',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════

  Widget _buildInputGroup(
    String label,
    IconData labelIcon,
    IconData inputIcon,
    String hint, {
    bool isPassword = false,
    bool isRequired = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Row(
            children: [
              Icon(labelIcon, size: 16, color: _cPrimary),
              const SizedBox(width: 6),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: label),
                  if (isRequired)
                    const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.redAccent)),
                ]),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6e5a5a),
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          textInputAction:
              onSubmitted != null ? TextInputAction.go : TextInputAction.next,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
              color: Color(0xFF3e2e2e), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFd3bcbc)),
            prefixIcon: Icon(inputIcon, color: _cIconLight),
            filled: true,
            fillColor: _cBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(48),
              borderSide: BorderSide(color: _cBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(48),
              borderSide: BorderSide(color: _cPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryBtn(
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
              color: Color(0x66F5AFAF),
              blurRadius: 18,
              offset: Offset(0, 8),
              spreadRadius: -8),
        ],
        borderRadius: BorderRadius.circular(60),
      ),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 18),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _cPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(60),
            side: const BorderSide(color: Color(0xFFfcd0d0)),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
