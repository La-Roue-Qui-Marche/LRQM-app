import 'package:package_info_plus/package_info_plus.dart';

/// Class to manage the configuration of the application.
class Config {
  // ------------------- Version----------------
  static String _appVersion = 'Unknown';

  // ------------------- API -------------------
  static const String apiUrl = 'api.la-rqm.dynv6.net';

  // ----------------- QR code -----------------
  static const String qrCodeStartContent = 'Ready';

  // ------------- POS FALLBACK --------------
  static const double defaultLat1 = 46.62094732231268;
  static const double defaultLon1 = 6.71095185969227;

  // ----------------- Geolocation Config -----------------
  static const int locationDistanceFilter = 3;
  static const double accuracyThreshold = 30;
  static const int distanceThreshold = 60;
  static const double speedThreshold = 12;
  static const Duration apiInterval = Duration(seconds: 10);
  static const int outsideCounterMax = 2;

  // ----------------- Couleurs -----------------
  static const int primaryColor = 0xFF403c74;
  static const int accentColor = 0xFFFF9900;
  static const int backgroundColor = 0xFFF2F2F7;
  // ----------------- Constantes -----------------

  // ----------------- Confirmation Code Secret Key & Prime -----------------
  static const int confirmationSecretKey = 21062025;
  static const int confirmationPrime = 7919;
  static const String confirmationPrefixLetter = 'C';

  /// Function to get the application version.
  static Future<String> getAppVersion() async {
    if (_appVersion == 'Unknown') {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    }
    return _appVersion;
  }
}
