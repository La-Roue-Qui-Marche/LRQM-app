import 'dart:convert';
import 'package:http/http.dart' as http;
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

    final uri = Uri.https(Config.API_URL, '/measures/start');
    final body = {
      "user_id": userId,
      if (contributorsNumber != null) "contributors_number": contributorsNumber,
    };

    print('[startMeasure] POST $uri');
    print('[startMeasure] Body: $body');

    return _client
        .post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"})
        .timeout(const Duration(seconds: 10))
        .then((response) async {
          print('[startMeasure] Response: ${response.statusCode} ${response.body}');
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
          print('[startMeasure] Error: $error');
          return Result<int>(error: error.toString());
        });
  }

  /// Edit the meters for a measure.
  static Future<Result<bool>> editMeters(int meters) async {
    if (!await MeasureData.isMeasureOngoing()) {
      throw Exception("No ongoing measure found to edit meters.");
    }

    String? measureId = await MeasureData.getMeasureId();

    final uri = Uri.https(Config.API_URL, '/measures/$measureId');
    final body = {"meters": meters};

    print('[editMeters] PUT $uri');
    print('[editMeters] Body: $body');

    return _client.put(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).then((response) {
      print('[editMeters] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to edit meters: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[editMeters] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }

  /// Stop a measure.
  static Future<Result<bool>> stopMeasure() async {
    if (!await MeasureData.isMeasureOngoing()) {
      throw Exception("No ongoing measure found to stop.");
    }

    String? measureId = await MeasureData.getMeasureId();

    final uri = Uri.https(Config.API_URL, '/measures/$measureId/stop');

    print('[stopMeasure] PUT $uri');

    return _client.put(uri).then((response) async {
      print('[stopMeasure] Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        await MeasureData.clearMeasureData();
        return Result<bool>(value: true);
      } else {
        throw Exception('Failed to stop measure: ${response.statusCode}');
      }
    }).onError((error, stackTrace) {
      print('[stopMeasure] Error: $error');
      return Result<bool>(error: error.toString());
    });
  }
}
