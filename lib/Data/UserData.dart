import 'DataManagement.dart';
import 'dart:developer'; // Add this for logging

/// Class to manage user-related data.
class UserData {
  /// Singleton instance of the DataManagement class.
  static final DataManagement _dataManagement = DataManagement();

  /// Save user details in the shared preferences.
  static Future<bool> saveUser(Map<String, dynamic> user) async {
    log('Saving user_id: ${user['id']}');
    bool idSaved = await _dataManagement.saveInt('user_id', user['id']);
    log('Result of saving user_id: $idSaved');

    log('Saving username: ${user['username']}');
    bool usernameSaved = await _dataManagement.saveString('username', user['username']);
    log('Result of saving username: $usernameSaved');

    log('Saving bib_id: ${user['bib_id']}');
    bool bibIdSaved = await _dataManagement.saveString('bib_id', user['bib_id']);
    log('Result of saving bib_id: $bibIdSaved');

    log('Saving event_id: ${user['event_id']}');
    bool eventIdSaved = await _dataManagement.saveInt('event_id', user['event_id']);
    log('Result of saving event_id: $eventIdSaved');

    return idSaved && usernameSaved && bibIdSaved && eventIdSaved;
  }

  /// Get the user ID from the shared preferences.
  static Future<int?> getUserId() async {
    return _dataManagement.getInt('user_id');
  }

  /// Get the username from the shared preferences.
  static Future<String?> getUsername() async {
    return _dataManagement.getString('username');
  }

  /// Get the bib ID from the shared preferences.
  static Future<String?> getBibId() async {
    return _dataManagement.getString('bib_id');
  }

  /// Get the event ID from the shared preferences.
  static Future<int?> getEventId() async {
    return _dataManagement.getInt('event_id');
  }

  /// Remove all user-related data from the shared preferences.
  static Future<bool> clearUserData() async {
    bool idRemoved = await _dataManagement.removeData('user_id');
    bool usernameRemoved = await _dataManagement.removeData('username');
    bool bibIdRemoved = await _dataManagement.removeData('bib_id');
    bool eventIdRemoved = await _dataManagement.removeData('event_id');
    return idRemoved && usernameRemoved && bibIdRemoved && eventIdRemoved;
  }
}
