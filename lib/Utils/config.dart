import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:package_info_plus/package_info_plus.dart'; // Ensure this import is present
import 'package:latlong2/latlong.dart'; // <-- Add this import

/// Class to manage the configuration of the application.
class Config {
  // ------------------- Version----------------
  static String _appVersion = 'Unknown';

  // ------------------- API -------------------
  static const String API_URL = 'api.la-rqm.dynv6.net';
  static const String API_COMMON_ADDRESS = '/app/measures/';

  // ----------------- QR code -----------------
  static const String QR_CODE_S_VALUE = 'Ready';
  static const String QR_CODE_F_VALUE = 'Stop';

  // ------------- POS FALLBACK --------------
  static const double DEFAULT_LAT1 = 46.62094732231268;
  static const double DEFAULT_LON1 = 6.71095185969227;

  // ----------------- Geolocation Config -----------------
  static const Duration LOCATION_UPDATE_INTERVAL = Duration(seconds: 5);
  static const int LOCATION_DISTANCE_FILTER = 5;
  static const int MAX_CHUNK_SIZE = 200;
  static const double ACCURACY_THRESHOLD = 20;
  static const int DISTANCE_THRESHOLD = 40;
  static const double SPEED_THRESHOLD = 10;
  static const Duration API_INTERVAL = Duration(seconds: 10);
  static const int OUTSIDE_COUNTER_MAX = 5;

  // ----------------- Couleurs -----------------
  static const int COLOR_APP_BAR = 0xFF403c74;
  static const int COLOR_BUTTON = 0xFFFF9900;
  static const int COLOR_TITRE = 0xFFFFFFFF;
  static const int COLOR_BACKGROUND = 0xFFF2F2F7;
  // ----------------- Constantes -----------------

  // ----------------- Confirmation Code Secret Key & Prime -----------------
  static const int CONFIRMATION_SECRET_KEY = 21062025;
  static const int CONFIRMATION_PRIME = 7919;

  /// Function to get the application version.
  static Future<String> getAppVersion() async {
    if (_appVersion == 'Unknown') {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    }
    return _appVersion;
  }
}
