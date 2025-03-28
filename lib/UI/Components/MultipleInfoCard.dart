import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class MultipleInfoCard extends StatefulWidget {
  final List<Widget?> logos;
  final List<String> titles;
  final List<String> data;
  final String? additionalDetails;
  final List<ActionItem>? actionItems;

  const MultipleInfoCard({
    super.key,
    required this.logos,
    required this.titles,
    required this.data,
    this.additionalDetails,
    this.actionItems,
  });

  @override
  _MultipleInfoCardState createState() => _MultipleInfoCardState();
}

class ActionItem {
  final Icon icon;
  final String label;
  final VoidCallback onPressed;

  ActionItem({required this.icon, required this.label, required this.onPressed});
}

class _MultipleInfoCardState extends State<MultipleInfoCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canExpand => widget.additionalDetails != null;

  void _toggleExpanded() {
    if (_canExpand) {
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < widget.titles.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            children: [
                              if (widget.logos[i] != null)
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(Config.COLOR_APP_BAR).withOpacity(0.15),
                                  ),
                                  child: Center(
                                    child: IconTheme(
                                      data: const IconThemeData(
                                        size: 32,
                                        color: Color(Config.COLOR_APP_BAR),
                                      ),
                                      child: widget.logos[i]!,
                                    ),
                                  ),
                                ),
                              if (widget.logos[i] != null) const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.titles[i],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(Config.COLOR_APP_BAR),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.data[i],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(Config.COLOR_APP_BAR),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_canExpand)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(Config.COLOR_APP_BAR),
                    ),
                  ),
              ],
            ),
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.additionalDetails != null) const SizedBox(height: 16),
                  if (widget.additionalDetails != null)
                    Text(
                      widget.additionalDetails!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(Config.COLOR_APP_BAR),
                      ),
                    ),
                  if (widget.additionalDetails != null) const SizedBox(height: 16),
                ],
              ),
            ),
            if (widget.actionItems != null && widget.actionItems!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: widget.actionItems!.map((actionItem) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      children: [
                        IconButton(
                          icon: actionItem.icon,
                          onPressed: actionItem.onPressed,
                        ),
                        Text(
                          actionItem.label,
                          style: const TextStyle(color: Color(Config.COLOR_APP_BAR)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
