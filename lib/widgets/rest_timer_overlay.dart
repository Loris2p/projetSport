import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';

class RestTimerOverlay extends StatelessWidget {
  const RestTimerOverlay({super.key});

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    return "${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);

    if (!provider.isRestTimerActive) {
      return const SizedBox.shrink();
    }

    final total = provider.restTimerDuration;

    return ValueListenableBuilder<int>(
      valueListenable: provider.restTimerRemainingNotifier,
      builder: (context, remaining, _) {
        final progress = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xff181820),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xff2563eb).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff2563eb).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top thin progress bar
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff2563eb)),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Large Timer Circle / Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xff2563eb).withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color(0xff2563eb),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.timer_outlined,
                            color: Color(0xff60a5fa),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Timer Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "TEMPS DE REPOS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Color(0xff9ca3af),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatSeconds(remaining),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Adjust time buttons (+15s / -10s)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              final newTime = (remaining - 10).clamp(1, 3600);
                              provider.startRestTimer(newTime);
                            },
                            tooltip: "-10s",
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "-10s",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              provider.startRestTimer(remaining + 15);
                            },
                            tooltip: "+15s",
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xff2563eb).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "+15s",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff60a5fa),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xff2d2d38)),

                // Prominent "Sauter le repos" button
                InkWell(
                  onTap: () {
                    provider.stopRestTimer();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: const Color(0xffef4444).withValues(alpha: 0.15),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.skip_next_rounded, size: 20, color: Color(0xfff87171)),
                        SizedBox(width: 8),
                        Text(
                          "Sauter le repos",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xfff87171),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
