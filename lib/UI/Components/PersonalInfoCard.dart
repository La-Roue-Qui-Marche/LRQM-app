import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utils/config.dart';
import 'DifferenceGraph.dart';

class PersonalInfoCard extends StatefulWidget {
  final bool isSessionActive;
  final String logoPath;
  final String bibNumber;
  final String userName;
  final String contribution;
  final String totalTime;

  const PersonalInfoCard({
    super.key,
    required this.isSessionActive,
    required this.logoPath,
    required this.bibNumber,
    required this.userName,
    required this.contribution,
    required this.totalTime,
  });

  @override
  State<PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<PersonalInfoCard> {
  final GlobalKey<DifferenceGraphState> _differenceGraphKey = GlobalKey<DifferenceGraphState>(); // Updated type

  @override
  void didUpdateWidget(covariant PersonalInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSessionActive && oldWidget.isSessionActive) {
      _differenceGraphKey.currentState?.stopAndClearGraph(); // Stop and clear the graph
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ta contribution à l\'événement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(Config.COLOR_APP_BAR),
                ),
              ),
              const SizedBox(height: 12),

              /// Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      widget.logoPath,
                      width: widget.isSessionActive ? 32 : 28,
                      height: widget.isSessionActive ? 32 : 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '№ de dossard: ${widget.bibNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        widget.userName.isNotEmpty
                            ? Text(
                                widget.userName,
                                style: const TextStyle(
                                  fontSize: 14,
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
                ],
              ),

              const SizedBox(height: 24),

              /// Metrics
              Row(
                children: [
                  /// Contribution
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(Config.COLOR_BACKGROUND).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contribution',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          widget.contribution.isNotEmpty
                              ? Text(
                                  _formatDistance(widget.contribution),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(Config.COLOR_APP_BAR),
                                  ),
                                )
                              : Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    height: 20,
                                    width: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  /// Total time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Temps total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        widget.totalTime.isNotEmpty
                            ? Text(
                                widget.totalTime,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              )
                            : Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 20,
                                  width: 80,
                                  color: Colors.grey,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4), // Add spacing between rows

              /// Distance message row
              Row(
                children: [
                  Expanded(
                    child: widget.contribution.isNotEmpty
                        ? Text(
                            _getDistanceMessage(
                              int.tryParse(widget.contribution.replaceAll("'", "").replaceAll(" m", "")) ?? 0,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.left,
                          )
                        : Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 16,
                              width: double.infinity,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              /// Difference Graph
              if (widget.isSessionActive) DifferenceGraph(key: _differenceGraphKey), // Attach the key to the graph
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: widget.isSessionActive
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(Config.COLOR_APP_BAR),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        RecordingIndicator(),
                        SizedBox(width: 6),
                        Text(
                          'Actif',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        PausedIndicator(),
                        SizedBox(width: 6),
                        Text(
                          'En pause',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(String? distance) {
    if (distance == null) return '';
    return distance.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}\'');
  }

  String _getDistanceMessage(int distance) {
    if (distance <= 100) {
      return "C'est ${(distance / 0.2).toStringAsFixed(0)} saucisse aux choux mis bout à bout. Quel papet! Continue comme ça";
    } else if (distance <= 4000) {
      return "C'est ${(distance / 400).toStringAsFixed(1)} tour(s) de la piste de la pontaise. Trop fort!";
    } else if (distance <= 38400) {
      return "C'est ${(distance / 12800).toStringAsFixed(1)} fois la distance Bottens-Lausanne. Tu es un champion, n'oublie pas de boire!";
    } else {
      return "C'est ${(distance / 42195).toStringAsFixed(1)} marathon. Tu as une forme et une détermination fantastique. Pense à reprendre des forces";
    }
  }
}

class RecordingIndicator extends StatefulWidget {
  const RecordingIndicator({super.key});

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class PausedIndicator extends StatelessWidget {
  const PausedIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}
