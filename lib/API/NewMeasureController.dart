import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Data/MeasureData.dart';

class NewMeasureController {
  static final http.Client _client = http.Client();
  static const Duration _timeoutDuration = Duration(seconds: 10);

  /// Start a new measure for a user.
  static Future<Result<int>> startMeasure(int userId, {int? contributorsNumber}) async {
    try {
      if (await MeasureData.isMeasureOngoing()) {
        return Result(error: "Une mesure est déjà en cours.");
      }

      final uri = Uri.https(Config.apiUrl, '/measures/start');
      final body = {
        "user_id": userId,
        if (contributorsNumber != null) "contributors_number": contributorsNumber,
      };

      debugPrint('[startMeasure] POST $uri');
      debugPrint('[startMeasure] Body: $body');

      final response = await _client
          .post(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).timeout(_timeoutDuration);

      debugPrint('[startMeasure] Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final measureId = data['id'];
        if (measureId == null) return Result(error: "ID manquant dans la réponse.");
        await MeasureData.saveMeasureId(measureId.toString());
        return Result(value: measureId);
      } else {
        return Result(error: 'Erreur ${response.statusCode} : impossible de démarrer la mesure.');
      }
    } catch (e) {
      debugPrint('[startMeasure] Exception: $e');
      return Result(error: e.toString());
    }
  }

  /// Update the meters for an ongoing measure.
  static Future<Result<bool>> editMeters(int meters) async {
    try {
      if (!await MeasureData.isMeasureOngoing()) {
        return Result(error: "Aucune mesure en cours à modifier.");
      }

      final measureId = await MeasureData.getMeasureId();
      final uri = Uri.https(Config.apiUrl, '/measures/$measureId');
      final body = {"meters": meters};

      debugPrint('[editMeters] PUT $uri');
      debugPrint('[editMeters] Body: $body');

      final response = await _client
          .put(uri, body: jsonEncode(body), headers: {"Content-Type": "application/json"}).timeout(_timeoutDuration);

      debugPrint('[editMeters] Response: ${response.statusCode} ${response.body}');

      return response.statusCode == 200
          ? Result(value: true)
          : Result(error: 'Erreur ${response.statusCode} : échec de la mise à jour.');
    } catch (e) {
      debugPrint('[editMeters] Exception: $e');
      return Result(error: e.toString());
    }
  }

  /// Stop an ongoing measure.
  static Future<Result<bool>> stopMeasure() async {
    try {
      if (!await MeasureData.isMeasureOngoing()) {
        return Result(error: "Aucune mesure en cours à arrêter.");
      }

      final measureId = await MeasureData.getMeasureId();
      final uri = Uri.https(Config.apiUrl, '/measures/$measureId/stop');

      debugPrint('[stopMeasure] PUT $uri');

      final response = await _client.put(uri).timeout(_timeoutDuration);

      debugPrint('[stopMeasure] Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        await MeasureData.clearMeasureId();
        return Result(value: true);
      } else {
        return Result(error: 'Erreur ${response.statusCode} : échec de l\'arrêt de la mesure.');
      }
    } catch (e) {
      debugPrint('[stopMeasure] Exception: $e');
      return Result(error: e.toString());
    }
  }
}
