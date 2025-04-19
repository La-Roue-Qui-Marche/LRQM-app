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

    print('[createUser] POST $uri');
    print('[createUser] Body: $body');

    return _client.post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      print('[createUser] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[createUser] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }

  /// Get a user by ID.
  static Future<Result<Map<String, dynamic>>> getUser(int userId) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId');

    print('[getUser] GET $uri');

    return _client.get(uri).then((response) {
      print('[getUser] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<Map<String, dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[getUser] Error: $error');
      return Result<Map<String, dynamic>>(error: error.toString());
    });
  }

  /// Retrieve all users.
  static Future<Result<List<dynamic>>> getAllUsers() async {
    final uri = Uri.https(Config.API_URL, '/users/');

    print('[getAllUsers] GET $uri');

    return _client.get(uri).then((response) {
      print('[getAllUsers] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<List<dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[getAllUsers] Error: $error');
      return Result<List<dynamic>>(error: error.toString());
    });
  }

  /// Edit a user by ID.
  static Future<Result<bool>> editUser(int userId, Map<String, dynamic> updates) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId');
    final body = jsonEncode(updates);

    print('[editUser] PATCH $uri');
    print('[editUser] Body: $updates');

    return _client.patch(uri, body: body, headers: {"Content-Type": "application/json"}).then((response) {
      print('[editUser] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to edit user: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[editUser] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }

  /// Get the total meters contributed by a user.
  static Future<Result<int>> getUserTotalMeters(int userId) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId/meters');

    print('[getUserTotalMeters] GET $uri');

    return _client.get(uri).then((response) {
      print('[getUserTotalMeters] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<int>(value: jsonDecode(response.body)['meters']);
      } else {
        throw Exception('Failed to fetch total meters: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[getUserTotalMeters] Error: $error');
      return Result<int>(error: error.toString());
    });
  }

  /// Get the total time spent by a user.
  static Future<Result<int>> getUserTotalTime(int userId) async {
    final uri = Uri.https(Config.API_URL, '/users/$userId/time');

    print('[getUserTotalTime] GET $uri');

    return _client.get(uri).then((response) {
      print('[getUserTotalTime] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final timeString = jsonDecode(response.body)['time'];
        final time = double.tryParse(timeString)?.toInt() ?? 0; // Convert to int
        return Result<int>(value: time);
      } else {
        throw Exception('Failed to fetch total time: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[getUserTotalTime] Error: $error');
      return Result<int>(error: error.toString());
    });
  }

  /// Login a user by bib_id and event_id.
  static Future<Result<Map<String, dynamic>>> login(String bibId, int eventId) async {
    final uri = Uri.https(Config.API_URL, '/login');
    final body = {
      "bib_id": bibId,
      "event_id": eventId,
    };

    print('[login] POST $uri');
    print('[login] Body: $body');

    return _client.post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      print('[login] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<Map<String, dynamic>>(value: jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return Result<Map<String, dynamic>>(error: "User not found");
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[login] Error: $error');
      return Result<Map<String, dynamic>>(error: error.toString());
    });
  }
}
