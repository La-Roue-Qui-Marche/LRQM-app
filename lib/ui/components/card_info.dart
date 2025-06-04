import 'package:flutter/material.dart';
import 'package:lrqm/utils/config.dart';
import 'package:shimmer/shimmer.dart';

class CardInfo extends StatefulWidget {
  final Widget? logo;
  final String title;
  final String? data;
  final String? additionalDetails;

  const CardInfo({
    super.key,
    this.logo,
    required this.title,
    this.data,
    this.additionalDetails,
  });

  @override
  _CardInfoState createState() => _CardInfoState();
}

class ActionItem {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  ActionItem({required this.icon, required this.label, required this.onPressed});
}

class _CardInfoState extends State<CardInfo> with SingleTickerProviderStateMixin {
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.logo != null)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(Config.backgroundColor),
                      ),
                      child: Center(
                        child: IconTheme(
                          data: const IconThemeData(
                            size: 28,
                            color: Colors.black87,
                          ),
                          child: widget.logo!,
                        ),
                      ),
                    ),
                  if (widget.logo != null) const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        widget.data != null
                            ? Text(
                                widget.data!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              )
                            : Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 16,
                                  width: 100,
                                  color: Colors.grey,
                                ),
                              ),
                      ],
                    ),
                  ),
                  if (_canExpand)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black87,
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
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    if (widget.additionalDetails != null) const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
