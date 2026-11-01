import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

/// Directory containing the native vodozemac library.
///
/// On macOS the Flutter plugin ships `flutter_vodozemac.framework` under
/// `Contents/Frameworks`, which is not on the default `./` search path when
/// launching a packaged `.app`.
String vodozemacLibraryPath() {
  if (kIsWeb || !Platform.isMacOS) return './';
  final parts = Platform.resolvedExecutable.split('/');
  final bundle = parts.lastIndexWhere((part) => part.endsWith('.app'));
  if (bundle == -1) return './';
  return '${parts.sublist(0, bundle + 1).join('/')}/Contents/Frameworks/';
}

/// Dynamic library stem used by flutter_vodozemac.
///
/// Apple builds embed `flutter_vodozemac`; Linux/Windows/Android embed
/// `vodozemac_bindings_dart`. Calling [vod.init] with the wrong stem makes the
/// bundled library look "missing".
String vodozemacStem() {
  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
    return 'flutter_vodozemac';
  }
  return 'vodozemac_bindings_dart';
}

/// Load the already-bundled vodozemac native library with platform-correct paths.
Future<void> initVodozemac({
  String wasmPath = './assets/assets/vodozemac/',
}) {
  return vod.init(
    wasmPath: wasmPath,
    libraryPath: vodozemacLibraryPath(),
    stem: vodozemacStem(),
  );
}
