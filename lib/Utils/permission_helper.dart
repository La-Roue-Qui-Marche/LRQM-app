import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:lrqm/utils/log_helper.dart';

class PermissionHelper {
  // ----------------------------
  // LOCATION PERMISSION
  // ----------------------------

  /// Check if proper location permission is granted based on platform
  static Future<bool> isProperLocationPermissionGranted() async {
    if (Platform.isIOS) {
      return isLocationAlwaysGranted();
    } else {
      // For Android, when in use permission is sufficient due to foreground service
      return isLocationWhenInUseGranted();
    }
  }

  /// Check if location when in use permission is granted
  static Future<bool> isLocationWhenInUseGranted() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Check if location always permission is granted
  static Future<bool> isLocationAlwaysGranted() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  /// Request proper location permission based on platform
  static Future<bool> requestProperLocationPermission() async {
    if (Platform.isIOS) {
      return requestLocationAlwaysPermission();
    } else {
      // For Android, when in use permission is sufficient due to foreground service
      return requestLocationWhenInUsePermission();
    }
  }

  /// Request location permission when app is active (while in use)
  static Future<bool> requestLocationWhenInUsePermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    }
    status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      return true;
    }
    LogHelper.logError("[PERMISSION] Location whileInUse permission not granted: $status");
    return false;
  }

  /// Request location permission for always access
  static Future<bool> requestLocationAlwaysPermission() async {
    var status = await Permission.locationAlways.status;
    if (status.isGranted) {
      return true;
    }
    // First, ensure "when in use" is granted
    if (!await PermissionHelper.requestLocationWhenInUsePermission()) {
      LogHelper.logError("[PERMISSION] Cannot request always permission without whileInUse permission.");
      return false;
    }
    status = await Permission.locationAlways.request();
    if (status.isGranted) {
      return true;
    }
    LogHelper.logError("[PERMISSION] Location always permission not granted: $status");
    return false;
  }

  static Future<void> openLocationSettings() async {
    LogHelper.logInfo("[PERMISSION] Opening location settings...");
    final success = await Geolocator.openLocationSettings();
    if (!success) {
      LogHelper.logError("[PERMISSION] Failed to open location settings.");
    }
  }

  // ----------------------------
  // CAMERA PERMISSION
  // ----------------------------
  static Future<bool> requestCameraPermission() async {
    LogHelper.logInfo("[PERMISSION] Requesting camera permission...");
    final status = await Permission.camera.request();
    if (status.isGranted) {
      LogHelper.logInfo("[PERMISSION] Camera permission granted.");
      return true;
    } else if (status.isDenied) {
      LogHelper.logWarn("[PERMISSION] Camera permission denied.");
      return false;
    } else if (status.isPermanentlyDenied) {
      LogHelper.logError("[PERMISSION] Camera permission permanently denied. Please enable it in settings.");
      return false;
    }
    LogHelper.logError("[PERMISSION] Unknown camera permission status: $status");
    return false;
  }

  static Future<void> openCameraSettings() async {
    LogHelper.logInfo("[PERMISSION] Opening settings...");
    final success = await openAppSettings();
    if (!success) {
      LogHelper.logError("[PERMISSION] Failed to open settings.");
    }
  }
}
