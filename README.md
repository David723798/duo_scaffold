# duo_scaffold

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.22.0-02569B?logo=flutter)](https://flutter.dev)
[![Example website](https://img.shields.io/badge/example-GitHub%20Pages-222?logo=github)](https://david723798.github.io/duo_scaffold/)

`duo_scaffold` provides a complete adaptive `DuoScaffold` page and fold-aware Flutter layout primitives. It chooses a layout from the space available to the widget and Flutter's `DisplayFeature` data, while your application keeps ownership of navigation and content state.

## Live demo

Try the interactive Mail example on GitHub Pages: [Demo](https://david723798.github.io/duo_scaffold/)

## Screenshots

The Mail example on [iPhone Duo](#iphone-duo). The package detects each of these six postures on its own; book and tabletop come from the hinge on iOS 27.1 and later.

| Cover display, portrait | Cover display, landscape |
| --- | --- |
| One pane, with the rail in the camera and status strip on the right. | The cover rotates; the strip moves to the left edge, and the rail moves with it. |
| ![Mail example on iPhone Duo's cover display in portrait](assets/screenshots/iphone-duo-cover-portrait.png) | ![Mail example on iPhone Duo's cover display in landscape](assets/screenshots/iphone-duo-cover-landscape.png) |

| Inner display, landscape | Inner display, portrait |
| --- | --- |
| The message list and selected message meet at the crease, and the rail sits in the status strip. | One pane at a time, with the rail in the same strip. |
| ![Mail example on iPhone Duo's inner display in landscape](assets/screenshots/iphone-duo-inner-landscape.png) | ![Mail example on iPhone Duo's inner display in portrait](assets/screenshots/iphone-duo-inner-portrait.png) |

| Half-open, book | Half-open, tabletop |
| --- | --- |
| Two panes either side of a vertical hinge. | The message above a horizontal hinge, its attachments below. |
| ![Mail example on iPhone Duo half-open as a book](assets/screenshots/iphone-duo-book.png) | ![Mail example on iPhone Duo half-open as a tabletop](assets/screenshots/iphone-duo-tabletop.png) |

## Install

```sh
flutter pub add duo_scaffold
```

The package supports Dart `>=3.4.0 <4.0.0` and Flutter `>=3.22.0`.
It is tested against the minimum supported Flutter release, representative
stable releases, and the latest stable channel.

## Quick start

Use one `DuoScaffold` as the page and put `DuoBody` in its body. Keep the selected pane in page state and provide the two pieces of content.

```dart
import 'package:duo_scaffold/duo_scaffold.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: MailPage()));

class MailPage extends StatefulWidget {
  const MailPage({super.key});

  @override
  State<MailPage> createState() => _MailPageState();
}

class _MailPageState extends State<MailPage> {
  bool _showingInbox = true;

  @override
  Widget build(BuildContext context) => DuoScaffold(
    appBar: AppBar(title: const Text('Mail')),
    body: DuoBody(
      compactPane: _showingInbox ? DuoPane.primary : DuoPane.secondary,
      primary: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('A message'),
            onTap: () => setState(() => _showingInbox = false),
          ),
        ],
      ),
      secondary: Center(
        child: FilledButton(
          onPressed: () => setState(() => _showingInbox = true),
          child: const Text('Back to inbox'),
        ),
      ),
    ),
  );
}
```

On compact layouts, `compactPane` selects the visible pane. On expanded landscape or book layouts, both panes appear side by side. Inactive compact panes remain mounted, so their local widget state is retained, but they are offstage, cannot receive focus, and do not tick animations. The same pane elements are retained when switching presentation, including from compact to book or tabletop.

## iPhone Duo

iOS does not report display features to Flutter, so `duo_scaffold` recognises iPhone Duo's inner display (951 × 669 logical pixels at 3×) and its cover display (466 × 678 in portrait), and fills in what the platform leaves out:

- **Crease.** `DuoBody` and `DuoDeviceProfile.displayFeaturesOf(context)` supply the crease at the screen centre: vertical in landscape, horizontal in portrait. Expanded landscape panes meet at the crease instead of at the middle of the remaining content area.
- **Hinge.** On iOS 27.1 and later, the package's iOS plugin observes the hinge with `UIHingeInteraction`. While the hinge is partially open the crease is half-opened, so the inner display selects `DuoLayout.book` in landscape and `DuoLayout.tabletop` in portrait; fully open, it returns to expanded landscape or portrait. On earlier iOS releases the hinge is unknown and the crease only places the split. `DuoScaffold` and `DuoBody` listen to `DuoHingeMonitor.platform` automatically; read the current reading with `DuoHingeScope.of(context)`, or wrap a subtree in `DuoHingeScope` with your own `ValueNotifier<DuoHinge?>` to simulate a posture.
- **Shared control region.** On the inner display in landscape, and always on the cover, iOS reserves a full-height strip for the camera and status bar. `DuoScaffold` places its rail inside that strip, below the status cluster, instead of beside it. The strip is on the right of the inner display. The cover rotates, and its strip follows the camera: on the right in portrait and on the left in landscape, with the rail following it to the same edge. On the cover the rail is used even though the display is narrower than `sideRailBreakpoint`, so the page gets the full height instead of an app bar and bottom bar squeezed beside the strip.

Together these give the six iPhone Duo layouts with no configuration: the cover in portrait and landscape, the inner display flat in landscape and portrait, and half-open as a book or tabletop. Detection only matches a full-screen window on iOS. On the web, an installed app (PWA) must fill the whole screen: set `apple-mobile-web-app-status-bar-style` to `black-translucent`, use `viewport-fit=cover`, and render into a host element whose height is `100lvh`, because iOS reports an installed app's viewport without the strip below the home indicator (and `screen` keeps the cover's size after unfolding). The example's `web/index.html` and `web/flutter_bootstrap.js` show the setup. `DuoScaffold` and `DuoBody` then read the browser's safe-area insets, since Flutter's web engine reports none. The hinge is not available on the web. Wrap a subtree in `DuoDeviceScope` to override detection, for example `DuoDeviceScope(profile: null, child: ...)` to disable it, or `DuoDeviceScope(profile: DuoDeviceProfile.iPhoneDuo, child: ...)` to force it (`DuoDeviceProfile.iPhoneDuoCover` for the cover). An explicit `platformLayout` or `chromeLayout` still takes precedence over the device's rail edge.

## Choose the right widget

| Need | Use |
| --- | --- |
| Adapt a primary and optional secondary pane in an existing page | `DuoBody` |
| Move declared actions and destinations between top-and-bottom controls and a physical side rail | `DuoScaffold` |
| Apply the same safe-area behaviour to a custom Scaffold slot | `DuoSafeArea` |
| Read or override device facts the platform does not report, such as iPhone Duo's crease | `DuoDeviceProfile`, `DuoDeviceScope` |

## Layout behaviour

| Available condition | Resolved layout | `DuoBody` presentation |
| --- | --- | --- |
| Width below 600 logical pixels | Compact portrait or landscape | One pane selected by `compactPane` |
| Width at least 600 and room for two 280 px panes | Expanded portrait or landscape | Two panes only in expanded landscape; expanded portrait uses the compact presentation |
| Flat or unknown-posture vertical fold, such as iPhone Duo's crease | Expanded landscape | Two panes that meet at the fold, when each side has room for a pane |
| Half-open vertical fold or hinge | Book | Two horizontal panes around the feature |
| Half-open horizontal fold or hinge | Tabletop | `tabletopTop` and `tabletopBottom`, when either is supplied |

The defaults are `expandedBreakpoint: 600` and `minimumPaneExtent: 280`. Set them directly on `DuoBody` for normal use:

```dart
DuoBody(
  expandedBreakpoint: 720,
  minimumPaneExtent: 320,
  primary: const InboxList(),
  secondary: const MessageDetail(),
)
```

`DuoLayoutPolicy` remains available when an application shares a resolver across several bodies. Use `layoutOverride` directly on `DuoBody` to force a layout for a preview or test.

```dart
const mailLayoutPolicy = DuoLayoutPolicy(
  expandedBreakpoint: 720,
  minimumPaneExtent: 320,
);

// Pass `policy: mailLayoutPolicy` to each relevant DuoBody.
```

Book and tabletop are chosen only from a half-open Flutter `DisplayFeature`. The package does not infer a fold posture from aspect ratio. If tabletop content is omitted, `DuoBody` falls back to its compact presentation.

## Safe areas and display features

`DuoBody` protects foreground panes with `SafeArea` by default. Keep a visual background outside `DuoBody` when it should extend edge to edge, and wrap a custom app bar, bottom bar, or side control in `DuoSafeArea` when it needs the same protection. Set `safeArea: false` only if the parent already applies the required insets.

`DisplayFeature.bounds` uses view coordinates. If a `DuoBody` is nested below an offset container, pass `DuoDisplayFeature` values translated into the body's local coordinate space when hinge placement must be exact.

## Adaptive side controls

`DuoScaffold` uses the supplied app bar, bottom navigation, and floating action button below 600 logical pixels. At or above 600, it uses a physical right-side rail by default. Its `left` and `right` placements stay physical in right-to-left layouts.

Use it directly as the page. Keep the selected destination in page state, then declare the actions and destinations that the host can move to the rail:

```dart
class _MailPageState extends State<MailPage> {
  String _selectedDestination = 'inbox';

  @override
  Widget build(BuildContext context) => DuoScaffold(
    actions: <DuoAction>[
      DuoAction(
        id: 'search',
        label: 'Search',
        icon: const Icon(Icons.search),
        onPressed: _openSearch,
      ),
    ],
    footerActions: <DuoAction>[
      DuoAction(
        id: 'compose',
        label: 'Compose',
        icon: const Icon(Icons.edit_outlined),
        onPressed: _compose,
      ),
    ],
    destinations: const <DuoDestination>[
      DuoDestination(
        id: 'inbox',
        label: 'Inbox',
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
      ),
      DuoDestination(
        id: 'starred',
        label: 'Starred',
        icon: Icon(Icons.star_outline),
        selectedIcon: Icon(Icons.star),
      ),
    ],
    selectedDestinationId: _selectedDestination,
    onDestinationSelected: (id) => setState(() => _selectedDestination = id),
    appBar: AppBar(
      title: Text(_selectedDestination),
      actions: <Widget>[
        IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _compose,
      child: const Icon(Icons.edit_outlined),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selectedDestination == 'inbox' ? 0 : 1,
      onDestinationSelected: (index) => setState(
        () => _selectedDestination = index == 0 ? 'inbox' : 'starred',
      ),
      destinations: const <Widget>[
        NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Inbox'),
        NavigationDestination(icon: Icon(Icons.star_outline), label: 'Starred'),
      ],
    ),
    bodyBuilder: (context, chrome) =>
        Center(child: Text('Showing $_selectedDestination')),
  );
}
```

`appBar`, `bottomNavigationBar`, and `floatingActionButton` appear in top-and-bottom mode. On a side rail, `actions` appear at the top, `footerActions` near the bottom, and `destinations` at the bottom. Supply both the horizontal widgets and the rail declarations for controls needed in both modes. A supplied `drawer` automatically gains a rail menu button and opens on the matching physical edge, including in right-to-left layouts. `leadingAction` overrides that button. Use `body` for ordinary content; use `bodyBuilder` only when it needs the resolved chrome layout and remaining content size. The optional `topAndBottomBuilder` wraps the built body inside the Material scaffold and must include it; use it for custom content arrangements.

For normal customization, set `chromeLayout` or `sideRailBreakpoint` directly on `DuoScaffold`:

```dart
DuoScaffold(
  chromeLayout: DuoChromeLayout.leftRail,
  body: const InboxPage(),
)
```

`DuoChromePolicy` remains available for sharing a policy across pages. Apart from the [iPhone Duo](#iphone-duo) profile, the package does not detect native hardware control regions.

## `DuoScaffold` properties

| Property | Type | Description |
| --- | --- | --- |
| `key` | `Key?` | Widget key passed to the underlying `StatelessWidget`. |
| `body` | `Widget?` | Page content that does not need resolved chrome information. Provide either this or `bodyBuilder`. |
| `bodyBuilder` | `Widget Function(BuildContext, DuoChromeInfo)?` | Builds page content after the scaffold chrome is resolved. `DuoChromeInfo` provides the layout, rail width, and remaining content size. Provide either this or `body`. |
| `scaffoldKey` | `GlobalKey<ScaffoldState>?` | Key used to access the underlying Material `Scaffold`, for example to open a drawer. |
| `appBar` | `PreferredSizeWidget?` | App bar shown only in `topAndBottom` layout. |
| `drawer` | `Widget?` | Drawer for the page. In rail layouts it is assigned to the matching physical edge and gets a default rail menu button unless `leadingAction` is supplied. |
| `floatingActionButton` | `Widget?` | Floating action button shown only in `topAndBottom` layout. |
| `floatingActionButtonLocation` | `FloatingActionButtonLocation?` | Position for `floatingActionButton` when it is shown. |
| `bottomNavigationBar` | `Widget?` | Bottom navigation or other bottom bar shown only in `topAndBottom` layout. |
| `bottomSheet` | `Widget?` | Persistent bottom sheet passed to the underlying Material `Scaffold` in every layout. |
| `backgroundColor` | `Color?` | Background color passed to the underlying Material `Scaffold`. |
| `resizeToAvoidBottomInset` | `bool?` | Whether the scaffold resizes its body when the on-screen keyboard appears. |
| `policy` | `DuoChromePolicy` | Resolves top-and-bottom, left-rail, or right-rail chrome. Defaults to `const DuoChromePolicy()`. |
| `chromeLayout` | `DuoChromeLayout?` | Forces the control placement. Takes precedence over `policy.layoutOverride`. |
| `sideRailBreakpoint` | `double?` | Width at which controls move to a side rail. Takes precedence over `policy.sideRailBreakpoint`. |
| `platformLayout` | `DuoChromeLayout?` | Optional application-provided platform layout passed to `policy` during resolution. Defaults to the system-region edge of a recognised `DuoDeviceProfile`, such as iPhone Duo in landscape. |
| `actions` | `List<DuoAction>` | Side-rail actions placed near the top. They are sorted by `visibilityPriority`; overflow actions move into a menu. Defaults to an empty list. |
| `leadingAction` | `DuoAction?` | First control in a side rail. Overrides the automatic drawer menu button. |
| `footerActions` | `List<DuoAction>` | Side-rail actions placed near the bottom, above destinations; suited to primary content actions. Defaults to an empty list. |
| `destinations` | `List<DuoDestination>` | Destinations rendered at the bottom of a side rail. Defaults to an empty list. |
| `selectedDestinationId` | `String?` | ID of the selected `DuoDestination`. |
| `onDestinationSelected` | `ValueChanged<String>?` | Called with a destination ID when a rail destination is selected. |
| `railWidth` | `double` | Width of the side rail, excluding any safe-area inset. Defaults to `72`; must be greater than zero. |
| `sideRailColor` | `Color?` | Background color of the side rail. Defaults to the theme's `surfaceContainer` color. |
| `maxVisibleActions` | `int` | Maximum number of top `actions` shown before an overflow menu is used. Defaults to `4`; must not be negative. |
| `topAndBottomBuilder` | `Widget Function(BuildContext, DuoChromeInfo, Widget)?` | Optionally wraps the built body in `topAndBottom` layout. The returned widget must include the supplied body. |

## Explore the Mail example

The included Mail app is the complete reference implementation. It keeps the selected mailbox, selected message, and compact-pane selection in `MailDemoPage`, then composes `DuoScaffold` and `DuoBody`.

```sh
cd example
flutter pub get
flutter run
```

To run the browser example explicitly, use `flutter run -d chrome`. See [example/README.md](example/README.md) for platform-specific commands.

It can preview all six layouts, simulated book and tabletop hinges, and top-and-bottom, left-rail, or right-rail controls. See [example/README.md](example/README.md) for a feature-to-API map.

## Development

Run the checks before opening a change:

```sh
dart format .
flutter analyze
flutter test
cd example && flutter test
```
