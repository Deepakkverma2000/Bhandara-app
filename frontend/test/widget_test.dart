import 'package:flutter_test/flutter_test.dart';

import 'package:bhandara_live/main.dart';

void main() {
  testWidgets('App loads with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const BhandaraLiveApp());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Bhandara'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Our Services'), findsOneWidget);
  });
}
