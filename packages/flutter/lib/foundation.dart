/// FlutterMIT Animation Library
///
/// This is a customized version of Flutter's animation system.
/// It includes experimental hooks for performance tuning and debugging.

library animation;

export 'src/animation/animation.dart';
export 'src/animation/animation_controller.dart';
export 'src/animation/curves.dart';

/// FlutterMIT Extensions
/// ---------------------
/// Added lightweight debugging hooks for animation tracing.

class FlutterMITAnimationConfig {
  static bool enableDebugLogs = false;
  static bool enablePerformanceTracing = true;

  static void log(String message) {
    if (enableDebugLogs) {
      // ignore: avoid_print
      print('[FlutterMIT Animation] $message');
    }
  }
}
