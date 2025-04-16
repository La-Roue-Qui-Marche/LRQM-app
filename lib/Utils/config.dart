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
  // ------------- Zone Evènement --------------
  // static const double LAT1 = 46.62094732231268;
  // static const double LON1 = 6.71095185969227;
  // static const double LAT2 = 46.60796048493062;
  // static const double LON2 = 6.7304699219465105;

  // ------------- Further Expanded Zone Lac Léman to Include Martigny --------------
  static const double LAT1 = 46.8000; // North-East latitude (expanded)
  static const double LON1 = 6.9000; // North-East longitude (expanded to include Martigny)
  static const double LAT2 = 46.4500; // South-West latitude (unchanged)
  static const double LON2 = 6.4000; // South-West longitude (unchanged)

  static final List<mp.LatLng> ZONE_EVENT = [
    mp.LatLng(LAT1, LON1),
    mp.LatLng(LAT2, LON1),
    mp.LatLng(LAT2, LON2),
    mp.LatLng(LAT1, LON2),
  ];

  /// Rassemblement point (point de rassemblement) of the event zone (raw values)
  static const double RASSEMBLEMENT_LAT = 46.625; // example: center of the zone, adjust as needed
  static const double RASSEMBLEMENT_LON = 6.65; // example: center of the zone, adjust as needed
  static final mp.LatLng RASSEMBLEMENT_POINT = mp.LatLng(RASSEMBLEMENT_LAT, RASSEMBLEMENT_LON);

  // For flutter_map convenience
  static final LatLng RASSEMBLEMENT_POINT_FLUTTER = LatLng(RASSEMBLEMENT_LAT, RASSEMBLEMENT_LON);

  // ----------------- Geolocation Config -----------------
  static const Duration LOCATION_UPDATE_INTERVAL = Duration(seconds: 5);
  static const int LOCATION_DISTANCE_FILTER = 5;
  static const int MAX_CHUNK_SIZE = 40;
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

  /// Function to get the application version.
  static Future<String> getAppVersion() async {
    if (_appVersion == 'Unknown') {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    }
    return _appVersion;
  }
}
