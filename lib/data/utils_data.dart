import 'package:lrqm/data/contributors_data.dart';
import 'package:lrqm/data/time_data.dart';
import 'package:lrqm/data/user_data.dart';
import 'package:lrqm/data/event_data.dart';
import 'package:lrqm/data/measure_data.dart';

/// Class containing utility methods to interact with the data.
class UtilsData {
  /// Delete all data stored in the shared preferences.
  /// Return a [Future] object resolving to a boolean value indicating if the data was deleted.
  static Future<bool> deleteAllData() async {
    return TimeData.removeTime()
        .then((value) => ContributorsData.removeContributors())
        .then((value) => UserData.clearUserData())
        .then((value) => EventData.clearEventData())
        .then((vallue) => MeasureData.clearMeasureData())
        .then((value) => true)
        .onError((error, stackTrace) => false);
  }
}
