import 'package:flutter_test/flutter_test.dart';
import 'package:time_logger_app/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TimeLoggerApp());
    expect(find.text('تایم لاگر — سازنده: کورش شیراز'), findsOneWidget);
  });
}
