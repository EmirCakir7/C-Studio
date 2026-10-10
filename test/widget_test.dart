import 'package:flutter_test/flutter_test.dart';
import 'package:c_studio/main.dart';

void main() {
  testWidgets('C-Studio App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CStudioApp());
    expect(find.byType(CStudioApp), findsOneWidget);
  });
}
