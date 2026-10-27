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
