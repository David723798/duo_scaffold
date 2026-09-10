import 'dart:ui';

import 'package:duo_scaffold/duo_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DuoLayoutPolicy policy = DuoLayoutPolicy();

  DuoDisplayFeature feature(Rect bounds, DisplayFeatureState state) =>
      DuoDisplayFeature(
        bounds: bounds,
        type: DisplayFeatureType.fold,
        state: state,
      );

  test('resolves compact and expanded layouts from available size', () {
    expect(
      policy.resolve(const Size(390, 844)).layout,
      DuoLayout.compactPortrait,
    );
    expect(
      policy.resolve(const Size(590, 390)).layout,
      DuoLayout.compactLandscape,
    );
    expect(
      policy.resolve(const Size(844, 390)).layout,
      DuoLayout.expandedLandscape,
    );
    expect(
      policy.resolve(const Size(700, 900)).layout,
      DuoLayout.expandedPortrait,
    );
  });

  test('resolves book and tabletop only from a half-open fold', () {
    expect(
      policy
          .resolve(
            const Size(800, 600),
            displayFeatures: <DuoDisplayFeature>[
              feature(
                const Rect.fromLTWH(396, 0, 8, 600),
                DisplayFeatureState.postureHalfOpened,
              ),
            ],
          )
          .layout,
      DuoLayout.book,
    );
    expect(
      policy
          .resolve(
            const Size(800, 600),
            displayFeatures: <DuoDisplayFeature>[
              feature(
                const Rect.fromLTWH(0, 296, 800, 8),
                DisplayFeatureState.postureHalfOpened,
              ),
            ],
          )
          .layout,
      DuoLayout.tabletop,
    );
    expect(
      policy
          .resolve(
            const Size(800, 600),
            displayFeatures: <DuoDisplayFeature>[
              feature(
                const Rect.fromLTWH(396, 0, 8, 600),
                DisplayFeatureState.postureFlat,
              ),
            ],
          )
          .layout,
      DuoLayout.expandedLandscape,
    );
  });

  test('ignores a half-open feature that does not span the local body', () {
    expect(
      policy
          .resolve(
            const Size(800, 600),
            displayFeatures: <DuoDisplayFeature>[
              feature(
                const Rect.fromLTWH(396, 100, 8, 300),
                DisplayFeatureState.postureHalfOpened,
              ),
            ],
          )
          .layout,
      DuoLayout.expandedLandscape,
    );
  });

  testWidgets('keeps inactive compact pane mounted while changing panes', (
    WidgetTester tester,
  ) async {
    Future<void> pump(DuoPane pane) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DuoBody(
            policy: const DuoLayoutPolicy(
              layoutOverride: DuoLayout.compactPortrait,
            ),
            compactPane: pane,
            primary: const Text('inbox'),
            secondary: const Text('message'),
          ),
        ),
      ),
    );

    await pump(DuoPane.primary);
    expect(find.text('inbox'), findsOneWidget);
    expect(find.text('message'), findsNothing);
    await pump(DuoPane.secondary);
    expect(find.text('inbox'), findsNothing);
    expect(find.text('message'), findsOneWidget);
  });

  testWidgets('preserves a pane state while its presentation changes', (
    WidgetTester tester,
  ) async {
    Future<void> pump(DuoLayout layout) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DuoBody(
            layout: DuoLayoutInfo(layout: layout, size: const Size(800, 600)),
            primary: const _StatefulPane(),
            secondary: const SizedBox(),
          ),
        ),
      ),
    );

    await pump(DuoLayout.compactPortrait);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await pump(DuoLayout.expandedLandscape);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('tabletop uses dedicated top and bottom content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DuoBody(
            layout: DuoLayoutInfo(
              layout: DuoLayout.tabletop,
              size: Size(800, 600),
              foldBounds: Rect.fromLTWH(0, 296, 800, 8),
            ),
            primary: Text('primary'),
            tabletopTop: Text('top'),
            tabletopBottom: Text('bottom'),
          ),
        ),
      ),
    );
    expect(find.text('top'), findsOneWidget);
    expect(find.text('bottom'), findsOneWidget);
    expect(find.text('primary'), findsNothing);
  });

  testWidgets('keeps a right safe-area inset out of both panes', (
    WidgetTester tester,
  ) async {
    final Key primaryKey = UniqueKey();
    final Key secondaryKey = UniqueKey();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.only(right: 44),
          viewPadding: EdgeInsets.only(right: 44),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DuoBody(
            policy: const DuoLayoutPolicy(
              layoutOverride: DuoLayout.expandedLandscape,
            ),
            primary: SizedBox.expand(key: primaryKey),
            secondary: SizedBox.expand(key: secondaryKey),
          ),
        ),
      ),
    );

    final Rect primary = tester.getRect(find.byKey(primaryKey));
    final Rect secondary = tester.getRect(find.byKey(secondaryKey));
    expect(primary.left, 0);
    expect(primary.width, 378);
    expect(secondary.right, 756);
    expect(secondary.height, 600);
  });

  testWidgets('translates a fold after top safe-area consumption', (
    WidgetTester tester,
  ) async {
    final Key topKey = UniqueKey();
    final Key bottomKey = UniqueKey();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          padding: EdgeInsets.only(top: 24),
          viewPadding: EdgeInsets.only(top: 24),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DuoBody(
            layout: const DuoLayoutInfo(
              layout: DuoLayout.tabletop,
              size: Size(800, 600),
              foldBounds: Rect.fromLTWH(0, 296, 800, 8),
            ),
            primary: const SizedBox(),
            tabletopTop: SizedBox(key: topKey),
            tabletopBottom: SizedBox(key: bottomKey),
          ),
        ),
      ),
    );

    final Rect top = tester.getRect(find.byKey(topKey));
    final Rect bottom = tester.getRect(find.byKey(bottomKey));
    expect(top.top, 24);
    expect(top.height, 272);
    expect(bottom.top, 304);
    expect(bottom.bottom, 600);
  });

  test('uses a right rail for a wide viewport unless layout is explicit', () {
    expect(
      const DuoChromePolicy().resolve(size: const Size(599, 900)),
      DuoChromeLayout.topAndBottom,
    );
    expect(
      const DuoChromePolicy().resolve(size: const Size(600, 900)),
      DuoChromeLayout.rightRail,
    );
    expect(
      const DuoChromePolicy(layoutOverride: DuoChromeLayout.leftRail).resolve(
        size: const Size(800, 600),
        platformLayout: DuoChromeLayout.rightRail,
      ),
      DuoChromeLayout.leftRail,
    );
    expect(
      const DuoChromePolicy().resolve(
        size: const Size(800, 600),
        platformLayout: DuoChromeLayout.topAndBottom,
      ),
      DuoChromeLayout.topAndBottom,
    );
  });

  testWidgets('direct layout settings override a DuoBody policy', (
    tester,
  ) async {
    const Key primaryKey = ValueKey('primary');
    const Key secondaryKey = ValueKey('secondary');
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 700,
            height: 500,
            child: DuoBody(
              policy: DuoLayoutPolicy(expandedBreakpoint: 900),
              expandedBreakpoint: 600,
              primary: SizedBox(key: primaryKey),
              secondary: SizedBox(key: secondaryKey),
            ),
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byKey(primaryKey)).width, 350);
    expect(tester.getRect(find.byKey(secondaryKey)).width, 350);
  });

  testWidgets('direct chrome settings override a DuoScaffold policy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: DuoScaffold(
          policy: const DuoChromePolicy(sideRailBreakpoint: 900),
          sideRailBreakpoint: 600,
          bodyBuilder: (_, DuoChromeInfo info) => Text('${info.layout}'),
        ),
      ),
    );

    expect(find.text('${DuoChromeLayout.rightRail}'), findsOneWidget);
  });

  testWidgets('a direct body does not require a builder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DuoScaffold(body: Text('Page body'))),
    );

    expect(find.text('Page body'), findsOneWidget);
  });

  testWidgets('one scaffold switches page slots and keeps Material services', (
    WidgetTester tester,
  ) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    Future<void> pump(double width) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: DuoScaffold(
            scaffoldKey: scaffoldKey,
            appBar: AppBar(title: const Text('Page')),
            bottomNavigationBar: const SizedBox(
              height: 60,
              child: Text('Bottom'),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            drawer: const Drawer(child: Text('Navigation')),
            bodyBuilder: (context, _) => TextButton(
              onPressed: () {
                expect(Scaffold.of(context), same(scaffoldKey.currentState));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Saved')));
              },
              child: const Text('Save'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(390);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Bottom'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);
    await pump(800);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Bottom'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(scaffoldKey.currentState!.isEndDrawerOpen, isTrue);
  });

  for (final DuoChromeLayout layout in [
    DuoChromeLayout.leftRail,
    DuoChromeLayout.rightRail,
  ]) {
    testWidgets('RTL drawer follows physical edge for $layout', (tester) async {
      const Key drawerKey = ValueKey('drawer');
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DuoScaffold(
              policy: DuoChromePolicy(layoutOverride: layout),
              drawer: const Drawer(key: drawerKey, child: Text('Navigation')),
              bodyBuilder: (context, info) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      final Rect bounds = tester.getRect(find.byKey(drawerKey));
      expect(
        layout == DuoChromeLayout.leftRail ? bounds.left : bounds.right,
        layout == DuoChromeLayout.leftRail ? 0 : 800,
      );
    });
  }

  testWidgets('body uses space remaining after app bar and keyboard', (
    tester,
  ) async {
    const Key bodyKey = ValueKey('body');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            viewInsets: EdgeInsets.only(bottom: 200),
          ),
          child: DuoScaffold(
            policy: const DuoChromePolicy(
              layoutOverride: DuoChromeLayout.topAndBottom,
            ),
            appBar: AppBar(title: const Text('Page')),
            bodyBuilder: (context, info) => const SizedBox.expand(key: bodyKey),
          ),
        ),
      ),
    );
    final Rect bounds = tester.getRect(find.byKey(bodyKey));
    expect(bounds.top, kToolbarHeight);
    expect(bounds.bottom, 400);
  });

  test('assigns a drawer to the matching physical Scaffold edge', () {
    const Widget drawer = SizedBox();
    final DuoDrawerSlots right = DuoDrawerSlots.forLayout(
      layout: DuoChromeLayout.rightRail,
      drawer: drawer,
    );
    final DuoDrawerSlots left = DuoDrawerSlots.forLayout(
      layout: DuoChromeLayout.leftRail,
      drawer: drawer,
    );

    expect(right.drawer, isNull);
    expect(right.endDrawer, same(drawer));
    expect(left.drawer, same(drawer));
    expect(left.endDrawer, isNull);
  });

  testWidgets(
    'lays out side controls on the right and sends excess actions to overflow',
    (WidgetTester tester) async {
      final Key bodyKey = UniqueKey();
      var invoked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              padding: EdgeInsets.only(right: 44),
            ),
            child: DuoScaffold(
              policy: const DuoChromePolicy(
                layoutOverride: DuoChromeLayout.rightRail,
              ),
              maxVisibleActions: 1,
              actions: <DuoAction>[
                DuoAction(
                  id: 'compose',
                  label: 'Compose',
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                  visibilityPriority: 1,
                ),
                DuoAction(
                  id: 'search',
                  label: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: () => invoked = true,
                ),
              ],
              destinations: const <DuoDestination>[
                DuoDestination(
                  id: 'inbox',
                  label: 'Inbox',
                  icon: Icon(Icons.inbox),
                ),
              ],
              selectedDestinationId: 'inbox',
              onDestinationSelected: (_) {},
              bodyBuilder: (context, info) => SizedBox.expand(key: bodyKey),
            ),
          ),
        ),
      );
      expect(tester.getRect(find.byKey(bodyKey)).right, 684);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search'));
      expect(invoked, isTrue);
    },
  );

  testWidgets('puts the declared leading control first in a side rail', (
    WidgetTester tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: DuoScaffold(
            policy: const DuoChromePolicy(
              layoutOverride: DuoChromeLayout.rightRail,
            ),
            leadingAction: DuoAction(
              id: 'menu',
              label: 'Open navigation',
              icon: const Icon(Icons.menu),
              onPressed: () => opened = true,
            ),
            bodyBuilder: (context, info) => const SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Open navigation'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation'));
    expect(opened, isTrue);
  });
}

class _StatefulPane extends StatefulWidget {
  const _StatefulPane();

  @override
  State<_StatefulPane> createState() => _StatefulPaneState();
}

class _StatefulPaneState extends State<_StatefulPane> {
  int count = 0;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: () => setState(() => count += 1),
    child: Text('$count'),
  );
}
