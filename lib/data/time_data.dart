import 'package:lrqm/data/management_data.dart';

/// Class to manage the time spent on the track.
class TimeData {
  static final ManagementData _managementData = ManagementData();

  /// Save the session time [sessionTime] in the shared preferences
  static Future<bool> saveSessionTime(int sessionTime) async {
    return _managementData.saveInt('sessionTime', sessionTime);
  }

  /// Get the session time from the shared preferences
  static Future<int> getSessionTime() async {
    final result = await _managementData.getInt('sessionTime');
    return result is int ? result : 0; // Ensure it always returns an int
  }

  /// Remove the time spent on the track from the shared preferences
  static Future<bool> removeTime() async {
    return _managementData.removeData('sessionTime');
  }

  /// Check if the time spent on the track exists in the shared preferences
  Future<bool> doesTimeExist() async {
    return _managementData.doesDataExist('sessionTime');
  }
}
