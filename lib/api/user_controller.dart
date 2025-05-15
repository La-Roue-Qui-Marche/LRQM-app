import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:lrqm/utils/Result.dart';
import 'package:lrqm/utils/config.dart';

class UserController {
  static final http.Client _client = http.Client(); // Reusable HTTP client

  /// Create a new user.
  static Future<Result<bool>> createUser(String username, String bibId, int eventId) async {
    final uri = Uri.https(Config.apiUrl, '/users');
    final body = {
      "username": username,
      "bib_id": bibId,
      "event_id": eventId,
    };

    debugPrint('[createUser] POST $uri');
    debugPrint('[createUser] Body: $body');

    return _client.post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      debugPrint('[createUser] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[createUser] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }

  /// Get a user by ID.
  static Future<Result<Map<String, dynamic>>> getUser(int userId) async {
    final uri = Uri.https(Config.apiUrl, '/users/$userId');

    debugPrint('[getUser] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getUser] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<Map<String, dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getUser] Error: $error');
      return Result<Map<String, dynamic>>(error: error.toString());
    });
  }

  /// Retrieve all users.
  static Future<Result<List<dynamic>>> getAllUsers() async {
    final uri = Uri.https(Config.apiUrl, '/users/');

    debugPrint('[getAllUsers] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getAllUsers] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<List<dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getAllUsers] Error: $error');
      return Result<List<dynamic>>(error: error.toString());
    });
  }

  /// Edit a user by ID.
  static Future<Result<bool>> editUser(int userId, Map<String, dynamic> updates) async {
    final uri = Uri.https(Config.apiUrl, '/users/$userId');
    final body = jsonEncode(updates);

    debugPrint('[editUser] PATCH $uri');
    debugPrint('[editUser] Body: $updates');

    return _client.patch(uri, body: body, headers: {"Content-Type": "application/json"}).then((response) {
      debugPrint('[editUser] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to edit user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[editUser] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }

  /// Get the total meters contributed by a user.
  static Future<Result<int>> getUserTotalMeters(int userId) async {
    final uri = Uri.https(Config.apiUrl, '/users/$userId/meters');

    debugPrint('[getUserTotalMeters] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getUserTotalMeters] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<int>(value: jsonDecode(response.body)['meters']);
      } else {
        throw Exception('Failed to fetch total meters: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getUserTotalMeters] Error: $error');
      return Result<int>(error: error.toString());
    });
  }

  /// Get the total time spent by a user.
  static Future<Result<int>> getUserTotalTime(int userId) async {
    final uri = Uri.https(Config.apiUrl, '/users/$userId/time');

    debugPrint('[getUserTotalTime] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getUserTotalTime] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final timeString = jsonDecode(response.body)['time'];
        final time = double.tryParse(timeString)?.toInt() ?? 0; // Convert to int
        return Result<int>(value: time);
      } else {
        throw Exception('Failed to fetch total time: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getUserTotalTime] Error: $error');
      return Result<int>(error: error.toString());
    });
  }

  /// Login a user by bib_id and event_id.
  static Future<Result<Map<String, dynamic>>> login(String bibId, int eventId) async {
    final uri = Uri.https(Config.apiUrl, '/login');
    final body = {
      "bib_id": bibId,
      "event_id": eventId,
    };

    debugPrint('[login] POST $uri');
    debugPrint('[login] Body: $body');

    return _client.post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      debugPrint('[login] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<Map<String, dynamic>>(value: jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return Result<Map<String, dynamic>>(error: "User not found");
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[login] Error: $error');
      return Result<Map<String, dynamic>>(error: error.toString());
    });
  }
}
