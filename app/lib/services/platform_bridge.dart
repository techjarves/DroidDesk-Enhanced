import 'package:flutter/services.dart';

/// Platform channel bridge to communicate with the Kotlin native layer.
///
/// All heavy work (bootstrap extraction, native pkg install, process management)
/// runs on the Kotlin side. Flutter calls into Kotlin via MethodChannel and
/// receives callbacks.
class DroidDeskPlatform {
  static const _channel = MethodChannel('com.droiddesk/core');

  // Callback handlers (set by the UI layer)
  static Function(double progress, String status)? onDownloadProgress;
  static Function(double progress, String status)? onExtractProgress;
  static Function(double progress, String status)? onInstallProgress;
  static Function(double progress, String status)? onOptionalInstallProgress;
  static Function(double progress, String status)? onPackageOperationProgress;
  static Function(String text)? onPackageOperationLog;
  static Function(String text)? onTerminalOutput;

  /// Initialize platform channel listeners
  static void init() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDownloadProgress':
          final args = call.arguments as Map;
          onDownloadProgress?.call(
            (args['progress'] as num).toDouble(),
            args['status'] as String,
          );
          break;
        case 'onExtractProgress':
          final args = call.arguments as Map;
          onExtractProgress?.call(
            (args['progress'] as num).toDouble(),
            args['status'] as String,
          );
          break;
        case 'onInstallProgress':
          final args = call.arguments as Map;
          onInstallProgress?.call(
            (args['progress'] as num).toDouble(),
            args['status'] as String,
          );
          break;
        case 'onTerminalOutput':
          final args = call.arguments as Map;
          onTerminalOutput?.call(args['text'] as String);
          break;
        case 'onOptionalInstallProgress':
          final args = call.arguments as Map;
          onOptionalInstallProgress?.call(
            (args['progress'] as num).toDouble(),
            args['status'] as String,
          );
          break;
        case 'onPackageOperationProgress':
          final args = call.arguments as Map;
          onPackageOperationProgress?.call(
            (args['progress'] as num).toDouble(),
            args['status'] as String,
          );
          break;
        case 'onPackageOperationLog':
          final args = call.arguments as Map;
          onPackageOperationLog?.call(args['text'] as String);
          break;
      }
    });
  }

  // ── Runtime Status ──

  static Future<Map<String, dynamic>> getRuntimeStatus() async {
    final result = await _channel.invokeMethod('getRuntimeStatus');
    return Map<String, dynamic>.from(result);
  }

  // ── Device Info ──

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final result = await _channel.invokeMethod('getDeviceInfo');
    return Map<String, dynamic>.from(result);
  }

  // ── Bootstrap ──

  static Future<void> setupBootstrap() async {
    await _channel.invokeMethod('setupBootstrap');
  }

  // ── Native Desktop Environment Installation (non-root fallback) ──

  static Future<bool> installDesktopNative({String de = 'xfce4'}) async {
    final result = await _channel.invokeMethod('installDesktopNative', {
      'de': de,
    });
    return result as bool? ?? false;
  }

  // ── Root / chroot support ──

  static Future<bool> checkRoot() async {
    final result = await _channel.invokeMethod('checkRoot');
    return result as bool? ?? false;
  }

  static Future<void> resetRootCache() async {
    await _channel.invokeMethod('resetRootCache');
  }

  // ── Rootfs Management (chroot mode) ──

  static Future<bool> downloadRootfs(String distro) async {
    return await _channel.invokeMethod<bool>('downloadRootfs', {
          'distro': distro,
        }) ??
        false;
  }

  static Future<bool> extractRootfs() async {
    return await _channel.invokeMethod<bool>('extractRootfs') ?? false;
  }

  static Future<bool> installDesktopEnvironment(String de) async {
    return await _channel.invokeMethod<bool>('installDesktopEnvironment', {
          'de': de,
        }) ??
        false;
  }

  static Future<Map<String, bool>> getOptionalApps() async {
    final result = await _channel.invokeMethod('getOptionalApps');
    return Map<String, bool>.from(result);
  }

  static Future<bool> installOptionalApp(String appId) async {
    return await _channel.invokeMethod<bool>('installOptionalApp', {
          'appId': appId,
        }) ??
        false;
  }

  // ── Native package store ──

  static Future<List<Map<String, dynamic>>> searchNativePackages(
    String query, {
    int limit = 60,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'searchNativePackages',
      {'query': query, 'limit': limit},
    );
    return (result ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getInstalledNativePackages() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getInstalledNativePackages',
    );
    return (result ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<bool> installNativePackage(String packageName) async {
    return await _channel.invokeMethod<bool>('installNativePackage', {
          'package': packageName,
        }) ??
        false;
  }

  static Future<bool> removeNativePackage(String packageName) async {
    return await _channel.invokeMethod<bool>('removeNativePackage', {
          'package': packageName,
        }) ??
        false;
  }

  static Future<bool> cancelNativePackageOperation() async {
    return await _channel.invokeMethod<bool>('cancelNativePackageOperation') ??
        false;
  }

  // ── Unified desktop integration ──

  static Future<List<Map<String, dynamic>>> searchDesktopItems(
    String query,
  ) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'searchDesktopItems',
      {'query': query},
    );
    return (result ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<bool> launchDesktopItem(String kind, String id) async {
    return await _channel.invokeMethod<bool>('launchDesktopItem', {
          'kind': kind,
          'id': id,
        }) ??
        false;
  }

  static Future<List<Map<String, dynamic>>> getAndroidApps() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getAndroidApps');
    return (result ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<List<String>> getDockPackages() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'getDockPackages',
    );
    return (result ?? const []).cast<String>();
  }

  static Future<bool> saveDockPackages(List<String> packages) async {
    return await _channel.invokeMethod<bool>('saveDockPackages', {
          'packages': packages,
        }) ??
        false;
  }

  static Future<List<Map<String, dynamic>>> listDesktopSnapshots() async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'listDesktopSnapshots',
    );
    return (result ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> createDesktopSnapshot() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'createDesktopSnapshot',
    );
    return Map<String, dynamic>.from(result ?? const {});
  }

  static Future<bool> restoreDesktopSnapshot(String name) async {
    return await _channel.invokeMethod<bool>('restoreDesktopSnapshot', {
          'name': name,
        }) ??
        false;
  }

  static Future<bool> deleteDesktopSnapshot(String name) async {
    return await _channel.invokeMethod<bool>('deleteDesktopSnapshot', {
          'name': name,
        }) ??
        false;
  }

  static Future<void> openAndroidControl(String action) async {
    await _channel.invokeMethod('openAndroidControl', {'action': action});
  }

  // ── Linux Session ──

  static Future<bool> startLinux({
    String de = 'xfce4',
    String mode = 'x11',
    int width = 1920,
    int height = 1080,
  }) async {
    return await _channel.invokeMethod<bool>('startLinux', {
          'de': de,
          'mode': mode,
          'width': width,
          'height': height,
        }) ??
        false;
  }

  static Future<void> stopLinux() async {
    await _channel.invokeMethod('stopLinux');
  }

  static Future<void> launchDesktopActivity() async {
    await _channel.invokeMethod('launchDesktopActivity');
  }

  static Future<String> executeCommand(String command) async {
    final result = await _channel.invokeMethod('executeCommand', {
      'command': command,
    });
    return result as String? ?? '';
  }

  static Future<void> interruptCommand() async {
    await _channel.invokeMethod('interruptCommand');
  }

  // ── Battery Optimization ──

  static Future<void> requestBatteryOptimization() async {
    await _channel.invokeMethod('requestBatteryOptimization');
  }

  static Future<bool> isBatteryOptimized() async {
    final result = await _channel.invokeMethod('isBatteryOptimized');
    return result as bool? ?? true;
  }

  static Future<void> requestDefaultLauncher() async {
    await _channel.invokeMethod('requestDefaultLauncher');
  }

  static Future<bool> unsetDefaultLauncher() async {
    return await _channel.invokeMethod<bool>('unsetDefaultLauncher') ?? false;
  }

  static Future<bool> isDefaultLauncher() async {
    return await _channel.invokeMethod<bool>('isDefaultLauncher') ?? false;
  }
}
