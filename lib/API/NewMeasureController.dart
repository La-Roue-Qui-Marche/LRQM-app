import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Data/MeasureData.dart';
import '../Data/SessionDistanceData.dart';

class NewMeasureController {
  static final http.Client _client = http.Client(); // Reusable HTTP client

  /// Start a new measure for a user.
  static Future<Result<int>> startMeasure(int userId, {int? contributorsNumber}) async {
    if (await MeasureData.isMeasureOngoing()) {
      log("Debug: Measure is already ongoing.");
      throw Exception("Cannot start a new measure while another measure is ongoing.");
    }

    final uri = Uri.https(Config.API_URL, '/measures/start');
    final body = {
      "user_id": userId,
      if (contributorsNumber != null) "contributors_number": contributorsNumber,
    };

    log("Request: POST $uri\nBody: ${jsonEncode(body)}");

    return _client
        .post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 10))
        .then((response) async {
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);

            // Only log critical information
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
          return Result<int>(error: error.toString());
        });
  }

  /// Edit the meters for a measure.
  static Future<Result<bool>> editMeters(int meters) async {
    if (!await MeasureData.isMeasureOngoing()) {
      log("Debug: No ongoing measure found to edit meters.");
      throw Exception("No ongoing measure found to edit meters.");
    }

    String? measureId = await MeasureData.getMeasureId();
    log("Debug: Retrieved measure ID for editing meters: $measureId");

    final uri = Uri.https(Config.API_URL, '/measures/$measureId');
    final body = {"meters": meters};

    log("Request: PUT $uri\nBody: ${jsonEncode(body)}");

    return _client.put(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      log("Response: ${response.statusCode}\nBody: ${response.body}");
      if (response.statusCode == 200) {
        log("Debug: Successfully edited meters.");
        return Result<bool>(value: true);
      } else {
        log("Error: Failed to edit meters with status code: ${response.statusCode}");
        throw Exception('Failed to edit meters: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      log("Error: $error\nStackTrace: $stackTrace");
      return Result<bool>(error: error.toString());
    });
  }

  /// Stop a measure.
  static Future<Result<bool>> stopMeasure() async {
    if (!await MeasureData.isMeasureOngoing()) {
      log("Debug: No ongoing measure found to stop.");
      throw Exception("No ongoing measure found to stop.");
    }

    String? measureId = await MeasureData.getMeasureId();
    log("Debug: Retrieved measure ID for stopping: $measureId");

    final uri = Uri.https(Config.API_URL, '/measures/$measureId/stop');

    log("Request: PUT $uri");

    return _client.put(uri).then((response) async {
      log("Response: ${response.statusCode}\nBody: ${response.body}");
      if (response.statusCode == 200) {
        await MeasureData.clearMeasureData();
        await SessionDistanceData.resetTotalDistance();
        log("Debug: Measure ID cleared.");
        return Result<bool>(value: true);
      } else {
        log("Error: Failed to stop measure with status code: ${response.statusCode}");
        throw Exception('Failed to stop measure: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      log("Error: $error\nStackTrace: $stackTrace");
      return Result<bool>(error: error.toString());
    });
  }
}
