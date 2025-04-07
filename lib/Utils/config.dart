import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:package_info_plus/package_info_plus.dart'; // Ensure this import is present

/// Class to manage the configuration of the application.
class Config {
  // ------------------- Version----------------
  static String _appVersion = 'Unknown';
  // ------------------- API -------------------
  static const String API_URL = 'api.la-rqm.dynv6.net';
  static const String API_COMMON_ADDRESS = '/app/measures/';
  // -------------- EVENT DATA ----------------
  static const String EVENT_NAME = 'TEST';
  static const String START_TIME = '2024-01-25 17:00:00';
  static const String END_TIME = '2025-06-22 17:00:00';
  // ----------------- QR code -----------------
  static const String QR_CODE_S_VALUE = 'Ready';
  static const String QR_CODE_F_VALUE = 'Stop';
  // ------------- Zone Evènement --------------
  // static const double LAT1 = 46.62094732231268;
  // static const double LON1 = 6.71095185969227;
  // static const double LAT2 = 46.60796048493062;
  // static const double LON2 = 6.7304699219465105;

  // ------------- Further Expanded Zone Lac Léman to Include Martigny --------------
  static const double LAT1 = 46.6000; // North-East latitude (expanded)
  static const double LON1 = 7.1000; // North-East longitude (expanded to include Martigny)
  static const double LAT2 = 46.1000; // South-West latitude (unchanged)
  static const double LON2 = 5.9000; // South-West longitude (unchanged)

  static final List<mp.LatLng> ZONE_EVENT = [
    mp.LatLng(LAT1, LON1),
    mp.LatLng(LAT2, LON1),
    mp.LatLng(LAT2, LON2),
    mp.LatLng(LAT1, LON2),
  ];

  // ----------------- Couleurs -----------------
  static const int COLOR_APP_BAR = 0xFF403c74;
  static const int COLOR_BUTTON = 0xFFFF9900;
  static const int COLOR_TITRE = 0xFFFFFFFF;
  static const int COLOR_BACKGROUND = 0xFFF0F0F0;
  // ----------------- Constantes -----------------

  /// Function to get the application version.
  static Future<String> getAppVersion() async {
    if (_appVersion == 'Unknown') {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    }
    return _appVersion;
  }
}
