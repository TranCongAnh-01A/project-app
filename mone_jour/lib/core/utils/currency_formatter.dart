import 'package:intl/intl.dart';

/// Format số tiền VND với dấu chấm phân cách hàng nghìn.
///
/// Ví dụ: 1500000 → "1.500.000 ₫"
///         -250000 → "-250.000 ₫"
String formatVND(double amount) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return '${formatter.format(amount.round())} ₫';
}

/// Format số tiền VND có dấu +/- cho dashboard.
///
/// Ví dụ: 1500000 → "+1.500.000 ₫"
///        -250000 → "-250.000 ₫"
String formatVNDSigned(double amount) {
  final prefix = amount >= 0 ? '+' : '';
  return '$prefix${formatVND(amount)}';
}
