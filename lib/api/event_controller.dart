import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:lrqm/utils/Result.dart';
import 'package:lrqm/utils/config.dart';

class EventController {
  static final http.Client _client = http.Client(); // Reusable HTTP client

  /// Create a new event with the provided details.
  static Future<Result<bool>> createEvent(
    String name,
    String startDate,
    String endDate,
    int metersGoal, {
    double? meetingPointLat,
    double? meetingPointLng,
    double? siteLeftUpLat,
    double? siteLeftUpLng,
    double? siteRightDownLat,
    double? siteRightDownLng,
  }) async {
    final uri = Uri.https(Config.apiUrl, '/events');
    final body = {
      "name": name,
      "start_date": startDate,
      "end_date": endDate,
      "meters_goal": metersGoal,
      "meeting_point_lat": meetingPointLat,
      "meeting_point_lng": meetingPointLng,
      "site_left_up_lat": siteLeftUpLat,
      "site_left_up_lng": siteLeftUpLng,
      "site_right_down_lat": siteRightDownLat,
      "site_right_down_lng": siteRightDownLng,
    };

    // Remove nulls as API expects absent fields for nulls
    body.removeWhere((key, value) => value == null);

    if (kDebugMode) {
      debugPrint('[createEvent] POST $uri');
      debugPrint('[createEvent] Body: $body');
    }

    return _client.post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      debugPrint('[createEvent] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[createEvent] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }

  /// Retrieve all events.
  static Future<Result<List<dynamic>>> getAllEvents() async {
    final uri = Uri.https(Config.apiUrl, '/events');

    debugPrint('[getAllEvents] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getAllEvents] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<List<dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch events: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getAllEvents] Error: $error');
      return Result<List<dynamic>>(error: error.toString());
    });
  }

  /// Retrieve an event by ID.
  static Future<Result<Map<String, dynamic>>> getEventById(int eventId) async {
    final uri = Uri.https(Config.apiUrl, '/events/$eventId');

    debugPrint('[getEventById] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getEventById] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<Map<String, dynamic>>(value: jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch event: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getEventById] Error: $error');
      return Result<Map<String, dynamic>>(error: error.toString());
    });
  }

  /// Get the number of active users for an event.
  static Future<Result<int>> getActiveUsers(int eventId) async {
    final uri = Uri.https(Config.apiUrl, '/events/$eventId/active_users');

    debugPrint('[getActiveUsers] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getActiveUsers] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<int>(value: jsonDecode(response.body)['active_users_number']);
      } else {
        throw Exception('Failed to fetch active users: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getActiveUsers] Error: $error');
      return Result<int>(error: error.toString());
    });
  }

  /// Get the total meters for an event.
  static Future<Result<int>> getTotalMeters(int eventId) async {
    final uri = Uri.https(Config.apiUrl, '/events/$eventId/meters');

    debugPrint('[getTotalMeters] GET $uri');

    return _client.get(uri).then((response) {
      debugPrint('[getTotalMeters] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<int>(value: jsonDecode(response.body)['total_meters']);
      } else {
        throw Exception('Failed to fetch total meters: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[getTotalMeters] Error: $error');
      return Result<int>(error: error.toString());
    });
  }
}
