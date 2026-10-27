import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The platform reports its own insets outside the web.
ValueListenable<EdgeInsets>? safeAreaInsets() => null;
