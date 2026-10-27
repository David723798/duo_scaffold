import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'duo_web_insets_stub.dart'
    if (dart.library.js_interop) 'duo_web_insets_web.dart'
    as platform;

/// Supplies the browser's safe-area insets to [MediaQuery] on the web.
///
/// Flutter's web engine always reports zero padding, so a page that extends
/// under the iOS status bar, such as an installed web app with
/// `viewport-fit=cover`, cannot see the status strip it shares with the
/// system. The insets come from the CSS `env(safe-area-inset-*)` values.
///
/// [DuoScaffold] and [DuoBody] insert the insets once, at the outermost of
/// them, so a page that removes padding for its body is not given it again.
class _DuoWebInsetsScope extends InheritedWidget {
  const _DuoWebInsetsScope({required super.child});

  @override
  bool updateShouldNotify(_DuoWebInsetsScope oldWidget) => false;
}

/// Wraps [builder] in the browser's safe-area insets on the web, unless an
/// outer [DuoScaffold] or [DuoBody] already supplied them.
///
/// iOS updates the insets after the viewport resizes, for example when the
/// device rotates, so the subtree rebuilds when they change.
Widget ensureWebInsets(BuildContext context, WidgetBuilder builder) {
  if (context.getInheritedWidgetOfExactType<_DuoWebInsetsScope>() != null) {
    return builder(context);
  }
  final ValueListenable<EdgeInsets>? insets = platform.safeAreaInsets();
  if (insets == null) return builder(context);
  final Widget child = _DuoWebInsetsScope(child: Builder(builder: builder));
  return ValueListenableBuilder<EdgeInsets>(
    valueListenable: insets,
    child: child,
    builder: (BuildContext context, EdgeInsets insets, Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      // Keep the MediaQuery in place either way, so the subtree keeps its
      // state when the insets change to or from zero.
      if (insets == EdgeInsets.zero || data.viewPadding != EdgeInsets.zero) {
        return MediaQuery(data: data, child: child!);
      }
      final EdgeInsets keyboard = data.viewInsets;
      return MediaQuery(
        data: data.copyWith(
          viewPadding: insets,
          padding: EdgeInsets.fromLTRB(
            math.max(0, insets.left - keyboard.left),
            math.max(0, insets.top - keyboard.top),
            math.max(0, insets.right - keyboard.right),
            math.max(0, insets.bottom - keyboard.bottom),
          ),
        ),
        child: child!,
      );
    },
  );
}
