import 'dart:ui';

import 'package:flutter/widgets.dart';

/// The six layouts supported by [DuoLayoutPolicy].
enum DuoLayout {
  compactPortrait,
  compactLandscape,
  expandedLandscape,
  expandedPortrait,
  book,
  tabletop,
}

/// The pane that should be shown while only one pane can be visible.
enum DuoPane { primary, secondary }

/// The arrangement available to a pair of panes.
///
/// This is deliberately separate from [DuoLayout].  A posture describes the
/// device; a presentation describes what content can actually be shown.
enum DuoPanePresentation { compact, horizontal, vertical }

/// A display feature in the coordinate space of the widget being laid out.
@immutable
class DuoDisplayFeature {
  const DuoDisplayFeature({
    required this.bounds,
    required this.type,
    required this.state,
  });

  factory DuoDisplayFeature.fromDisplayFeature(DisplayFeature feature) =>
      DuoDisplayFeature(
        bounds: feature.bounds,
        type: feature.type,
        state: feature.state,
      );

  final Rect bounds;
  final DisplayFeatureType type;
  final DisplayFeatureState state;
}

/// The resolved layout and the fold that caused it, if any.
@immutable
class DuoLayoutInfo {
  const DuoLayoutInfo({
    required this.layout,
    required this.size,
    this.foldBounds,
  });

  final DuoLayout layout;
  final Size size;

  /// Bounds of the fold or hinge in local layout coordinates.
  ///
  /// For book and tabletop this is the half-open feature that selected the
  /// layout. For expanded landscape it is a flat or unknown-posture vertical
  /// fold that the two panes should meet at, such as iPhone Duo's crease.
  final Rect? foldBounds;

  DuoPanePresentation get presentation => switch (layout) {
    DuoLayout.expandedLandscape ||
    DuoLayout.book => DuoPanePresentation.horizontal,
    DuoLayout.tabletop => DuoPanePresentation.vertical,
    _ => DuoPanePresentation.compact,
  };

  bool get hasTwoPanes => presentation != DuoPanePresentation.compact;
}

/// Resolves display size and posture into one of [DuoLayout]'s six layouts.
@immutable
class DuoLayoutPolicy {
  const DuoLayoutPolicy({
    this.expandedBreakpoint = 600,
    this.minimumPaneExtent = 280,
    this.layoutOverride,
  }) : assert(expandedBreakpoint > 0),
       assert(minimumPaneExtent > 0);

  final double expandedBreakpoint;
  final double minimumPaneExtent;
  final DuoLayout? layoutOverride;

  DuoLayoutInfo resolve(
    Size size, {
    Iterable<DuoDisplayFeature> displayFeatures = const <DuoDisplayFeature>[],
  }) {
    if (!size.width.isFinite || !size.height.isFinite || size.isEmpty) {
      return DuoLayoutInfo(layout: DuoLayout.compactPortrait, size: size);
    }
    DuoDisplayFeature? vertical;
    DuoDisplayFeature? horizontal;
    DuoDisplayFeature? flatVertical;
    for (final DuoDisplayFeature feature in displayFeatures) {
      if (feature.type != DisplayFeatureType.fold &&
          feature.type != DisplayFeatureType.hinge) {
        continue;
      }
      final Rect bounds = feature.bounds.intersect(Offset.zero & size);
      // A feature must span the usable viewport. A small cutout or a feature
      // outside a nested body is not a two-pane boundary.
      final bool spansHeight =
          bounds.height >= size.height && bounds.width < size.width;
      final bool spansWidth =
          bounds.width >= size.width && bounds.height < size.height;
      if (feature.state != DisplayFeatureState.postureHalfOpened) {
        if (spansHeight &&
            feature.bounds.left >= 0 &&
            feature.bounds.right <= size.width) {
          flatVertical ??= feature;
        }
        continue;
      }
      if (spansHeight) vertical ??= feature;
      if (spansWidth) horizontal ??= feature;
    }
    final DuoDisplayFeature? postureFeature = vertical ?? horizontal;
    if (layoutOverride != null) {
      return DuoLayoutInfo(
        layout: layoutOverride!,
        size: size,
        foldBounds: postureFeature?.bounds,
      );
    }
    if (vertical != null) {
      return DuoLayoutInfo(
        layout: DuoLayout.book,
        size: size,
        foldBounds: vertical.bounds,
      );
    }
    if (horizontal != null) {
      return DuoLayoutInfo(
        layout: DuoLayout.tabletop,
        size: size,
        foldBounds: horizontal.bounds,
      );
    }
    final bool canExpand =
        size.width >= expandedBreakpoint && size.width >= minimumPaneExtent * 2;
    final DuoLayout layout = canExpand
        ? (size.width >= size.height
              ? DuoLayout.expandedLandscape
              : DuoLayout.expandedPortrait)
        : (size.width >= size.height
              ? DuoLayout.compactLandscape
              : DuoLayout.compactPortrait);
    // A flat crease does not change the posture, but panes that meet at it
    // avoid content straddling the fold.
    final Rect? crease = flatVertical?.bounds;
    final bool alignToCrease =
        layout == DuoLayout.expandedLandscape &&
        crease != null &&
        crease.left >= minimumPaneExtent &&
        size.width - crease.right >= minimumPaneExtent;
    return DuoLayoutInfo(
      layout: layout,
      size: size,
      foldBounds: alignToCrease ? crease : null,
    );
  }
}
