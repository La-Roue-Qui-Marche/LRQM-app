import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

/// LogHelper as a singleton class for managing application logs
class LogHelper {
  // Singleton instance
  static final LogHelper _instance = LogHelper._internal();

  // Factory constructor to return the same instance
  factory LogHelper() => _instance;

  // Private constructor for singleton pattern
  LogHelper._internal();

  // Instance variables
  final List<String> _logs = [];
  final StreamController<List<String>> _logStreamController = StreamController<List<String>>.broadcast();
  bool _isClosed = false;
  bool isLoggingEnabled = true;

  /// Stream pour afficher les logs
  Stream<List<String>> get logStream => _logStreamController.stream;

  /// Ajoute un log au journal avec niveau et timestamp
  void writeLog(String msg, {String level = "INFO"}) {
    if (!isLoggingEnabled) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = "[$level] $timestamp: $msg";
      _logs.add(logEntry);

      // Log to console
      dev.log(logEntry, name: 'LogHelper');

      // Only emit if the stream controller is still open
      if (!_isClosed && _logStreamController.hasListener) {
        // Émet une copie non modifiable
        _logStreamController.add(List.unmodifiable(_logs));
      }
    } catch (e) {
      // Fallback logging in case of error
      dev.log("Error in LogHelper: $e", name: 'LogHelper');
    }
  }

  /// Méthodes pratiques pour différents niveaux de log
  void logInfo(String msg) => writeLog(msg, level: "INFO");
  void logWarn(String msg) => writeLog(msg, level: "WARN");
  void logError(String msg) => writeLog(msg, level: "ERROR");

  /// Force un push des logs actuels dans le stream (utile au premier affichage)
  void forceRefresh() {
    if (_isClosed) return;
    // Add logging to diagnose issues with force refresh
    dev.log("Force refreshing logs (${_logs.length} entries)", name: 'LogHelper');
    try {
      _logStreamController.add(List.unmodifiable(_logs));
    } catch (e) {
      dev.log("Error in forceRefresh: $e", name: 'LogHelper');
    }
  }

  /// Supprime tous les logs
  void clearLogs() {
    if (_isClosed) return;
    _logs.clear();
    _logStreamController.add([]);
  }

  /// Renvoie tous les logs actuels (pour export, copier, etc.)
  List<String> getLogs() {
    return List.unmodifiable(_logs);
  }

  /// Ferme proprement le StreamController
  void dispose() {
    if (_isClosed) return;
    _logStreamController.close();
    _isClosed = true;
  }

  // Static convenience methods with 'static' prefix to avoid name conflicts
  static final LogHelper _logger = LogHelper();
  static Stream<List<String>> get staticLogStream => _logger.logStream;

  static void staticLog(String msg, {String level = "INFO"}) => _logger.writeLog(msg, level: level);
  static void staticLogInfo(String msg) => _logger.logInfo(msg);
  static void staticLogWarn(String msg) => _logger.logWarn(msg);
  static void staticLogError(String msg) => _logger.logError(msg);
  static void staticForceRefresh() => _logger.forceRefresh();
  static void staticClearLogs() => _logger.clearLogs();
  static List<String> staticGetLogs() => _logger.getLogs();
  static void staticDispose() => _logger.dispose();

  // --- Kalman CSV Logging ---
  static Future<File> _getKalmanCsvFile() async {
    // Use systemTemp instead of path_provider
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/kalman_data.csv');
    if (!await file.exists()) {
      await file.writeAsString(
        'timestamp,orig_lat,orig_lng,gps_acc,filtered_lat,filtered_lng,speed,uncertainty,confidence\n',
        mode: FileMode.write,
      );
    }
    return file;
  }

  /// Append a line of Kalman data to the CSV file
  static Future<void> staticAppendKalmanCsv({
    required double timestamp,
    required double origLat,
    required double origLng,
    required double gpsAcc,
    required double filteredLat,
    required double filteredLng,
    required double speed,
    required double uncertainty,
    required double confidence,
  }) async {
    try {
      final file = await _getKalmanCsvFile();
      final line = '$timestamp,$origLat,$origLng,$gpsAcc,$filteredLat,$filteredLng,$speed,$uncertainty,$confidence\n';
      await file.writeAsString(line, mode: FileMode.append);
    } catch (e) {
      dev.log("Error writing Kalman CSV: $e", name: 'LogHelper');
    }
  }

  /// Get the Kalman CSV file path
  static Future<String> staticGetKalmanCsvPath() async {
    final file = await _getKalmanCsvFile();
    return file.path;
  }

  /// Clear the Kalman CSV file
  static Future<void> staticClearKalmanCsv() async {
    final file = await _getKalmanCsvFile();
    await file.writeAsString(
      'timestamp,orig_lat,orig_lng,gps_acc,filtered_lat,filtered_lng,speed,uncertainty,confidence\n',
      mode: FileMode.write,
    );
  }
}
