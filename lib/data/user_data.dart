import 'dart:developer';
import 'package:lrqm/data/management_data.dart';

/// Class to manage user-related data.
class UserData {
  static final ManagementData _managementData = ManagementData();

  /// Save user details in the shared preferences.
  static Future<bool> saveUser(Map<String, dynamic> user) async {
    log('Saving user_id: ${user['id']}');
    bool idSaved = await _managementData.saveInt('user_id', user['id']);
    log('Result of saving user_id: $idSaved');

    log('Saving username: ${user['username']}');
    bool usernameSaved = await _managementData.saveString('username', user['username']);
    log('Result of saving username: $usernameSaved');

    log('Saving bib_id: ${user['bib_id']}');
    bool bibIdSaved = await _managementData.saveString('bib_id', user['bib_id']);
    log('Result of saving bib_id: $bibIdSaved');

    log('Saving event_id: ${user['event_id']}');
    bool eventIdSaved = await _managementData.saveInt('event_id', user['event_id']);
    log('Result of saving event_id: $eventIdSaved');

    return idSaved && usernameSaved && bibIdSaved && eventIdSaved;
  }

  /// Get the user ID from the shared preferences.
  static Future<int?> getUserId() async {
    return _managementData.getInt('user_id');
  }

  /// Get the username from the shared preferences.
  static Future<String?> getUsername() async {
    return _managementData.getString('username');
  }

  /// Get the bib ID from the shared preferences.
  static Future<String?> getBibId() async {
    return _managementData.getString('bib_id');
  }

  /// Get the event ID from the shared preferences.
  static Future<int?> getEventId() async {
    return _managementData.getInt('event_id');
  }

  /// Remove all user-related data from the shared preferences.
  static Future<bool> clearUserData() async {
    bool idRemoved = await _managementData.removeData('user_id');
    bool usernameRemoved = await _managementData.removeData('username');
    bool bibIdRemoved = await _managementData.removeData('bib_id');
    bool eventIdRemoved = await _managementData.removeData('event_id');
    return idRemoved && usernameRemoved && bibIdRemoved && eventIdRemoved;
  }
}
