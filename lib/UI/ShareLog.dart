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

  void _saveLogsToFile() async {
    final logs = LogHelper.getLogs();
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No logs to save.")),
      );
      return;
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final directory = await Directory.systemTemp.createTemp('logs');
    final file = File('${directory.path}/logs_$timestamp.txt');
    await file.writeAsString(logs.join('\n'));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logs saved to ${file.path}")),
    );
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Force refresh",
            onPressed: LogHelper.forceRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share logs",
            onPressed: _shareLogs,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save logs",
            onPressed: _saveLogsToFile,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<List<String>>(
          stream: LogHelper.logStream,
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return const Center(child: Text('No logs yet.'));
            }

            _scrollToBottom();

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
                        fontSize: 13,
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
    );
  }
}
