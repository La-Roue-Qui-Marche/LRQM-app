import 'DataManagement.dart';

/// Class to manage the total distance traveled by the user during the session.
class SessionDistanceData {
  /// Singleton instance of the DataManagement class.
  static final DataManagement _dataManagement = DataManagement();

  /// Save the total distance [totalDistance] for the session in the shared preferences.
  static Future<bool> saveTotalDistance(int totalDistance) async {
    return _dataManagement.saveInt('totalDistance', totalDistance);
  }

  /// Get the total distance for the session from the shared preferences.
  static Future<int?> getTotalDistance() async {
    return _dataManagement.getInt('totalDistance');
  }

  /// Remove the total distance for the session from the shared preferences.
  static Future<bool> resetTotalDistance() async {
    return _dataManagement.removeData('totalDistance');
  }

  /// Check if the total distance for the session exists in the shared preferences.
  static Future<bool> doesTotalDistanceExist() async {
    return _dataManagement.doesDataExist('totalDistance');
  }
}
