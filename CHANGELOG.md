## 0.3.2

* Declare Android, web, macOS, Windows, and Linux as supported plugin
  platforms again. Since 0.3.0 the package declared only iOS, so pub.dev
  listed it as iOS-only although layout works everywhere. These platforms
  register a no-op `DuoScaffoldPlugin`; the hinge is still read only on iOS.

## 0.3.1

* On the web, `DuoScaffold` and `DuoBody` read the browser's safe-area insets
  (`env(safe-area-inset-*)`), which Flutter's web engine does not report, and
  follow them as they change, including after rotation. An installed web app
  on iPhone Duo with `viewport-fit=cover` now detects the device, meets its
  panes at the crease, and places the rail in the status strip.
* The example web app fills the whole screen when installed, including the
  status strip and the strip below the home indicator (`100lvh`), stays
  correct when iPhone Duo unfolds, and allows landscape.

## 0.3.0

* Detect iPhone Duo's book and tabletop postures from the hinge. The package
  is now an iOS plugin that observes `UIHingeInteraction` (iOS 27.1 and
  later) and reports it through `DuoHingeMonitor.platform`. A partially open
  hinge makes the crease half-opened, so the inner display selects
  `DuoLayout.book` in landscape and `DuoLayout.tabletop` in portrait.
* Add `DuoHinge`, `DuoHingeStatus`, and `DuoHingeScope`. `DuoScaffold` and
  `DuoBody` supply a platform hinge scope when none is in scope.
* `DuoDeviceProfile.displayFeatures` takes an optional `hinge`.

## 0.2.0

* Add iPhone Duo support through `DuoDeviceProfile` and `DuoDeviceScope`.
  On iOS, the inner display's crease is supplied to `DuoBody`, and in
  landscape `DuoScaffold` places its rail inside the side status-bar strip.
  The cover display (`DuoDeviceProfile.iPhoneDuoCover`) uses the same rail
  in its right-hand strip, even below `sideRailBreakpoint`.
* Expanded landscape panes meet at a flat or unknown-posture vertical fold.
* Side-rail backgrounds now extend under the safe-area insets; controls
  still avoid them.

## 0.1.0

* Initial release.
