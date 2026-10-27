import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The status of a device hinge, as reported by `UIHinge` on iOS 27.1 and
/// later.
enum DuoHingeStatus { unknown, closed, partiallyOpen, fullyOpen }

/// A snapshot of a device hinge.
@immutable
class DuoHinge {
  const DuoHinge({required this.status, this.angle});

  final DuoHingeStatus status;

  /// The hinge angle in radians, when the platform reports one.
  ///
  /// The rate and precision of angle updates are system policy. Prefer
  /// [status] for choosing a posture.
  final double? angle;

  /// The posture this hinge gives a fold that crosses it.
  ///
  /// A partially open hinge is half-opened, which selects book or tabletop;
  /// a fully open hinge is flat.
  DisplayFeatureState get displayFeatureState => switch (status) {
    DuoHingeStatus.partiallyOpen => DisplayFeatureState.postureHalfOpened,
    DuoHingeStatus.fullyOpen => DisplayFeatureState.postureFlat,
    _ => DisplayFeatureState.unknown,
  };

  @override
  bool operator ==(Object other) =>
      other is DuoHinge && other.status == status && other.angle == angle;

  @override
  int get hashCode => Object.hash(status, angle);

  @override
  String toString() => 'DuoHinge(${status.name}, angle: $angle)';
}

/// Hinge updates from the platform.
///
/// On iOS, the package's plugin observes the Flutter view with a
/// `UIHingeInteraction`. Updates start when the first listener is added and
/// stop when the last is removed. The value stays `null` on other platforms,
/// on iOS releases before 27.1, and on devices without a hinge.
class DuoHingeMonitor extends ValueNotifier<DuoHinge?> {
  DuoHingeMonitor._() : super(null);

  /// The shared monitor that [DuoScaffold] and [DuoBody] use when no
  /// [DuoHingeScope] is in scope.
  static final DuoHingeMonitor platform = DuoHingeMonitor._();

  static const MethodChannel _channel = MethodChannel('duo_scaffold/hinge');

  bool _started = false;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (!_started) _start();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_started && !hasListeners) _stop();
  }

  void _start() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _started = true;
    _channel.setMethodCallHandler(_handle);
    _invoke('start');
  }

  void _stop() {
    _started = false;
    _invoke('stop');
    _channel.setMethodCallHandler(null);
    value = null;
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Tests, and apps that have not rebuilt since adding the package.
    } on PlatformException {
      // The view is not available yet; the value stays unknown.
    }
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method != 'hingeChanged') return;
    final Map<Object?, Object?>? hinge =
        call.arguments as Map<Object?, Object?>?;
    if (hinge == null) {
      value = null;
      return;
    }
    final int status = hinge['status'] as int? ?? 0;
    value = DuoHinge(
      status: status >= 0 && status < DuoHingeStatus.values.length
          ? DuoHingeStatus.values[status]
          : DuoHingeStatus.unknown,
      angle: (hinge['angle'] as num?)?.toDouble(),
    );
  }
}

/// Supplies hinge state to [DuoDeviceProfile.displayFeaturesOf].
///
/// [DuoScaffold] and [DuoBody] insert one with [DuoHingeMonitor.platform]
/// when none is in scope. Provide a scope to simulate a posture, for example
/// `DuoHingeScope(notifier: ValueNotifier(DuoHinge(status:
/// DuoHingeStatus.partiallyOpen)), child: ...)`.
class DuoHingeScope extends InheritedNotifier<ValueListenable<DuoHinge?>> {
  const DuoHingeScope({
    super.key,
    required ValueListenable<DuoHinge?> super.notifier,
    required super.child,
  });

  /// The hinge in scope, or `null` when it is unknown or no scope exists.
  static DuoHinge? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DuoHingeScope>()
      ?.notifier
      ?.value;

  /// Wraps [child] in a platform hinge scope unless one is already in scope.
  static Widget ensure(BuildContext context, WidgetBuilder builder) {
    if (context.getInheritedWidgetOfExactType<DuoHingeScope>() != null) {
      return builder(context);
    }
    return DuoHingeScope(
      notifier: DuoHingeMonitor.platform,
      child: Builder(builder: builder),
    );
  }
}
