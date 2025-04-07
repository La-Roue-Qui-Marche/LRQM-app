import 'dart:async';

class LogHelper {
  static final List<String> _logs = [];
  static final StreamController<List<String>> _logStreamController = StreamController<List<String>>.broadcast();
  static bool _isClosed = false;
  static bool isLoggingEnabled = true;

  /// Stream pour afficher les logs
  static Stream<List<String>> get logStream => _logStreamController.stream;

  /// Ajoute un log au journal avec niveau et timestamp
  static void writeLog(String msg, {String level = "INFO"}) {
    if (!isLoggingEnabled || _isClosed) return;

    final timestamp = DateTime.now().toIso8601String();
    final logEntry = "[$level] $timestamp: $msg";
    _logs.add(logEntry);

    // Émet une copie non modifiable
    _logStreamController.add(List.unmodifiable(_logs));
  }

  /// Méthodes pratiques pour différents niveaux de log
  static void logInfo(String msg) => writeLog(msg, level: "INFO");
  static void logWarn(String msg) => writeLog(msg, level: "WARN");
  static void logError(String msg) => writeLog(msg, level: "ERROR");

  /// Force un push des logs actuels dans le stream (utile au premier affichage)
  static void forceRefresh() {
    if (_isClosed) return;
    _logStreamController.add(List.unmodifiable(_logs));
  }

  /// Supprime tous les logs
  static void clearLogs() {
    if (_isClosed) return;
    _logs.clear();
    _logStreamController.add([]);
  }

  /// Renvoie tous les logs actuels (pour export, copier, etc.)
  static List<String> getLogs() {
    return List.unmodifiable(_logs);
  }

  /// Ferme proprement le StreamController
  static void dispose() {
    if (_isClosed) return;
    _logStreamController.close();
    _isClosed = true;
  }
}
