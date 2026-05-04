import 'package:flutter_test/flutter_test.dart';
import 'package:pmka_mobile/main.dart';

void main() {
  testWidgets('App khởi động thành công', (WidgetTester tester) async {
    await tester.pumpWidget(const PMKAApp());
    expect(find.text('PMKA'), findsOneWidget);
  });
}
