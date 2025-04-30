import 'package:lrqm/data/management_data.dart';

/// Class to manage the number of participants.
class ContributorsData {
  static final ManagementData _managementData = ManagementData();

  /// Save the number of contributors [contributors] in the shared preferences.
  static Future<bool> saveContributors(int contributors) async {
    return _managementData.saveInt('contributors', contributors);
  }

  /// Get the number of contributors from the shared preferences.
  static Future<int?> getContributors() async {
    return _managementData.getInt('contributors');
  }

  /// Remove the number of contributors from the shared preferences.
  static Future<bool> removeContributors() async {
    return _managementData.removeData('contributors');
  }

  /// Check if the number of contributors exists in the shared preferences.
  static Future<bool> doesContributorsExist() async {
    return _managementData.doesDataExist('contributors');
  }
}
