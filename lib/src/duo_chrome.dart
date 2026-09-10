import 'package:flutter/material.dart';

/// Where adaptive application controls are displayed.
///
/// [DuoChromeLayout.leftRail] and [DuoChromeLayout.rightRail] are physical
/// display edges. They deliberately do not change in right-to-left layouts
/// because iPhone Duo's shared control region follows the hardware edge.
enum DuoChromeLayout { topAndBottom, leftRail, rightRail }

/// Selects an adaptive layout for application controls.
///
/// A wide viewport uses a physical right rail by default. This is a Flutter
/// layout decision, not detection of an iPhone Duo system control region.
/// Applications can inject a verified platform value through
/// [platformLayout], or force a value with [layoutOverride].
@immutable
class DuoChromePolicy {
  const DuoChromePolicy({this.layoutOverride, this.sideRailBreakpoint = 600})
    : assert(sideRailBreakpoint > 0);

  final DuoChromeLayout? layoutOverride;
  final double sideRailBreakpoint;

  DuoChromeLayout resolve({Size? size, DuoChromeLayout? platformLayout}) {
    if (layoutOverride != null) return layoutOverride!;
    if (platformLayout != null) return platformLayout;
    if (size == null ||
        !size.width.isFinite ||
        size.width < sideRailBreakpoint) {
      return DuoChromeLayout.topAndBottom;
    }
    return DuoChromeLayout.rightRail;
  }
}

/// Resolved information for an adaptive control region.
@immutable
class DuoChromeInfo {
  const DuoChromeInfo({
    required this.layout,
    required this.railWidth,
    required this.contentSize,
  });

  final DuoChromeLayout layout;
  final double railWidth;
  final Size contentSize;

  bool get hasSideRail => layout != DuoChromeLayout.topAndBottom;
}

/// Assigns one application drawer to the matching official Scaffold slot.
///
/// Rail layouts follow physical edges using the supplied text direction.
/// Top-and-bottom controls use the logical start drawer.
@immutable
class DuoDrawerSlots {
  const DuoDrawerSlots({this.drawer, this.endDrawer});

  factory DuoDrawerSlots.forLayout({
    required DuoChromeLayout layout,
    Widget? drawer,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final bool useEndDrawer = layout == DuoChromeLayout.topAndBottom
        ? false
        : (layout == DuoChromeLayout.rightRail) ==
              (textDirection == TextDirection.ltr);
    return DuoDrawerSlots(
      drawer: useEndDrawer ? null : drawer,
      endDrawer: useEndDrawer ? drawer : null,
    );
  }

  final Widget? drawer;
  final Widget? endDrawer;
}

/// A drawer button that follows the physical edge of [layout].
///
/// Pair it with [DuoDrawerSlots.forLayout] when supplying a drawer to an
/// official [Scaffold].
class DuoDrawerButton extends StatelessWidget {
  const DuoDrawerButton({
    super.key,
    required this.layout,
    this.tooltip = 'Open navigation',
    this.icon = const Icon(Icons.menu),
  });

  final DuoChromeLayout layout;
  final String tooltip;
  final Widget icon;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton(
      onPressed: () {
        final ScaffoldState? scaffold = Scaffold.maybeOf(context);
        if (layout != DuoChromeLayout.topAndBottom &&
            (layout == DuoChromeLayout.rightRail) ==
                (Directionality.of(context) == TextDirection.ltr)) {
          scaffold?.openEndDrawer();
        } else {
          scaffold?.openDrawer();
        }
      },
      icon: icon,
    ),
  );
}

/// A compact action that can be shown in a side control region.
@immutable
class DuoAction {
  const DuoAction({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.visibilityPriority = 0,
    this.sideBuilder,
  });

  final String id;
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  /// Larger values remain visible before lower-priority actions overflow.
  final int visibilityPriority;

  /// Builds a side-rail-specific representation, such as a menu button.
  ///
  /// When omitted, the rail uses a standard [IconButton]. This lets an app
  /// move an AppBar menu to the rail without losing its menu semantics.
  final Widget Function(BuildContext context)? sideBuilder;
}

/// A destination for [DuoScaffold]'s side navigation.
@immutable
class DuoDestination {
  const DuoDestination({
    required this.id,
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
  });

  final String id;
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? badge;
}

/// A complete Material page with adaptive actions and navigation.
///
/// Use directly as a page, with no enclosing [Scaffold]. [appBar],
/// [bottomNavigationBar], and [floatingActionButton] appear in top-and-bottom
/// mode; rail modes use the declared actions and destinations instead.
/// [drawer] follows the physical rail edge automatically.
class DuoScaffold extends StatelessWidget {
  const DuoScaffold({
    super.key,
    this.body,
    this.bodyBuilder,
    this.scaffoldKey,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.policy = const DuoChromePolicy(),
    this.chromeLayout,
    this.sideRailBreakpoint,
    this.platformLayout,
    this.actions = const <DuoAction>[],
    this.leadingAction,
    this.footerActions = const <DuoAction>[],
    this.destinations = const <DuoDestination>[],
    this.selectedDestinationId,
    this.onDestinationSelected,
    this.railWidth = 72,
    this.sideRailColor,
    this.maxVisibleActions = 4,
    this.topAndBottomBuilder,
  }) : assert(body != null || bodyBuilder != null),
       assert(body == null || bodyBuilder == null),
       assert(railWidth > 0),
       assert(sideRailBreakpoint == null || sideRailBreakpoint > 0),
       assert(maxVisibleActions >= 0);

  /// Page content when it does not need resolved chrome information.
  final Widget? body;

  /// Builds page content with the space remaining after scaffold chrome.
  final Widget Function(BuildContext context, DuoChromeInfo info)? bodyBuilder;

  /// Optional key for accessing the underlying Material scaffold state.
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  /// Advanced chrome resolver. Direct chrome settings override this policy.
  final DuoChromePolicy policy;

  /// Forces the control placement, primarily for previews and platform input.
  final DuoChromeLayout? chromeLayout;

  /// Width at which controls move to a side rail.
  final double? sideRailBreakpoint;

  final DuoChromeLayout? platformLayout;
  final List<DuoAction> actions;

  /// The navigation or drawer control placed first in a side rail.
  final DuoAction? leadingAction;

  /// Actions kept at the bottom of a side rail, above destinations.
  ///
  /// Use this for primary content actions such as Compose. [actions] remains
  /// the top group for controls that normally appear in an AppBar.
  final List<DuoAction> footerActions;
  final List<DuoDestination> destinations;
  final String? selectedDestinationId;
  final ValueChanged<String>? onDestinationSelected;
  final double railWidth;

  /// Background color for a side control rail.
  ///
  /// Defaults to the current theme's `surfaceContainer` color.
  final Color? sideRailColor;
  final int maxVisibleActions;

  /// Builds the caller's top and bottom controls around [body].
  final Widget Function(BuildContext context, DuoChromeInfo info, Widget body)?
  topAndBottomBuilder;

  @override
  Widget build(BuildContext context) {
    assert(() {
      _validateActionIds(actions, 'actions');
      _validateActionIds(footerActions, 'footerActions');
      _validateDestinationIds(destinations);
      if (selectedDestinationId != null &&
          !destinations.any(
            (DuoDestination item) => item.id == selectedDestinationId,
          )) {
        throw ArgumentError.value(
          selectedDestinationId,
          'selectedDestinationId',
          'must identify an item in destinations',
        );
      }
      return true;
    }());
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final DuoChromeLayout layout = _resolvedPolicy.resolve(
          size: constraints.biggest,
          platformLayout: platformLayout,
        );
        final bool horizontal = layout == DuoChromeLayout.topAndBottom;
        final DuoDrawerSlots slots = DuoDrawerSlots.forLayout(
          layout: layout,
          drawer: drawer,
          textDirection: Directionality.of(context),
        );
        return Scaffold(
          key: scaffoldKey,
          appBar: horizontal ? (appBar ?? _automaticAppBar()) : null,
          drawer: slots.drawer,
          endDrawer: slots.endDrawer,
          floatingActionButton: horizontal ? floatingActionButton : null,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: horizontal
              ? (bottomNavigationBar ?? _automaticNavigation())
              : null,
          bottomSheet: bottomSheet,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints bodyConstraints) =>
                _buildBody(context, bodyConstraints, layout),
          ),
        );
      },
    );
  }

  DuoChromePolicy get _resolvedPolicy => DuoChromePolicy(
    layoutOverride: chromeLayout ?? policy.layoutOverride,
    sideRailBreakpoint: sideRailBreakpoint ?? policy.sideRailBreakpoint,
  );

  /// Creates compact controls from the same declarations used by a rail.
  /// Supply [appBar] or [bottomNavigationBar] when the application needs a
  /// richer Material arrangement.
  PreferredSizeWidget? _automaticAppBar() {
    if (actions.isEmpty && leadingAction == null) return null;
    return AppBar(
      leading: leadingAction == null
          ? null
          : _CompactActionButton(action: leadingAction!),
      actions: <Widget>[
        for (final DuoAction action in actions)
          _CompactActionButton(action: action),
      ],
    );
  }

  Widget? _automaticNavigation() {
    if (destinations.isEmpty) return null;
    final int selectedIndex = destinations.indexWhere(
      (DuoDestination item) => item.id == selectedDestinationId,
    );
    return NavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: onDestinationSelected == null
          ? null
          : (int index) => onDestinationSelected!(destinations[index].id),
      destinations: destinations
          .map(
            (DuoDestination item) => NavigationDestination(
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
            ),
          )
          .toList(growable: false),
    );
  }

  static void _validateActionIds(Iterable<DuoAction> items, String name) {
    final Set<String> ids = <String>{};
    for (final DuoAction item in items) {
      if (!ids.add(item.id)) {
        throw ArgumentError.value(item.id, name, 'contains duplicate IDs');
      }
    }
  }

  static void _validateDestinationIds(Iterable<DuoDestination> items) {
    final Set<String> ids = <String>{};
    for (final DuoDestination item in items) {
      if (!ids.add(item.id)) {
        throw ArgumentError.value(
          item.id,
          'destinations',
          'contains duplicate IDs',
        );
      }
    }
  }

  Widget _buildBody(
    BuildContext context,
    BoxConstraints constraints,
    DuoChromeLayout layout,
  ) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double edgeInset = layout == DuoChromeLayout.leftRail
        ? padding.left
        : layout == DuoChromeLayout.rightRail
        ? padding.right
        : 0;
    final DuoChromeInfo info = DuoChromeInfo(
      layout: layout,
      railWidth: railWidth,
      contentSize: layout == DuoChromeLayout.topAndBottom
          ? constraints.biggest
          : Size(
              (constraints.maxWidth - railWidth - edgeInset).clamp(
                0,
                double.infinity,
              ),
              constraints.maxHeight,
            ),
    );
    final Widget body = this.body ?? bodyBuilder!(context, info);
    if (layout == DuoChromeLayout.topAndBottom) {
      return topAndBottomBuilder?.call(context, info, body) ?? body;
    }
    final Widget rail = _DuoSideRail(
      width: railWidth,
      layout: layout,
      actions: actions,
      leadingAction:
          leadingAction ??
          (drawer == null
              ? null
              : DuoAction(
                  id: 'open-drawer',
                  icon: const Icon(Icons.menu),
                  label: 'Open navigation',
                  onPressed: null,
                  sideBuilder: (BuildContext context) =>
                      DuoDrawerButton(layout: layout),
                )),
      footerActions: footerActions,
      destinations: destinations,
      selectedDestinationId: selectedDestinationId,
      onDestinationSelected: onDestinationSelected,
      color: sideRailColor,
      maxVisibleActions: maxVisibleActions,
    );
    // The child keeps the inherited text direction. `left` and `right` are
    // expressed by the order of this Row, so they remain physical edges.
    final Widget content = MediaQuery.removePadding(
      context: context,
      removeLeft: layout == DuoChromeLayout.leftRail,
      removeRight: layout == DuoChromeLayout.rightRail,
      child: body,
    );
    return Row(
      textDirection: TextDirection.ltr,
      children: layout == DuoChromeLayout.leftRail
          ? <Widget>[rail, Expanded(child: content)]
          : <Widget>[Expanded(child: content), rail],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({required this.action});

  final DuoAction action;

  @override
  Widget build(BuildContext context) =>
      action.sideBuilder?.call(context) ??
      Tooltip(
        message: action.label,
        child: IconButton(
          onPressed: action.enabled ? action.onPressed : null,
          icon: action.icon,
        ),
      );
}

class _DuoSideRail extends StatelessWidget {
  const _DuoSideRail({
    required this.width,
    required this.layout,
    required this.actions,
    required this.leadingAction,
    required this.footerActions,
    required this.destinations,
    required this.selectedDestinationId,
    required this.onDestinationSelected,
    required this.color,
    required this.maxVisibleActions,
  });

  final double width;
  final DuoChromeLayout layout;
  final List<DuoAction> actions;
  final DuoAction? leadingAction;
  final List<DuoAction> footerActions;
  final List<DuoDestination> destinations;
  final String? selectedDestinationId;
  final ValueChanged<String>? onDestinationSelected;
  final Color? color;
  final int maxVisibleActions;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double edgeInset = layout == DuoChromeLayout.leftRail
        ? padding.left
        : padding.right;
    final List<DuoAction> sorted = List<DuoAction>.of(actions)
      ..sort(
        (DuoAction a, DuoAction b) =>
            b.visibilityPriority.compareTo(a.visibilityPriority),
      );
    final int visibleCount = sorted.length.clamp(0, maxVisibleActions);
    final List<DuoAction> visible = sorted.take(visibleCount).toList();
    final List<DuoAction> overflow = sorted.skip(visibleCount).toList();
    final List<Widget> topControls = <Widget>[
      if (leadingAction != null) _actionButton(context, leadingAction!),
      for (final DuoAction action in visible) _actionButton(context, action),
      if (overflow.isNotEmpty) _overflowButton(overflow),
    ];
    final List<Widget> bottomControls = <Widget>[
      for (final DuoAction action in footerActions)
        _actionButton(context, action),
      for (final DuoDestination destination in destinations)
        _destinationButton(context, destination),
    ];

    return SizedBox(
      width: width + edgeInset,
      child: SafeArea(
        left: layout == DuoChromeLayout.leftRail,
        right: layout == DuoChromeLayout.rightRail,
        child: SizedBox(
          width: width,
          child: Material(
            color: color ?? Theme.of(context).colorScheme.surfaceContainer,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Keep footer controls at the physical bottom where there is
                // room. On a short rail, every control remains reachable.
                final bool fits =
                    constraints.maxHeight >=
                    (topControls.length + bottomControls.length) * 48;
                if (fits) {
                  return Column(
                    children: <Widget>[
                      ...topControls,
                      const Spacer(),
                      ...bottomControls,
                    ],
                  );
                }
                return CustomScrollView(
                  slivers: <Widget>[
                    SliverList(delegate: SliverChildListDelegate(topControls)),
                    SliverList(
                      delegate: SliverChildListDelegate(bottomControls),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, DuoAction action) =>
      action.sideBuilder?.call(context) ??
      Tooltip(
        message: action.label,
        child: IconButton(
          onPressed: action.enabled ? action.onPressed : null,
          icon: action.icon,
        ),
      );

  Widget _overflowButton(List<DuoAction> overflow) => PopupMenuButton<String>(
    tooltip: 'More actions',
    icon: const Icon(Icons.more_horiz),
    onSelected: (String id) {
      final DuoAction action = overflow.firstWhere(
        (DuoAction action) => action.id == id,
      );
      if (action.enabled) action.onPressed?.call();
    },
    itemBuilder: (BuildContext context) => overflow
        .map(
          (DuoAction action) => PopupMenuItem<String>(
            value: action.id,
            enabled: action.enabled && action.onPressed != null,
            child: Text(action.label),
          ),
        )
        .toList(growable: false),
  );

  Widget _destinationButton(BuildContext context, DuoDestination destination) {
    final bool selected = destination.id == selectedDestinationId;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          onTap: onDestinationSelected == null
              ? null
              : () => onDestinationSelected!(destination.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Badge(
                isLabelVisible: destination.badge != null,
                label: Text(destination.badge ?? ''),
                child: IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  child: selected
                      ? (destination.selectedIcon ?? destination.icon)
                      : destination.icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
