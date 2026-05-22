import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_mock_interviewer/main.dart';

// Force refresh the analyzer
void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    await tester.pumpWidget(MyApp(prefs: prefs));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
