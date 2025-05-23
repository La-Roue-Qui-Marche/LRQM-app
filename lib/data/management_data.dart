import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

/// Class to manage the data in the shared preferences.
/// Allow to save, get, remove and check if the data exists in the shared preferences.
/// Those methods are implemented for int and string data.
class ManagementData {
  /// Singleton instance of the class.
  static final ManagementData _singleton = ManagementData._internal();

  /// Future to get the shared preferences.
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  /// Factory constructor to return the singleton instance of the class.
  factory ManagementData() {
    return _singleton;
  }

  /// Internal constructor to create the singleton instance of the class.
  ManagementData._internal();

  /// Save an integer [value] with the name [name] in the shared preferences.
  /// Return a [Future] object resolving to a boolean value indicating if the data was saved.
  Future<bool> saveInt(String name, int value) async {
    // Save the data in the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.setInt(name, value);
    return test;
  }

  /// Get an integer with the name [name] from the shared preferences.
  /// Return a [Future] object resolving to an integer value if the data was found.
  /// Return null if the data was not found.
  Future<int?> getInt(String name) async {
    // Get the data from the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.getInt(name);
    return test;
  }

  /// Save a double [value] with the name [name] in the shared preferences.
  /// Return a [Future] object resolving to a boolean value indicating if the data was saved.
  Future<bool> saveDouble(String name, double value) async {
    // Save the data in the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.setDouble(name, value);
    return test;
  }

  /// Get a double with the name [name] from the shared preferences.
  /// Return a [Future] object resolving to a double value if the data was found.
  /// Return null if the data was not found.
  Future<double?> getDouble(String name) async {
    // Get the data from the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.getDouble(name);
    return test;
  }

  /// Save a string [value] with the name [name] in the shared preferences.
  /// Return a [Future] object resolving to a boolean value indicating if the data was saved.
  Future<bool> saveString(String name, String value) async {
    // Save the data in the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.setString(name, value);
    return test;
  }

  /// Get a string with the name [name] from the shared preferences.
  /// Return a [Future] object resolving to a string value if the data was found.
  /// Return an empty string if the data was not found.
  Future<String> getString(String name) async {
    // Get the data from the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.getString(name);
    return test ?? "";
  }

  /// Remove the data with the name [name] from the shared preferences.
  /// Return a [Future] object resolving to a boolean value indicating if the data was removed.
  Future<bool> removeData(String name) async {
    // Remove the data from the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.remove(name);
    return test;
  }

  /// Check if the data with the name [name] exists in the shared preferences.
  /// Return a [Future] object resolving to a boolean value indicating if the data exists or not.
  Future<bool> doesDataExist(String name) async {
    // Check if the data exists in the shared preferences
    final SharedPreferences prefs = await _prefs;

    var test = prefs.containsKey(name);
    log('doesDataExist: $test');
    return test;
  }
}
