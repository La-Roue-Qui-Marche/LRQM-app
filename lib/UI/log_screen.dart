// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lrqm/ui/components/app_toast.dart';
import 'package:lrqm/utils/log_helper.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _showInfo = true;
  bool _showWarnings = true;
  bool _showErrors = true;
  bool _autoScroll = false;

  @override
  void initState() {
    super.initState();
    LogHelper.staticForceRefresh();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _toggleAutoScroll() {
    setState(() => _autoScroll = !_autoScroll);
  }

  void _clearLogs() => LogHelper.staticClearLogs();

  Future<void> _shareLogs() async {
    final logs = LogHelper.staticGetLogs();
    if (logs.isEmpty) {
      AppToast.showError("No logs to share.");
      return;
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final directory = await Directory.systemTemp.createTemp('logs');
    final file = File('${directory.path}/logs_$timestamp.txt');
    await file.writeAsString(logs.join('\n'));

    Share.shareFiles([file.path], text: "Application Logs");
  }

  Color _getLogColor(String log) {
    if (log.contains("[ERROR]")) return Colors.red;
    if (log.contains("[WARN]")) return Colors.orange;
    if (log.contains("[INFO]")) return const Color.fromARGB(255, 0, 80, 145);
    return Colors.black87;
  }

  bool _shouldShowLog(String log) {
    if (log.contains("[ERROR]")) return _showErrors;
    if (log.contains("[WARN]")) return _showWarnings;
    if (log.contains("[INFO]")) return _showInfo;
    return true;
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildChip(
              "INFO", _showInfo, Colors.blue[700], Colors.blue[50], () => setState(() => _showInfo = !_showInfo)),
          const SizedBox(width: 8),
          _buildChip("WARNINGS", _showWarnings, Colors.amber[700], Colors.amber[100],
              () => setState(() => _showWarnings = !_showWarnings)),
          const SizedBox(width: 8),
          _buildChip("ERRORS", _showErrors, Colors.red[700], Colors.red[100],
              () => setState(() => _showErrors = !_showErrors)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, Color? color, Color? bgColor, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: bgColor,
      showCheckmark: false,
      avatar: Icon(
        selected ? Icons.check : Icons.close,
        size: 18,
        color: selected ? color : Colors.grey[600],
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildLogList(List<String> logs) {
    final filteredLogs = logs.where(_shouldShowLog).toList();

    if (filteredLogs.isEmpty) {
      return const Center(child: Text('No logs to display with current filters.'));
    }

    if (_autoScroll) _scrollToBottom();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            filteredLogs[index],
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: _getLogColor(filteredLogs[index]),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Logs'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.delete), tooltip: "Clear logs", onPressed: _clearLogs),
            IconButton(
                icon: const Icon(Icons.refresh), tooltip: "Force refresh", onPressed: LogHelper.staticForceRefresh),
            IconButton(icon: const Icon(Icons.share), tooltip: "Share logs", onPressed: _shareLogs),
          ],
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: StreamBuilder<List<String>>(
                  stream: LogHelper.staticLogStream,
                  builder: (context, snapshot) {
                    return _buildLogList(snapshot.data ?? []);
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
      ),
    );
  }
}
