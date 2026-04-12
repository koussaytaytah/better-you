import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_you/features/ai_assistant/screens/ai_chat_screen.dart';

void main() {
  testWidgets('AI Chat Screen should have voice, camera, and gallery icons', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AIChatScreen())),
    );
    await tester.pump(); // Pump one frame to let widgets build

    // Check for the Mic icon
    expect(find.byIcon(Icons.mic_none), findsOneWidget);

    // Check for the Camera icon
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

    // Check for the Image icon
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);

    // Check for the Send icon
    expect(find.byIcon(Icons.send), findsOneWidget);

    // To avoid the "Timer is still pending" error from animations
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
