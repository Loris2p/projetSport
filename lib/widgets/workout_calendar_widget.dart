import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/workout_session.dart';
import '../providers/workout_provider.dart';
import '../screens/workout_summary_screen.dart';

class WorkoutCalendarWidget extends StatefulWidget {
  final bool isCompact;

  const WorkoutCalendarWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  State<WorkoutCalendarWidget> createState() => _WorkoutCalendarWidgetState();
}

class _WorkoutCalendarWidgetState extends State<WorkoutCalendarWidget> {
  late DateTime _displayedMonth;
  bool _isCompactView = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _isCompactView = widget.isCompact;
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _resetToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final now = DateTime.now();

    final String monthName = DateFormat('MMMM yyyy', 'fr_FR').format(_displayedMonth);
    final String capitalizedMonth = monthName.isNotEmpty
        ? monthName[0].toUpperCase() + monthName.substring(1)
        : '';

    final streak = workoutProvider.currentStreak;
    final activeDaysCount = workoutProvider.getActiveDaysCountForMonth(_displayedMonth.year, _displayedMonth.month);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1e1e24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff2d2d34), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MON HISTORIQUE",
                    style: TextStyle(
                      color: Color(0xff2563eb),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _resetToCurrentMonth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          capitalizedMonth,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_displayedMonth.year != now.year || _displayedMonth.month != now.month) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.today, size: 16, color: Color(0xff2563eb)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (streak > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xfff97316), Color(0xffea580c)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xfff97316).withAlpha(76),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$streak j",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _previousMonth,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Days Badge Progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xff121214),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xff2d2d34)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xffeab308), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "$activeDaysCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(text: " / $daysInMonth jours actifs ce mois-ci"),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isCompactView = !_isCompactView;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Text(
                          _isCompactView ? "Mois" : "7 Jours",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff2563eb),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          _isCompactView ? Icons.calendar_month : Icons.view_week,
                          size: 14,
                          color: const Color(0xff2563eb),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Calendar Days Grid or Weekly View
          if (_isCompactView)
            _buildWeeklyView(context, workoutProvider, now)
          else
            _buildMonthlyView(context, workoutProvider, now),
        ],
      ),
    );
  }

  Widget _buildWeeklyView(BuildContext context, WorkoutProvider workoutProvider, DateTime now) {
    // Current week starting from Monday
    final currentMonday = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = currentMonday.add(Duration(days: index));
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        final sessions = workoutProvider.getSessionsForDate(date);
        final hasSession = sessions.isNotEmpty;

        final weekDayName = DateFormat('E', 'fr_FR').format(date).substring(0, 1).toUpperCase();

        return _buildDayCell(
          context: context,
          date: date,
          dayText: "${date.day}",
          subText: weekDayName,
          isToday: isToday,
          hasSession: hasSession,
          sessions: sessions,
          isCurrentMonth: true,
        );
      }),
    );
  }

  Widget _buildMonthlyView(BuildContext context, WorkoutProvider workoutProvider, DateTime now) {
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday; // 1 = Lun, 7 = Dim

    final weekDays = ["L", "M", "M", "J", "V", "S", "D"];

    return Column(
      children: [
        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            return SizedBox(
              width: 32,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42, // 6 weeks * 7 days
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final dayOffset = index - (firstWeekday - 1);
            if (dayOffset < 0 || dayOffset >= daysInMonth) {
              return const SizedBox.shrink();
            }

            final dayNumber = dayOffset + 1;
            final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
            final sessions = workoutProvider.getSessionsForDate(date);
            final hasSession = sessions.isNotEmpty;

            return _buildDayCell(
              context: context,
              date: date,
              dayText: "$dayNumber",
              isToday: isToday,
              hasSession: hasSession,
              sessions: sessions,
              isCurrentMonth: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime date,
    required String dayText,
    String? subText,
    required bool isToday,
    required bool hasSession,
    required List<WorkoutSession> sessions,
    required bool isCurrentMonth,
  }) {
    Color bgColor = const Color(0xff121214);
    Color textColor = Colors.white;
    Border? border;

    if (hasSession) {
      bgColor = const Color(0xff2563eb);
      textColor = Colors.white;
    } else if (isToday) {
      border = Border.all(color: const Color(0xff38bdf8), width: 2);
    } else {
      border = Border.all(color: const Color(0xff2d2d34));
    }

    return InkWell(
      onTap: hasSession
          ? () => _showDaySessionsBottomSheet(context, date, sessions)
          : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: border,
          boxShadow: hasSession
              ? [
                  BoxShadow(
                    color: const Color(0xff2563eb).withAlpha(100),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subText != null)
                  Text(
                    subText,
                    style: TextStyle(
                      fontSize: 10,
                      color: hasSession ? Colors.white70 : Colors.grey[400],
                    ),
                  ),
                Text(
                  dayText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasSession || isToday ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ],
            ),
            if (hasSession)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDaySessionsBottomSheet(
    BuildContext context,
    DateTime date,
    List<WorkoutSession> sessions,
  ) {
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final String formattedDate = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    final String capitalizedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xff10b981), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capitalizedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${sessions.length} séance(s) effectuée(s)",
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: sessions.map((session) {
                      final duration = session.endTime != null
                          ? session.endTime!.difference(session.startTime).inMinutes
                          : 0;
                      final volume = workoutProvider.calculateSessionVolume(session);
                      final summary = workoutProvider.getSessionExercisesSummary(session);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xff1e1e24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xff2d2d34)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            session.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "⏱️ ${duration > 0 ? '$duration min' : 'Temps libre'}  •  🏋️ ${(volume / 1000).toStringAsFixed(2)} T",
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                              if (summary.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutSummaryScreen(session: session),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
