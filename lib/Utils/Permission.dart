import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Utils/LogHelper.dart';

class PermissionHelper {
  // ----------------------------
  // LOCATION PERMISSION
  // ----------------------------
  static Future<bool> requestLocationPermission() async {
    if (await Permission.locationAlways.status.isGranted) return true;

    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isGranted) {
      LogHelper.logInfo("[PERMISSION] Location whileInUse permission granted: $status");
      var alwaysStatus = await Permission.locationAlways.request();
      if (alwaysStatus.isGranted) {
        LogHelper.logInfo("[PERMISSION] Location always permission granted $alwaysStatus");
        return true;
      } else {
        LogHelper.logInfo("[PERMISSION] Location always permission refuse $alwaysStatus");
        return false;
      }
    }

    LogHelper.logError("[PERMISSION] Unexpected permission state: $status");
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
