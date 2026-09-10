import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'duo_layout.dart';
import 'duo_safe_area.dart';

/// Lays out primary and secondary content using a [DuoLayout].
///
/// Inactive compact content remains mounted offstage, preserving local state.
class DuoBody extends StatelessWidget {
  const DuoBody({
    super.key,
    required this.primary,
    this.secondary,
    this.layout,
    this.policy = const DuoLayoutPolicy(),
    this.expandedBreakpoint,
    this.minimumPaneExtent,
    this.layoutOverride,
    this.displayFeatures,
    this.compactPane = DuoPane.primary,
    this.tabletopTop,
    this.tabletopBottom,
    this.safeArea = true,
    this.safeAreaLeft = true,
    this.safeAreaTop = true,
    this.safeAreaRight = true,
    this.safeAreaBottom = true,
    this.safeAreaMinimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  }) : assert(expandedBreakpoint == null || expandedBreakpoint > 0),
       assert(minimumPaneExtent == null || minimumPaneExtent > 0);

  final Widget primary;
  final Widget? secondary;
  final DuoLayoutInfo? layout;

  /// Advanced layout resolver. Direct layout settings override this policy.
  final DuoLayoutPolicy policy;

  /// Width at which a layout can show expanded content.
  final double? expandedBreakpoint;

  /// Minimum extent required for each pane in an expanded layout.
  final double? minimumPaneExtent;

  /// Forces a layout, primarily for previews and tests.
  final DuoLayout? layoutOverride;
  final Iterable<DuoDisplayFeature>? displayFeatures;
  final DuoPane compactPane;
  final Widget? tabletopTop;
  final Widget? tabletopBottom;

  /// Whether foreground pane content avoids platform safe areas.
  final bool safeArea;
  final bool safeAreaLeft;
  final bool safeAreaTop;
  final bool safeAreaRight;
  final bool safeAreaBottom;
  final EdgeInsets safeAreaMinimum;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final EdgeInsets insets = _safeInsets(mediaQuery);
    final Iterable<DuoDisplayFeature> features =
        displayFeatures ??
        mediaQuery.displayFeatures.map(DuoDisplayFeature.fromDisplayFeature);
    final Widget content = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Iterable<DuoDisplayFeature> localFeatures = features.map(
          (DuoDisplayFeature feature) => _translate(feature, insets),
        );
        final Rect? localFold = layout?.foldBounds == null
            ? null
            : _translateBounds(layout!.foldBounds!, insets);
        // A page-level layout can select a posture, but the body must use its
        // own constraints after Scaffold, keyboard, and safe-area adjustments.
        final DuoLayoutInfo resolved = layout == null
            ? _resolvedPolicy.resolve(
                constraints.biggest,
                displayFeatures: localFeatures,
              )
            : DuoLayoutInfo(
                layout: layout!.layout,
                size: constraints.biggest,
                foldBounds: localFold,
              );
        return _buildLayout(resolved);
      },
    );
    if (!safeArea) return content;
    return DuoSafeArea(
      left: safeAreaLeft,
      top: safeAreaTop,
      right: safeAreaRight,
      bottom: safeAreaBottom,
      minimum: safeAreaMinimum,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: content,
    );
  }

  DuoLayoutPolicy get _resolvedPolicy => DuoLayoutPolicy(
    expandedBreakpoint: expandedBreakpoint ?? policy.expandedBreakpoint,
    minimumPaneExtent: minimumPaneExtent ?? policy.minimumPaneExtent,
    layoutOverride: layoutOverride ?? policy.layoutOverride,
  );

  EdgeInsets _safeInsets(MediaQueryData mediaQuery) {
    if (!safeArea) return EdgeInsets.zero;
    final EdgeInsets padding = mediaQuery.padding;
    final double bottomInset = maintainBottomViewPadding
        ? mediaQuery.viewPadding.bottom
        : padding.bottom;
    return EdgeInsets.fromLTRB(
      safeAreaLeft ? math.max(padding.left, safeAreaMinimum.left) : 0,
      safeAreaTop ? math.max(padding.top, safeAreaMinimum.top) : 0,
      safeAreaRight ? math.max(padding.right, safeAreaMinimum.right) : 0,
      safeAreaBottom ? math.max(bottomInset, safeAreaMinimum.bottom) : 0,
    );
  }

  DuoDisplayFeature _translate(DuoDisplayFeature feature, EdgeInsets insets) =>
      DuoDisplayFeature(
        bounds: _translateBounds(feature.bounds, insets),
        type: feature.type,
        state: feature.state,
      );

  Rect _translateBounds(Rect bounds, EdgeInsets insets) => Rect.fromLTWH(
    bounds.left - insets.left,
    bounds.top - insets.top,
    bounds.width,
    bounds.height,
  );

  Widget _buildLayout(DuoLayoutInfo resolved) => switch (resolved.layout) {
    DuoLayout.book || DuoLayout.expandedLandscape => _split(
      resolved,
      Axis.horizontal,
      primary,
      secondary,
    ),
    DuoLayout.tabletop => _tabletop(resolved),
    _ => _compact(),
  };

  Widget _compact() {
    if (secondary == null) return primary;
    final bool showPrimary = compactPane == DuoPane.primary;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(
          child: _DuoPane(visible: showPrimary, child: primary),
        ),
        Positioned.fill(
          child: _DuoPane(visible: !showPrimary, child: secondary!),
        ),
      ],
    );
  }

  Widget _tabletop(DuoLayoutInfo info) {
    if (tabletopTop == null && tabletopBottom == null) return _compact();
    return _split(info, Axis.vertical, tabletopTop ?? primary, tabletopBottom);
  }

  Widget _split(DuoLayoutInfo info, Axis axis, Widget first, Widget? second) {
    if (second == null) return first;
    final double extent = axis == Axis.horizontal
        ? info.size.width
        : info.size.height;
    final Rect? fold = info.foldBounds;
    final double start = axis == Axis.horizontal
        ? fold?.left ?? extent / 2
        : fold?.top ?? extent / 2;
    final double gap = axis == Axis.horizontal
        ? fold?.width ?? 0
        : fold?.height ?? 0;
    final bool valid = start > 0 && start + gap < extent;
    final double firstExtent = valid ? start : extent / 2;
    final double effectiveGap = valid ? gap : 0;

    // Keep both panes under one stable Stack. Switching between compact,
    // book, and tabletop presentations therefore does not re-parent a pane
    // and lose its Element, scroll position, or text-field state.
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          width: axis == Axis.horizontal ? firstExtent : null,
          height: axis == Axis.vertical ? firstExtent : null,
          right: axis == Axis.horizontal ? null : 0,
          bottom: axis == Axis.horizontal ? 0 : null,
          child: _DuoPane(visible: true, child: first),
        ),
        Positioned(
          left: axis == Axis.horizontal ? firstExtent + effectiveGap : 0,
          top: axis == Axis.vertical ? firstExtent + effectiveGap : 0,
          right: 0,
          bottom: 0,
          child: _DuoPane(visible: true, child: second),
        ),
      ],
    );
  }
}

class _DuoPane extends StatelessWidget {
  const _DuoPane({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !visible,
    child: TickerMode(
      enabled: visible,
      child: ExcludeFocus(excluding: !visible, child: child),
    ),
  );
}
