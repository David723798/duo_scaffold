import 'package:duo_scaffold_example/main.dart';
import 'package:duo_scaffold/duo_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the inbox and can open a message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MailDemoApp());

    expect(find.byType(DuoScaffold), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Maya Chen'), findsOneWidget);
    await tester.tap(find.text('Maya Chen'));
    await tester.pumpAndSettle();

    expect(find.text('Launch notes'), findsOneWidget);
  });

  testWidgets('uses right-side controls by default on a wide viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MailDemoApp());

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byTooltip('Open navigation'), findsOneWidget);
    expect(find.byTooltip('Compose'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.vertical_split_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top and bottom'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('keeps the selected message after changing preview layouts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MailDemoApp());
    await tester.tap(find.text('Maya Chen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.preview_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();

    expect(find.text('Launch notes'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.preview_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic'));
    await tester.pumpAndSettle();

    expect(find.text('Launch notes'), findsOneWidget);
  });

  testWidgets('navigation destinations change the displayed mailbox', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MailDemoApp());

    await tester.tap(find.byTooltip('Starred'));
    await tester.pumpAndSettle();
    expect(find.text('Samir Patel'), findsOneWidget);
    expect(find.text('Maya Chen'), findsNothing);
  });

  testWidgets('pushes the compose route and receives its result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MailDemoApp());

    await tester.tap(find.byTooltip('Compose'));
    await tester.pumpAndSettle();
    expect(find.text('New message'), findsOneWidget);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Message sent.'), findsOneWidget);
    expect(find.byType(DuoScaffold), findsOneWidget);
  });

  testWidgets('opens navigation from the same physical edge as the side rail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MailDemoApp());

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Duo Mail')).center.dx, greaterThan(400));

    await tester.tapAt(const Offset(100, 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Preview controls layout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Left rail'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Duo Mail')).center.dx, lessThan(400));
  });
}
