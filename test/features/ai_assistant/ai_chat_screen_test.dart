import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_you/features/dashboard/screens/ai_chatbot_screen.dart';

void main() {
  testWidgets('AI Chatbot Screen should have mic, camera, and send icons', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AIChatbotScreen())),
    );
    await tester.pump(); // Pump one frame to let widgets build

    // Check for the Mic icon (voice input)
    expect(find.byIcon(Icons.mic_none), findsOneWidget);

    // Check for the Camera icon (image picker)
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);

    // Check for the Send icon
    expect(find.byIcon(Icons.send), findsOneWidget);

    // To avoid the "Timer is still pending" error from animations
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
