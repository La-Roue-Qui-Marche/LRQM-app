import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../Utils/LogHelper.dart';

class ShareLog extends StatefulWidget {
  @override
  _ShareLogState createState() => _ShareLogState();
}

class _ShareLogState extends State<ShareLog> {
  final ScrollController _scrollController = ScrollController();
  bool _showInfo = true;
  bool _showWarnings = true;
  bool _showErrors = true;
  bool _autoScroll = false; // Track auto scroll state

  @override
  void initState() {
    super.initState();
    LogHelper.forceRefresh();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _toggleAutoScroll() {
    setState(() {
      _autoScroll = !_autoScroll;
    });
  }

  void _addTestLog() {
    LogHelper.writeLog("Test log at ${DateTime.now().toIso8601String()}");
  }

  void _clearLogs() {
    LogHelper.clearLogs();
  }

  void _shareLogs() async {
    final logs = LogHelper.getLogs();
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No logs to share.")),
      );
      return;
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final directory = await Directory.systemTemp.createTemp('logs');
    final file = File('${directory.path}/logs_$timestamp.txt');
    await file.writeAsString(logs.join('\n'));

    Share.shareFiles([file.path], text: "Application Logs");
  }

  Color _getLogColor(String log) {
    if (log.contains("[ERROR]")) {
      return Colors.red;
    } else if (log.contains("[WARN]")) {
      return Colors.orange;
    } else if (log.contains("[INFO]")) {
      return const Color.fromARGB(255, 0, 80, 145);
    }
    return Colors.black87; // Default color
  }

  bool _shouldShowLog(String log) {
    if (log.contains("[ERROR]")) {
      return _showErrors;
    } else if (log.contains("[WARN]")) {
      return _showWarnings;
    } else if (log.contains("[INFO]")) {
      return _showInfo;
    }
    return true; // Show other logs by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Clear logs",
            onPressed: _clearLogs,
          ),
          const IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Force refresh",
            onPressed: LogHelper.forceRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share logs",
            onPressed: _shareLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('INFO'),
                  selected: _showInfo,
                  selectedColor: const Color.fromARGB(255, 200, 230, 255),
                  showCheckmark: false,
                  avatar: Icon(
                    _showInfo ? Icons.check : Icons.close,
                    size: 18,
                    color: _showInfo ? Colors.blue[700] : Colors.grey[600],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _showInfo = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('WARNINGS'),
                  selected: _showWarnings,
                  selectedColor: Colors.amber[100],
                  showCheckmark: false,
                  avatar: Icon(
                    _showWarnings ? Icons.check : Icons.close,
                    size: 18,
                    color: _showWarnings ? Colors.amber[700] : Colors.grey[600],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _showWarnings = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('ERRORS'),
                  selected: _showErrors,
                  selectedColor: Colors.red[100],
                  showCheckmark: false,
                  avatar: Icon(
                    _showErrors ? Icons.check : Icons.close,
                    size: 18,
                    color: _showErrors ? Colors.red[700] : Colors.grey[600],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _showErrors = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<List<String>>(
                stream: LogHelper.logStream,
                builder: (context, snapshot) {
                  final allLogs = snapshot.data ?? [];
                  final logs = allLogs.where(_shouldShowLog).toList();

                  if (logs.isEmpty) {
                    return const Center(child: Text('No logs to display with current filters.'));
                  }

                  // Apply auto scroll if enabled
                  if (_autoScroll) {
                    _scrollToBottom();
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            logs[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: _getLogColor(logs[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "autoScrollBtn",
        mini: true,
        backgroundColor: _autoScroll ? Colors.blue : Colors.grey,
        onPressed: _toggleAutoScroll,
        tooltip: _autoScroll ? 'Auto-scroll enabled' : 'Auto-scroll disabled',
        child: Icon(_autoScroll ? Icons.sync : Icons.sync_disabled),
      ),
    );
  }
}
