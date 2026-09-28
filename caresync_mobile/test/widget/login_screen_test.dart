import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caresync_mobile/app/theme.dart';
import 'package:caresync_mobile/providers/auth_provider.dart';
import 'package:caresync_mobile/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders credentials form and demo chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Verify Brand title & Welcome message
    expect(find.text('Welcome to CareSync'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify Guest Demo Role chips
    expect(find.text('Patient Demo'), findsOneWidget);
    expect(find.text('Doctor Demo'), findsOneWidget);
    expect(find.text('Admin Demo'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation errors on empty submission', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    // Tap Sign In without typing credentials
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
