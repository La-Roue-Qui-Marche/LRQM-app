import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'; // ADD THIS
import '../Utils/LogHelper.dart';

class PermissionHelper {
  static Future<bool> handlePermission() async {
    final GeolocatorPlatform geoPlatform = GeolocatorPlatform.instance;
    if (!await geoPlatform.isLocationServiceEnabled()) {
      LogHelper.logError("[PERMISSION] Location services are disabled.");
      return false;
    }
    LocationPermission permission = await geoPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await geoPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        LogHelper.logError("[PERMISSION] Location permission denied by user.");
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      LogHelper.logError("[PERMISSION] Location permission permanently denied.");
      return false;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      LogHelper.logWarn("[PERMISSION] Location permission granted: $permission");
      return true;
    }

    LogHelper.logError("[PERMISSION] Unexpected permission state: $permission");
    return false;
  }

  static Future<bool> checkPermissionAlways() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  static Future<LocationPermission> requestLocationPermission() async {
    LogHelper.logInfo("[PERMISSION] Requesting location permission...");
    final permission = await Geolocator.requestPermission();
    LogHelper.logInfo("[PERMISSION] User responded with: $permission");
    return permission;
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
}
