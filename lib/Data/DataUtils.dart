import 'ContributorsData.dart';
import 'TimeData.dart';
import 'UserData.dart';
import 'EventData.dart';
import 'MeasureData.dart';

/// Class containing utility methods to interact with the data.
class DataUtils {
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
