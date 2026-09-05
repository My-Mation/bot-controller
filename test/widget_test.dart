import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_controller/main.dart';

void main() {
  testWidgets('Controller app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BotControllerApp()));
    await tester.pump();
    // Just verify the app renders without errors
    expect(find.byType(BotControllerApp), findsOneWidget);
  });
}
