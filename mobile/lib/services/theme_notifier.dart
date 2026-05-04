/// ThemeNotifier: Quản lý chuyển đổi Dark/Light theme.
///
/// Tại sao dùng ChangeNotifier thay vì Riverpod/Bloc:
/// - Cùng pattern với AudioPlayerService hiện có (consistency)
/// - Đơn giản, không thêm dependency cho tính năng nhỏ
library;

import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeNotifier._internal();

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
