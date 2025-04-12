import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Utils/Result.dart';
import '../Utils/config.dart';

class NewUserController {
  static final http.Client _client = http.Client(); // Reusable HTTP client

  /// Create a new user.
  static Future<Result<bool>> createUser(String username, String bibId, int eventId) async {
    final uri = Uri.https(Config.API_URL, '/users');
    final body = {
      "username": username,
      "bib_id": bibId,
      "event_id": eventId,
    };

    return _client.post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      return Result<bool>(error: error.toString());
    });
  }

  /// Get a user by ID.
  static Future<Result<Map<String, dynamic>>> getUser(int userId) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId');

    return _client.get(uri).then((response) {
      if (response.statusCode == 200) {
        return Result<Map<String, dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      return Result<Map<String, dynamic>>(error: error.toString());
    });
  }

  /// Retrieve all users.
  static Future<Result<List<dynamic>>> getAllUsers() async {
    final uri = Uri.https(Config.API_URL, '/users/');

    return _client.get(uri).then((response) {
      if (response.statusCode == 200) {
        return Result<List<dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      return Result<List<dynamic>>(error: error.toString());
    });
  }

  /// Edit a user by ID.
  static Future<Result<bool>> editUser(int userId, Map<String, dynamic> updates) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId');
    final body = jsonEncode(updates);

    return _client.patch(uri, body: body, headers: {"Content-Type": "application/json"}).then((response) {
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to edit user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      return Result<bool>(error: error.toString());
    });
  }

  /// Get the total meters contributed by a user.
  static Future<Result<int>> getUserTotalMeters(int userId) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId/meters');

    return _client.get(uri).then((response) {
      if (response.statusCode == 200) {
        return Result<int>(value: jsonDecode(response.body)['meters']);
      } else {
        throw Exception('Failed to fetch total meters: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      return Result<int>(error: error.toString());
    });
  }

  /// Get the total time spent by a user.
  static Future<Result<int>> getUserTotalTime(int userId) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId/time');

    return _client.get(uri).then((response) {
      if (response.statusCode == 200) {
        final timeString = jsonDecode(response.body)['time'];
        final time = double.tryParse(timeString)?.toInt() ?? 0; // Convert to int
        return Result<int>(value: time);
      } else {
        throw Exception('Failed to fetch total time: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      return Result<int>(error: error.toString());
    });
  }
}
