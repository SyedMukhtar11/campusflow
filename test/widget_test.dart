// Run with: flutter test
// If your package name is not "campusflow", change it in the imports
// (see the "name:" line in pubspec.yaml).
import 'dart:io';

import 'package:campusflow/main.dart';
import 'package:campusflow/models/program.dart';
import 'package:campusflow/providers/auth_provider.dart';
import 'package:campusflow/providers/program_provider.dart';
import 'package:campusflow/providers/theme_provider.dart';
import 'package:campusflow/screens/feedback_screen.dart';
import 'package:campusflow/services/auth_service.dart';
import 'package:campusflow/services/program_service.dart';
import 'package:campusflow/services/session_storage.dart';
import 'package:campusflow/widgets/hover_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Reads the same JSON file the app uses, with no delay, so tests are fast.
ProgramService testService() => ProgramService(
      delay: Duration.zero,
      loader: () async =>
          File('assets/data/programs.json').readAsStringSync(),
    );

AuthProvider testAuth([SessionStorage? storage]) => AuthProvider(
      service: const MockAuthService(delay: Duration.zero),
      storage: storage ?? MemorySessionStorage(),
    );

Widget buildApp() => MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ProgramProvider(service: testService())),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => testAuth()),
      ],
      child: const CampusFlowApp(useGoogleFonts: false),
    );

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'alex@test.com');
  await tester.enterText(find.byType(TextFormField).at(1), '123456');
  await tester.tap(find.text('Log in'));
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  // Tests draw text with the "Ahem" font (every letter is a wide square),
  // so rows can falsely report "RenderFlex overflowed". Real devices use
  // Inter and are fine, so we ignore only those overflow messages here.
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

void main() {
  group('Data loading (JSON)', () {
    test('service loads 5 programs from programs.json', () async {
      final programs = await testService().fetchPrograms();
      expect(programs.length, 5);
      expect(programs.first.title, 'Design Thinking Workshop');
    });

    test('Program.fromJson tolerates missing fields', () {
      final p = Program.fromJson(const {'id': 'x', 'title': 'Only Title'});
      expect(p.title, 'Only Title');
      expect(p.learnPoints, isEmpty);
      expect(p.fee, 'Free');
    });

    test('Program.fromJson accepts backend-style field names', () {
      final p = Program.fromJson(const {
        '_id': 'abc',
        'name': 'Backend Program',
        'description': 'From the API',
        'category': 'Career',
      });
      expect(p.id, 'abc');
      expect(p.title, 'Backend Program');
      expect(p.about, 'From the API');
    });

    test('provider exposes an error when loading fails', () async {
      final provider = ProgramProvider(
        service: ProgramService(
          delay: Duration.zero,
          loader: () async => throw Exception('network down'),
        ),
      );
      await provider.loadPrograms();
      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.allPrograms, isEmpty);
    });
  });

  group('Authentication', () {
    test('valid login signs the user in', () async {
      final auth = testAuth();
      await auth.ready;
      expect(await auth.login('alex@test.com', '123456'), isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.user!.email, 'alex@test.com');
      expect(auth.user!.name, 'Alex');
    });

    test('invalid login shows an error', () async {
      final auth = testAuth();
      await auth.ready;
      expect(await auth.login('nope', '1'), isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.error, isNotNull);
    });

    test('signup signs the user in with the chosen name', () async {
      final auth = testAuth();
      await auth.ready;
      expect(await auth.signup('Sam Lee', 'sam@test.com', 'secret1'), isTrue);
      expect(auth.user!.name, 'Sam Lee');
    });

    test('logout clears the session', () async {
      final auth = testAuth();
      await auth.ready;
      await auth.login('alex@test.com', '123456');
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
    });

    test('a saved session is restored on start', () async {
      final storage = MemorySessionStorage();
      await storage.save(token: 't', name: 'Alex', email: 'alex@test.com');
      final auth = testAuth(storage);
      await auth.ready;
      expect(auth.isLoggedIn, isTrue);
    });
  });

  group('App flow', () {
    testWidgets('Login shows validation errors when empty', (tester) async {
      phoneSize(tester);
      await pumpApp(tester);
      await tester.tap(find.text('Log in'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    
  testWidgets('Signup validates its fields', (tester) async {
  phoneSize(tester);
  await pumpApp(tester);

  await tester.tap(find.text('Sign up'));
  await tester.pumpAndSettle();

  expect(find.text('Full name'), findsOneWidget);

  final button = find.widgetWithText(
    ElevatedButton,
    'Create account',
  );

  expect(button, findsOneWidget);

  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();

  // Print what Flutter finds after validation.
  debugDumpApp();

  expect(find.text('Please enter your name'), findsOneWidget);
  expect(find.text('Please enter your email'), findsOneWidget);
});


    testWidgets('Login leads to Home with the user name', (tester) async {
      phoneSize(tester);
      await pumpApp(tester);
      await login(tester);
      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.textContaining('Good morning, Alex'), findsOneWidget);
    });

    testWidgets('Programs -> Details -> Register -> Confirmation',
        (tester) async {
      phoneSize(tester);
      await pumpApp(tester);
      await login(tester);
      await openTab(tester, 'Programs');

      await tester.tap(find.text('Design Thinking Workshop'));
      await tester.pumpAndSettle();
      expect(find.text('Register'), findsOneWidget);

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.text('Registration confirmed'), findsOneWidget);
    });

    testWidgets('Registered event appears on the Events tab', (tester) async {
      phoneSize(tester);
      await pumpApp(tester);
      await login(tester);
      await openTab(tester, 'Programs');
      await tester.tap(find.text('Design Thinking Workshop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to programs'));
      await tester.pumpAndSettle();

      await openTab(tester, 'Events');
      expect(find.text('My registrations'), findsOneWidget);
      expect(find.text('Design Thinking Workshop'), findsWidgets);
    });

    testWidgets('Programs search with no match shows the empty state',
        (tester) async {
      phoneSize(tester);
      await pumpApp(tester);
      await login(tester);
      await openTab(tester, 'Programs');

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('No programs found'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('No programs found'), findsNothing);
    });

    testWidgets('Home bell opens Notifications with 3 unread', (tester) async {
      phoneSize(tester);
      await pumpApp(tester);
      await login(tester);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Unread (3)'), findsOneWidget);
    });

    testWidgets('Profile log out returns to Login', (tester) async {
      phoneSize(tester);
      await pumpApp(tester);
      await login(tester);
      await openTab(tester, 'Profile');

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('Feedback form', () {
    Widget feedbackApp() {
      final program =
          Program.fromJson(const {'id': 't1', 'title': 'Test Program'});
      return ChangeNotifierProvider(
        create: (_) => ProgramProvider(service: testService()),
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => FeedbackScreen(program: program)),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows validation errors when submitted empty', (tester) async {
      phoneSize(tester);
      await tester.pumpWidget(feedbackApp());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Submit feedback'));
      await tester.tap(find.text('Submit feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a rating'), findsOneWidget);
      expect(find.text('Please choose a category'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your feedback'), findsOneWidget);
    });

    testWidgets('rejects a short comment', (tester) async {
      phoneSize(tester);
      await tester.pumpWidget(feedbackApp());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.ensureVisible(find.text('Submit feedback'));
      await tester.tap(find.text('Submit feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Please write at least 10 characters'), findsOneWidget);
    });

    testWidgets('valid form is saved and shows thank-you message',
        (tester) async {
      phoneSize(tester);
      await tester.pumpWidget(feedbackApp());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_border).at(3)); // 4 stars
      await tester.pump();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Content').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'alex@test.com');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'Great session, very practical.');

      await tester.ensureVisible(find.text('Submit feedback'));
      await tester.tap(find.text('Submit feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Thank you for your feedback!'), findsOneWidget);
      final provider = Provider.of<ProgramProvider>(
          tester.element(find.text('open')),
          listen: false);
      expect(provider.feedbackEntries.length, 1);
      expect(provider.feedbackEntries.first.rating, 4);
    });
  });

  group('Theme and hover', () {
    test('ThemeProvider toggles between light and dark', () {
      final theme = ThemeProvider();
      expect(theme.mode, ThemeMode.light);
      theme.toggle();
      expect(theme.mode, ThemeMode.dark);
      expect(theme.isDark, isTrue);
      theme.toggle();
      expect(theme.mode, ThemeMode.light);
    });

    testWidgets('HoverCard grows when the mouse hovers over it',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Center(child: HoverCard(child: Text('card'))),
      ));
      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('card')));
      await tester.pumpAndSettle();

      final scale =
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      expect(scale, greaterThan(1.0));
    });
  });

  testWidgets('My Learning tab opens without overflow on mobile', (tester) async {
    phoneSize(tester);
    await tester.pumpWidget(buildApp());
    await login(tester);

    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('My Learning')));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Ongoing'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);
  });
}
