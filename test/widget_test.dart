import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_you/main.dart';
import 'package:better_you/shared/providers/auth_provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:better_you/core/services/auth_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create mock instances
    final mockAuth = MockFirebaseAuth();
    final mockFirestore = FakeFirebaseFirestore();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override authServiceProvider to use mock
          authServiceProvider.overrideWithValue(
            AuthService(mockAuth, mockFirestore),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app starts without crashing
    expect(find.byType(MyApp), findsOneWidget);

    // Pump to handle splash screen timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
