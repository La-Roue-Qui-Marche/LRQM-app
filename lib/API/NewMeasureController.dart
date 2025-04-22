import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Data/MeasureData.dart';

class NewMeasureController {
  static final http.Client _client = http.Client(); // Reusable HTTP client

  /// Start a new measure for a user.
  static Future<Result<int>> startMeasure(int userId, {int? contributorsNumber}) async {
    if (await MeasureData.isMeasureOngoing()) {
      throw Exception("Cannot start a new measure while another measure is ongoing.");
    }

    final uri = Uri.https(Config.apiUrl, '/measures/start');
    final body = {
      "user_id": userId,
      if (contributorsNumber != null) "contributors_number": contributorsNumber,
    };

    debugPrint('[startMeasure] POST $uri');
    debugPrint('[startMeasure] Body: $body');

    return _client
        .post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 10))
        .then((response) async {
          debugPrint('[startMeasure] Response: ${response.statusCode} ${response.body}');
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            int? measureId = responseData['id'];
            if (measureId == null) {
              throw Exception("id is null in the response.");
            }

            await MeasureData.saveMeasureId(measureId.toString());
            return Result<int>(value: measureId);
          } else {
            throw Exception('Failed to start measure: ${response.statusCode}');
          }
        })
        .onError((error, stackTrace) {
          debugPrint('[startMeasure] Error: $error');
          return Result<int>(error: error.toString());
        });
  }

  /// Edit the meters for a measure.
  static Future<Result<bool>> editMeters(int meters) async {
    if (!await MeasureData.isMeasureOngoing()) {
      throw Exception("No ongoing measure found to edit meters.");
    }

    String? measureId = await MeasureData.getMeasureId();

    final uri = Uri.https(Config.apiUrl, '/measures/$measureId');
    final body = {"meters": meters};

    debugPrint('[editMeters] PUT $uri');
    debugPrint('[editMeters] Body: $body');

    return _client.put(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      debugPrint('[editMeters] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to edit meters: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[editMeters] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }

  /// Stop a measure.
  static Future<Result<bool>> stopMeasure() async {
    if (!await MeasureData.isMeasureOngoing()) {
      throw Exception("No ongoing measure found to stop.");
    }

    String? measureId = await MeasureData.getMeasureId();

    final uri = Uri.https(Config.apiUrl, '/measures/$measureId/stop');

    debugPrint('[stopMeasure] PUT $uri');

    return _client.put(uri).then((response) async {
      debugPrint('[stopMeasure] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to stop measure: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      debugPrint('[stopMeasure] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }
}
