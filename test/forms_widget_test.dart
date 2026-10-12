import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travelverse/data/services/local_db.dart';
import 'package:travelverse/features/auth/login_screen.dart';
import 'package:travelverse/features/auth/signup_screen.dart';
import 'package:travelverse/features/trips/trip_form_screen.dart';
import 'package:travelverse/providers.dart';

Widget _app(Widget child, {List overrides = const []}) =>
    ProviderScope(overrides: [...overrides], child: MaterialApp(home: child));

void main() {
  testWidgets('login shows errors for empty fields', (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('login rejects a malformed email', (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));
    await tester.enterText(find.byKey(const Key('login_email')), 'aria.gmail.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'whatever');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.textContaining('Enter a valid email'), findsOneWidget);
  });

  testWidgets('sign-up validates every field and the terms checkbox', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const SignupScreen()));
    await tester.enterText(find.byKey(const Key('signup_name')), 'R2');
    await tester.enterText(find.byKey(const Key('signup_email')), 'r2@');
    await tester.enterText(find.byKey(const Key('signup_phone')), '12345');
    await tester.enterText(find.byKey(const Key('signup_password')), 'password');
    await tester.enterText(find.byKey(const Key('signup_confirm')), 'different');
    await tester.tap(find.byKey(const Key('signup_submit')));
    await tester.pump();
    expect(find.text('Name must be at least 3 characters'), findsOneWidget);
    expect(find.textContaining('Enter a valid email'), findsOneWidget);
    expect(find.text('Mobile number must be 10 digits'), findsOneWidget);
    expect(find.text('Add at least one capital letter'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.text('Please accept the guidelines to continue'), findsOneWidget);
  });

  testWidgets('trip form validates budget and dates', (tester) async {
    sqfliteFfiInit();
    final db = await tester.runAsync(() => LocalDb.open(factory: databaseFactoryFfi, name: inMemoryDatabasePath));
    await tester.pumpWidget(_app(const TripFormScreen(), overrides: [
      localDbProvider.overrideWithValue(db!),
      uidProvider.overrideWithValue('u1'),
    ]));
    await tester.enterText(find.byKey(const Key('trip_name')), 'Goa Getaway');
    await tester.enterText(find.byKey(const Key('trip_destination')), 'Goa');
    await tester.enterText(find.byKey(const Key('trip_travellers')), '25');
    await tester.enterText(find.byKey(const Key('trip_budget')), '100');
    await tester.tap(find.byKey(const Key('trip_save')));
    await tester.pump();
    expect(find.text('Travellers must be at most 20'), findsOneWidget);
    expect(find.text('Budget must be at least 500'), findsOneWidget);
    expect(find.text('Select a start date'), findsOneWidget);
  });
}
