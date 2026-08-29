
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_chat/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuranChatApp());

    // Verify that our app bar title is rendered
    expect(find.text('Quran Chat (MVP)'), findsOneWidget);
  });
}
