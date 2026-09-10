import 'package:flutter/widgets.dart';

/// Applies platform safe-area insets to foreground Duo content.
///
/// Use this around custom controls supplied to a `Scaffold` slot, such as a
/// custom top, bottom, or side bar. `DuoBody` applies the same protection by
/// default. Backgrounds can remain outside this widget to draw edge-to-edge.
class DuoSafeArea extends StatelessWidget {
  const DuoSafeArea({
    super.key,
    required this.child,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  });

  final Widget child;
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;
  final EdgeInsets minimum;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) => SafeArea(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    minimum: minimum,
    maintainBottomViewPadding: maintainBottomViewPadding,
    child: child,
  );
}
