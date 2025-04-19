import 'DataManagement.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

/// Class to manage event-related data.
class EventData {
  /// Singleton instance of the DataManagement class.
  static final DataManagement _dataManagement = DataManagement();

  /// Save all event details in the shared preferences.
  static Future<bool> saveEvent(Map<String, dynamic> event) async {
    bool idSaved = await _dataManagement.saveInt('event_id', event['id']);
    bool nameSaved = await _dataManagement.saveString('event_name', event['name']);
    bool startDateSaved = await _dataManagement.saveString('event_start_date', event['start_date']);
    bool endDateSaved = await _dataManagement.saveString('event_end_date', event['end_date']);
    bool metersGoalSaved = await _dataManagement.saveInt('event_meters_goal', event['meters_goal']);

    // Save meeting point as flat values
    bool meetingPointLatSaved = event['meeting_point_lat'] != null
        ? await _dataManagement.saveDouble('event_meeting_point_lat', event['meeting_point_lat'])
        : true;
    bool meetingPointLngSaved = event['meeting_point_lng'] != null
        ? await _dataManagement.saveDouble('event_meeting_point_lng', event['meeting_point_lng'])
        : true;

    // Save site coordinates as flat values
    bool siteLeftUpLatSaved = event['site_left_up_lat'] != null
        ? await _dataManagement.saveDouble('event_site_left_up_lat', event['site_left_up_lat'])
        : true;
    bool siteLeftUpLngSaved = event['site_left_up_lng'] != null
        ? await _dataManagement.saveDouble('event_site_left_up_lng', event['site_left_up_lng'])
        : true;
    bool siteRightDownLatSaved = event['site_right_down_lat'] != null
        ? await _dataManagement.saveDouble('event_site_right_down_lat', event['site_right_down_lat'])
        : true;
    bool siteRightDownLngSaved = event['site_right_down_lng'] != null
        ? await _dataManagement.saveDouble('event_site_right_down_lng', event['site_right_down_lng'])
        : true;

    return idSaved &&
        nameSaved &&
        startDateSaved &&
        endDateSaved &&
        metersGoalSaved &&
        meetingPointLatSaved &&
        meetingPointLngSaved &&
        siteLeftUpLatSaved &&
        siteLeftUpLngSaved &&
        siteRightDownLatSaved &&
        siteRightDownLngSaved;
  }

  /// Get the event ID from the shared preferences.
  static Future<int?> getEventId() async {
    return _dataManagement.getInt('event_id');
  }

  /// Get the event name from the shared preferences.
  static Future<String?> getEventName() async {
    return _dataManagement.getString('event_name');
  }

  /// Get the event start date from the shared preferences.
  static Future<String?> getStartDate() async {
    return _dataManagement.getString('event_start_date');
  }

  /// Get the event end date from the shared preferences.
  static Future<String?> getEndDate() async {
    return _dataManagement.getString('event_end_date');
  }

  /// Get the event meters goal from the shared preferences.
  static Future<int?> getMetersGoal() async {
    return _dataManagement.getInt('event_meters_goal');
  }

  /// Get the event meeting point as a List<mp.LatLng> (2 identical points for compatibility)
  static Future<List<mp.LatLng>?> getMeetingPointLatLngList() async {
    final lat = await _dataManagement.getDouble('event_meeting_point_lat');
    final lng = await _dataManagement.getDouble('event_meeting_point_lng');
    if (lat == null || lng == null) return null;
    return [
      mp.LatLng(lat, lng),
      mp.LatLng(lat, lng),
    ];
  }

  /// Get the event site coordinates as a List<mp.LatLng> (same order as ZONE_EVENT)
  static Future<List<mp.LatLng>?> getSiteCoordLatLngList() async {
    final leftUpLat = await _dataManagement.getDouble('event_site_left_up_lat');
    final leftUpLng = await _dataManagement.getDouble('event_site_left_up_lng');
    final rightDownLat = await _dataManagement.getDouble('event_site_right_down_lat');
    final rightDownLng = await _dataManagement.getDouble('event_site_right_down_lng');
    if (leftUpLat == null || leftUpLng == null || rightDownLat == null || rightDownLng == null) return null;
    return [
      mp.LatLng(leftUpLat, leftUpLng),
      mp.LatLng(rightDownLat, leftUpLng),
      mp.LatLng(rightDownLat, rightDownLng),
      mp.LatLng(leftUpLat, rightDownLng),
    ];
  }

  /// Remove all event-related data from the shared preferences.
  static Future<bool> clearEventData() async {
    bool idRemoved = await _dataManagement.removeData('event_id');
    bool nameRemoved = await _dataManagement.removeData('event_name');
    bool startDateRemoved = await _dataManagement.removeData('event_start_date');
    bool endDateRemoved = await _dataManagement.removeData('event_end_date');
    bool metersGoalRemoved = await _dataManagement.removeData('event_meters_goal');
    // Remove flat fields
    bool meetingPointLatRemoved = await _dataManagement.removeData('event_meeting_point_lat');
    bool meetingPointLngRemoved = await _dataManagement.removeData('event_meeting_point_lng');
    bool siteLeftUpLatRemoved = await _dataManagement.removeData('event_site_left_up_lat');
    bool siteLeftUpLngRemoved = await _dataManagement.removeData('event_site_left_up_lng');
    bool siteRightDownLatRemoved = await _dataManagement.removeData('event_site_right_down_lat');
    bool siteRightDownLngRemoved = await _dataManagement.removeData('event_site_right_down_lng');
    return idRemoved &&
        nameRemoved &&
        startDateRemoved &&
        endDateRemoved &&
        metersGoalRemoved &&
        meetingPointLatRemoved &&
        meetingPointLngRemoved &&
        siteLeftUpLatRemoved &&
        siteLeftUpLngRemoved &&
        siteRightDownLatRemoved &&
        siteRightDownLngRemoved;
  }
}
