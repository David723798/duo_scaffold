import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@JS('document')
external _Document get _document;

@JS('getComputedStyle')
external _Style _getComputedStyle(_Element element);

extension type _Document._(JSObject _) implements JSObject {
  external _Element? get body;
  external _Element createElement(String tag);
}

extension type _Element._(JSObject _) implements JSObject {
  external _Style get style;
  external void append(_Element child);
}

extension type _Style._(JSObject _) implements JSObject {
  external String getPropertyValue(String name);
  external void setProperty(String name, String value);
}

@JS('ResizeObserver')
extension type _ResizeObserver._(JSObject _) implements JSObject {
  external factory _ResizeObserver(JSFunction callback);
  external void observe(_Element target);
}

const List<String> _sides = <String>['left', 'top', 'right', 'bottom'];

ValueNotifier<EdgeInsets>? _insets;

/// The CSS `env(safe-area-inset-*)` values in logical pixels.
///
/// Each side is the width of a hidden element sized by that inset, so a
/// `ResizeObserver` reports when iOS changes it, which happens after the
/// viewport resizes.
ValueListenable<EdgeInsets>? safeAreaInsets() {
  final ValueNotifier<EdgeInsets>? existing = _insets;
  if (existing != null) return existing;
  final _Element? body = _document.body;
  if (body == null) return null;
  final List<_Element> probes = <_Element>[
    for (final String side in _sides) _probe(body, side),
  ];
  final ValueNotifier<EdgeInsets> insets = _insets = ValueNotifier<EdgeInsets>(
    _read(probes),
  );
  final _ResizeObserver observer = _ResizeObserver(
    ((JSAny? entries, JSAny? observer) {
      insets.value = _read(probes);
    }).toJS,
  );
  for (final _Element probe in probes) {
    observer.observe(probe);
  }
  return insets;
}

_Element _probe(_Element body, String side) {
  final _Element probe = _document.createElement('flt-duo-safe-area');
  final _Style style = probe.style;
  style.setProperty('position', 'fixed');
  style.setProperty('top', '0');
  style.setProperty('left', '0');
  style.setProperty('height', '1px');
  style.setProperty('visibility', 'hidden');
  style.setProperty('pointer-events', 'none');
  style.setProperty('width', 'env(safe-area-inset-$side, 0px)');
  body.append(probe);
  return probe;
}

EdgeInsets _read(List<_Element> probes) {
  final List<double> values = <double>[
    for (final _Element probe in probes)
      double.tryParse(
            _getComputedStyle(
              probe,
            ).getPropertyValue('width').replaceAll('px', ''),
          ) ??
          0,
  ];
  return EdgeInsets.fromLTRB(values[0], values[1], values[2], values[3]);
}
