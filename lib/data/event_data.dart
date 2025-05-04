import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:flutter/foundation.dart';
import 'package:lrqm/data/management_data.dart';

enum EventStatus { notStarted, inProgress, over }

class EventData {
  static final ManagementData _managementData = ManagementData();

  // ---- Save event ----

  static Future<bool> saveEvent(Map<String, dynamic> event) async {
    final saves = [
      _managementData.saveInt('event_id', event['id']),
      _managementData.saveString('event_name', event['name']),
      _managementData.saveString('event_start_date', event['start_date']),
      _managementData.saveString('event_end_date', event['end_date']),
      _managementData.saveInt('event_meters_goal', event['meters_goal']),
      _saveOptionalDouble('event_meeting_point_lat', event['meeting_point_lat']),
      _saveOptionalDouble('event_meeting_point_lng', event['meeting_point_lng']),
      _saveOptionalDouble('event_site_left_up_lat', event['site_left_up_lat']),
      _saveOptionalDouble('event_site_left_up_lng', event['site_left_up_lng']),
      _saveOptionalDouble('event_site_right_down_lat', event['site_right_down_lat']),
      _saveOptionalDouble('event_site_right_down_lng', event['site_right_down_lng']),
    ];

    final results = await Future.wait(saves);
    return results.every((res) => res);
  }

  static Future<bool> _saveOptionalDouble(String key, dynamic value) async {
    return value != null ? await _managementData.saveDouble(key, value) : true;
  }

  // ---- Getters ----

  static Future<int?> getEventId() => _managementData.getInt('event_id');
  static Future<String?> getEventName() => _managementData.getString('event_name');
  static Future<String?> getStartDate() => _managementData.getString('event_start_date');
  static Future<String?> getEndDate() => _managementData.getString('event_end_date');
  static Future<int?> getMetersGoal() => _managementData.getInt('event_meters_goal');

  static Future<List<mp.LatLng>?> getMeetingPointLatLngList() async {
    final lat = await _managementData.getDouble('event_meeting_point_lat');
    final lng = await _managementData.getDouble('event_meeting_point_lng');
    return (lat != null && lng != null) ? [mp.LatLng(lat, lng), mp.LatLng(lat, lng)] : null;
  }

  static Future<List<mp.LatLng>?> getSiteCoordLatLngList() async {
    final lat1 = await _managementData.getDouble('event_site_left_up_lat');
    final lng1 = await _managementData.getDouble('event_site_left_up_lng');
    final lat2 = await _managementData.getDouble('event_site_right_down_lat');
    final lng2 = await _managementData.getDouble('event_site_right_down_lng');

    return (lat1 != null && lng1 != null && lat2 != null && lng2 != null)
        ? [mp.LatLng(lat1, lng1), mp.LatLng(lat2, lng1), mp.LatLng(lat2, lng2), mp.LatLng(lat1, lng2)]
        : null;
  }

  // ---- DateTime parsing helper ----

  static DateTime? _parseUtcToLocal(String? rawDate) {
    if (rawDate == null) return null;
    try {
      final dateUtc = DateTime.parse(rawDate.endsWith('Z') ? rawDate : '${rawDate}Z');
      return dateUtc.toLocal();
    } catch (e) {
      debugPrint('Failed to parse UTC date: $e');
      return null;
    }
  }

  // ---- Status and timing ----

  static Future<bool> hasEventStarted() async {
    final start = await getStartDate();
    final startDateTime = _parseUtcToLocal(start);
    if (startDateTime == null) return false;

    debugPrint('Event start time (Local): $startDateTime');
    return DateTime.now().isAfter(startDateTime);
  }

  static Future<bool> isEventOver() async {
    final end = await getEndDate();
    final endDateTime = _parseUtcToLocal(end);
    if (endDateTime == null) return false;

    debugPrint('Event end time (Local): $endDateTime');
    return DateTime.now().isAfter(endDateTime);
  }

  static Future<EventStatus> getEventStatus() async {
    if (await isEventOver()) {
      debugPrint('Event status: over');
      return EventStatus.over;
    }
    if (await hasEventStarted()) {
      debugPrint('Event status: inProgress');
      return EventStatus.inProgress;
    }
    debugPrint('Event status: notStarted');
    return EventStatus.notStarted;
  }

  static Future<int> getTimeUntilStartInSeconds() async {
    final start = await getStartDate();
    final startDateTime = _parseUtcToLocal(start);
    if (startDateTime == null) return 0;

    final now = DateTime.now();
    debugPrint('Event start time: $startDateTime, Current time: $now');
    return startDateTime.difference(now).inSeconds;
  }

  static Future<int> getRemainingTimeInSeconds() async {
    final end = await getEndDate();
    final endDateTime = _parseUtcToLocal(end);
    if (endDateTime == null) return 0;

    final now = DateTime.now();
    final seconds = endDateTime.difference(now).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  static Future<int> getRemainingTimeUntilEndInSeconds() async {
    final end = await getEndDate();
    final endDateTime = _parseUtcToLocal(end);
    if (endDateTime == null) return 0;

    return endDateTime.difference(DateTime.now()).inSeconds;
  }

  // ---- Time Formatting ----

  static String _formatDuration(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (days > 0) {
      return "$days:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  static Future<String> getFormattedTimeUntilStart() async {
    final seconds = await getTimeUntilStartInSeconds();
    return seconds <= 0 ? "L'évènement a commencé !" : _formatDuration(seconds);
  }

  static Future<String> getFormattedRemainingTime() async {
    final seconds = await getRemainingTimeInSeconds();
    if (seconds < 0) return "L'évènement est terminé !";

    final start = await getStartDate();
    final startDateTime = _parseUtcToLocal(start);
    if (startDateTime == null || DateTime.now().isBefore(startDateTime)) {
      return "L'évènement n'a pas encore commencé !";
    }

    return _formatDuration(seconds);
  }

  static Future<double> getEventCompletionPercentage() async {
    final start = await getStartDate();
    final end = await getEndDate();
    final startDate = _parseUtcToLocal(start);
    final endDate = _parseUtcToLocal(end);

    if (startDate == null || endDate == null) return 0.0;

    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;

    final total = endDate.difference(startDate).inSeconds;
    final elapsed = now.difference(startDate).inSeconds;
    return (elapsed / total) * 100;
  }

  // ---- Clear ----

  static Future<bool> clearEventData() async {
    final keys = [
      'event_id',
      'event_name',
      'event_start_date',
      'event_end_date',
      'event_meters_goal',
      'event_meeting_point_lat',
      'event_meeting_point_lng',
      'event_site_left_up_lat',
      'event_site_left_up_lng',
      'event_site_right_down_lat',
      'event_site_right_down_lng',
    ];
    final results = await Future.wait(keys.map(_managementData.removeData));
    return results.every((res) => res);
  }
}
