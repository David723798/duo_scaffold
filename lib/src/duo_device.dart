import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'duo_chrome.dart';
import 'duo_layout.dart';

/// Layout facts for hardware that Flutter does not describe on its own.
///
/// iOS does not report display features to Flutter, so a book-style iPhone
/// cannot expose its crease through [MediaQueryData.displayFeatures]. A
/// profile supplies that crease and identifies the screen edge where the
/// system status region becomes a shared control region.
@immutable
class DuoDeviceProfile {
  const DuoDeviceProfile({
    required this.name,
    required this.landscapeSize,
    required this.devicePixelRatio,
    this.platform = TargetPlatform.iOS,
    this.creaseWidth,
    this.systemStatusExtent = 0,
  }) : assert(creaseWidth == null || creaseWidth >= 0),
       assert(systemStatusExtent >= 0);

  /// The inner display of iPhone Duo.
  ///
  /// The display is two cover-sized halves joined by a vertical crease in
  /// landscape. In landscape, iOS reserves a full-height strip on one side
  /// for the status bar; the status cluster uses only its top portion.
  static const DuoDeviceProfile iPhoneDuo = DuoDeviceProfile(
    name: 'iPhone Duo',
    landscapeSize: Size(951, 669),
    devicePixelRatio: 3,
    creaseWidth: 0,
    systemStatusExtent: 104,
  );

  /// The cover display of iPhone Duo.
  ///
  /// The cover stays in portrait, and iOS reserves a full-height strip on its
  /// right for the camera and a stacked status cluster.
  static const DuoDeviceProfile iPhoneDuoCover = DuoDeviceProfile(
    name: 'iPhone Duo cover',
    landscapeSize: Size(678, 466),
    devicePixelRatio: 3,
    systemStatusExtent: 160,
  );

  /// Profiles recognised by [detect].
  static const List<DuoDeviceProfile> knownProfiles = <DuoDeviceProfile>[
    iPhoneDuo,
    iPhoneDuoCover,
  ];

  final String name;

  /// Full-screen logical size with the longer side horizontal.
  final Size landscapeSize;
  final double devicePixelRatio;
  final TargetPlatform platform;

  /// Width of the crease or hinge between the two display halves, or `null`
  /// for a display without one.
  final double? creaseWidth;

  /// Extent of the system status cluster at the top of a side system region.
  ///
  /// Side-rail controls sharing that region start below this extent.
  final double systemStatusExtent;

  /// Returns the profile in scope, or a detected profile for a full-screen
  /// window on known hardware.
  ///
  /// A [DuoDeviceScope] overrides detection, including disabling it.
  static DuoDeviceProfile? of(BuildContext context) {
    final DuoDeviceScope? scope = context
        .dependOnInheritedWidgetOfExactType<DuoDeviceScope>();
    if (scope != null) return scope.profile;
    return detect(MediaQuery.of(context));
  }

  /// Matches [data] against [knownProfiles].
  static DuoDeviceProfile? detect(
    MediaQueryData data, {
    TargetPlatform? platform,
  }) {
    final TargetPlatform current = platform ?? defaultTargetPlatform;
    for (final DuoDeviceProfile profile in knownProfiles) {
      if (profile.platform == current && profile.matches(data)) return profile;
    }
    return null;
  }

  /// Display features from [MediaQuery], or this device's crease when the
  /// platform reports none.
  static Iterable<DuoDisplayFeature> displayFeaturesOf(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    if (data.displayFeatures.isNotEmpty) {
      return data.displayFeatures.map(DuoDisplayFeature.fromDisplayFeature);
    }
    return of(context)?.displayFeatures(data.size) ??
        const <DuoDisplayFeature>[];
  }

  /// Whether [data] describes this device's full screen.
  bool matches(MediaQueryData data) {
    final Size size = data.size;
    final Size longFirst = size.width >= size.height ? size : size.flipped;
    return (data.devicePixelRatio - devicePixelRatio).abs() < 0.01 &&
        (longFirst.width - landscapeSize.width).abs() < 1 &&
        (longFirst.height - landscapeSize.height).abs() < 1;
  }

  /// The crease in screen coordinates.
  ///
  /// The posture is reported as unknown because Flutter cannot read the hinge
  /// angle on iOS. [DuoLayoutPolicy] uses such a crease to place the split of
  /// an expanded landscape layout, not to select book or tabletop.
  List<DuoDisplayFeature> displayFeatures(Size screenSize) {
    final double? creaseWidth = this.creaseWidth;
    if (creaseWidth == null) return const <DuoDisplayFeature>[];
    final bool landscape = screenSize.width >= screenSize.height;
    final Rect bounds = landscape
        ? Rect.fromLTWH(
            (screenSize.width - creaseWidth) / 2,
            0,
            creaseWidth,
            screenSize.height,
          )
        : Rect.fromLTWH(
            0,
            (screenSize.height - creaseWidth) / 2,
            screenSize.width,
            creaseWidth,
          );
    return <DuoDisplayFeature>[
      DuoDisplayFeature(
        bounds: bounds,
        type: creaseWidth > 0
            ? DisplayFeatureType.hinge
            : DisplayFeatureType.fold,
        state: DisplayFeatureState.unknown,
      ),
    ];
  }

  /// The rail on the edge that holds the system region, when the system
  /// places its status bar at the side rather than the top.
  ///
  /// [DuoScaffold] uses this even below its side-rail breakpoint, so a narrow
  /// display with a side system region, such as the iPhone Duo cover, keeps
  /// its controls in that region instead of adding top and bottom bars.
  DuoChromeLayout? chromeLayout(MediaQueryData data) {
    final EdgeInsets padding = data.viewPadding;
    if (padding.top > 0) return null;
    if (padding.right > padding.left) return DuoChromeLayout.rightRail;
    if (padding.left > padding.right) return DuoChromeLayout.leftRail;
    return null;
  }

  @override
  String toString() => 'DuoDeviceProfile($name)';
}

/// Overrides [DuoDeviceProfile] detection for a subtree.
///
/// Supply a profile to preview a device elsewhere, or `null` to disable
/// device-specific behaviour.
class DuoDeviceScope extends InheritedWidget {
  const DuoDeviceScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final DuoDeviceProfile? profile;

  @override
  bool updateShouldNotify(DuoDeviceScope oldWidget) =>
      profile != oldWidget.profile;
}
