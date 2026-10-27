/// Registers the package on platforms without a native implementation.
///
/// Only iOS reports the hinge. Elsewhere the layout comes from Flutter's
/// `DisplayFeature` data, so there is nothing to register. Flutter calls
/// [registerWith] with no argument on Android, macOS, Windows, and Linux,
/// and with a plugin registrar on the web.
class DuoScaffoldPlugin {
  DuoScaffoldPlugin._();

  /// Does nothing; Flutter calls this when the app starts.
  static void registerWith([Object? registrar]) {}
}
