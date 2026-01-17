import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_record_sleep_phase.dart';
import 'package:sleepbalance/features/night_review/presentation/viewmodels/night_review_viewmodel.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/date_navigation_header.dart';
import '../../../../shared/widgets/ui/expandable_calendar.dart';
import '../../domain/models/sleep_record.dart';

/// Night Review screen for reviewing a specific night's sleep (UI + simple in-memory logic only).
class NightScreen extends StatefulWidget {
  const NightScreen({super.key});

  @override
  State<NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends State<NightScreen> {
  /// Currently selected date.
  DateTime _currentDate = DateTime.now();

  /// Whether the calendar is expanded or collapsed.
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentDate = _normalizeDate(_currentDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NightReviewViewmodel>().setDateAndFetchRecord(_currentDate);
    });
  }

  /// Strip time component so only year/month/day are kept.
  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Centralized handler when the user changes the date (via nav or calendar).
  void _onDateChanged(DateTime newDate) {
    final normalized = _normalizeDate(newDate);

    setState(() {
      _currentDate = normalized;
    });

    context.read<NightReviewViewmodel>().setDateAndFetchRecord(normalized);
  }

  /// Save a rating for the current date and update the UI.
  void _onRatingSelected(String rating) {
    final normalized = _normalizeDate(_currentDate);
    final viewModel = context.read<NightReviewViewmodel>();

    setState(() {
      viewModel.updateRating(rating);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NightReviewViewmodel>();
    final currentRecord = viewModel.currentRecord;
    final previousRatings = viewModel.previousRatings;
    final sleepRecordSleepPhases = viewModel.currentRecordSleepPhases;
    final targetSleepTime = viewModel.sleepTarget;
    final loading = viewModel.isLoading;

    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.6,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Night Review',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // --- Date navigation header ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DateNavigationHeader(
                  currentDate: _currentDate,
                  onPreviousDay: () {
                    _onDateChanged(
                      _currentDate.subtract(const Duration(days: 1)),
                    );
                  },
                  onNextDay: () {
                    _onDateChanged(
                      _currentDate.add(const Duration(days: 1)),
                    );
                  },
                  onDateTap: () {
                    setState(() {
                      _isCalendarExpanded = !_isCalendarExpanded;
                    });
                  },
                ),
              ),

              // --- Expandable calendar ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ExpandableCalendar(
                  selectedDate: _currentDate,
                  isExpanded: _isCalendarExpanded,
                  onDateSelected: (date) => _onDateChanged(date),
                  onToggleExpansion: () {
                    setState(() {
                      _isCalendarExpanded = !_isCalendarExpanded;
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              // --- Main content ---
              mainContent(
                currentRecord,
                previousRatings,
                sleepRecordSleepPhases,
                targetSleepTime,
                loading
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the main content area with sleep record details or loading/empty state.
  Widget mainContent(
    SleepRecord? sleepRecord,
    Map<DateTime, String?>? previousRatings,
    List<SleepRecordSleepPhase>? sleepRecordSleepPhases,
    int? targetSleepTime,
    bool loading
  ) {
    if (loading) {
      return CircularProgressIndicator();
    }

    if (sleepRecord == null) {
      return Text("No Data available...");
    }

    final dateLabel = DateFormat('EEE, MMM d').format(_currentDate);

    previousRatings ??= {};

    return
      Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NightSummaryCard(
                dateLabel: dateLabel,
                sleepRecord: sleepRecord,
                sleepRecordSleepPhases: sleepRecordSleepPhases,
                targetSleeptime: targetSleepTime,
              ),

              const SizedBox(height: 24),

              _SleepStageSummaryRow(sleepRecord: sleepRecord),

              const SizedBox(height: 16),

              const _HeartRateSummaryCard(),

              const SizedBox(height: 24),

              _RatingSection(
                selectedRating: sleepRecord.qualityRating,
                onRatingSelected: _onRatingSelected,
              ),

              const SizedBox(height: 24),

              // Comparison is intentionally at the very bottom
              _ComparisonCard(
                currentDate: _currentDate,
                currentRating: sleepRecord.qualityRating,
                ratingsByDate: previousRatings,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
  }
}

/// ------------------------------------------------------------
/// NIGHT SUMMARY CARD – total duration, timeline-style stages, legend
/// ------------------------------------------------------------
class _NightSummaryCard extends StatelessWidget {
  const _NightSummaryCard({
    required this.dateLabel,
    required this.sleepRecord,
    required this.sleepRecordSleepPhases,
    required this.targetSleeptime
  });

  final String dateLabel;
  final SleepRecord sleepRecord;
  final List<SleepRecordSleepPhase>? sleepRecordSleepPhases;
  final int? targetSleeptime;

  @override
  Widget build(BuildContext context) {
    final sleepDuration = formatTime(sleepRecord.totalSleepTime);
    final difference = targetSleeptime != null && sleepRecord.totalSleepTime != null
        ? targetSleeptime! - sleepRecord.totalSleepTime!
        : 0;

    final differenceText = Text(
      '${difference > 0 ? "-" : '+'}${formatTime(difference.abs())}',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: difference > 0 ? Colors.red : Colors.green,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.bedtime, size: 36, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sleepDuration,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                          'Zielschlaf-Differenz: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                      ),
                      differenceText,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Night View',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Timeline-style sleep stages (no vertical bars)
          SizedBox(
            height: 140,
            child: _SleepStageTimeline(sleepRecord: sleepRecord, sleepRecordSleepPhases: sleepRecordSleepPhases)
          ),

          const SizedBox(height: 8),

          // Time labels at the bottom of the chart
          SleepHourlyAxis(
            start: sleepRecord.sleepStartTime!,
            end: sleepRecord.sleepEndTime!,
            maxLabels: 4,
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _LegendDot(label: 'Awake', color: Color(0xFF4DD0E1)),
              _LegendDot(label: 'REM', color: Color(0xFF7C4DFF)),
              _LegendDot(label: 'Light', color: Color(0xFF42A5F5)),
              _LegendDot(label: 'Deep', color: Color(0xFF1565C0)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Different sleep stage types used in the timeline chart.
enum _SleepStageType { awake, rem, light, deep }

/// One segment on the timeline, using [start] and [end] as fractions (0–1) of width.
class _SleepSegment {
  final double start; // 0.0 .. 1.0
  final double end; // 0.0 .. 1.0
  final _SleepStageType type;

  const _SleepSegment({
    required this.start,
    required this.end,
    required this.type,
  });
}

/// Timeline widget that uses a CustomPainter to draw stage blocks.
class _SleepStageTimeline extends StatelessWidget {
  const _SleepStageTimeline({ required this.sleepRecord, required this.sleepRecordSleepPhases });

  final SleepRecord sleepRecord;
  final List<SleepRecordSleepPhase>? sleepRecordSleepPhases;

  @override
  Widget build(BuildContext context) {
    if (sleepRecordSleepPhases == null) {
      return Text("Not Available");
    }

    return CustomPaint(
      painter: _SleepTimelinePainter(sleepRecord: sleepRecord, sleepRecordSleepPhases: sleepRecordSleepPhases!),
      child: const SizedBox.expand(),
    );
  }
}

class _SleepTimelinePainter extends CustomPainter {
  /// Initializes painter and converts sleep phases into normalized timeline segments.
  _SleepTimelinePainter({
    required this.sleepRecord,
    required List<SleepRecordSleepPhase> sleepRecordSleepPhases,
  }) : sleepRecordSleepPhases = List.of(sleepRecordSleepPhases) {
    final sleepStart = sleepRecord.sleepStartTime!;
    final totalSeconds = sleepRecord.totalSleepTime! * 60; // minutes -> seconds
    final step = 1.0 / totalSeconds;

    // Ensure correct order (prevents overlaps / weird rendering)
    this.sleepRecordSleepPhases.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    _segments = <_SleepSegment>[];
    for (final srsp in this.sleepRecordSleepPhases) {
      final startSeconds = srsp.startedAt.difference(sleepStart).inSeconds;
      final durationSeconds = srsp.duration; // already seconds

      var start = (startSeconds * step).clamp(0.0, 1.0);
      var end = ((startSeconds + durationSeconds) * step).clamp(0.0, 1.0);

      // Skip invalid/empty segments
      if (end <= start) continue;

      _segments.add(_SleepSegment(
        start: start,
        end: end,
        type: getStageType(srsp),
      ));
    }
  }

  /// Converts sleep phase ID to the corresponding stage type for visualization.
  static _SleepStageType getStageType(SleepRecordSleepPhase p) => switch (p.sleepPhaseId) {
    SLEEP_PHASE_DEEP => _SleepStageType.deep,
    SLEEP_PHASE_LIGHT => _SleepStageType.light,
    SLEEP_PHASE_REM => _SleepStageType.rem,
    SLEEP_PHASE_WAKE => _SleepStageType.awake,
    _ => throw Exception("Sleep Stage Type not implemented"),
  };

  final SleepRecord sleepRecord;
  final List<SleepRecordSleepPhase> sleepRecordSleepPhases;
  late final List<_SleepSegment> _segments;

  /// Returns the display color for a given sleep stage type.
  Color _colorForStage(_SleepStageType type) {
    switch (type) {
      case _SleepStageType.awake:
        return const Color(0xFF4DD0E1);
      case _SleepStageType.rem:
        return const Color(0xFF7C4DFF);
      case _SleepStageType.light:
        return const Color(0xFF42A5F5);
      case _SleepStageType.deep:
        return const Color(0xFF1565C0);
    }
  }

  /// Returns the vertical center position for a given sleep stage type in the timeline.
  double _centerYForStage(_SleepStageType type, double height) {
    switch (type) {
      case _SleepStageType.awake:
        return height * 0.25;
      case _SleepStageType.rem:
        return height * 0.40;
      case _SleepStageType.light:
        return height * 0.60;
      case _SleepStageType.deep:
        return height * 0.78;
    }
  }

  /// Paints the sleep stage timeline with grid lines and colored stage blocks.
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final dy = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), backgroundPaint);
    }

    for (final segment in _segments) {
      final x1 = segment.start * size.width;
      final x2 = segment.end * size.width;

      // Make tiny segments still visible (optional but helps)
      final width = (x2 - x1).clamp(1.0, size.width);

      final centerY = _centerYForStage(segment.type, size.height);
      final blockHeight = size.height * 0.18;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x1 + width / 2, centerY),
          width: width,
          height: blockHeight,
        ),
        const Radius.circular(6),
      );

      final paint = Paint()
        ..color = _colorForStage(segment.type)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);
    }
  }

  /// Determines if repainting is needed when painter is updated.
  @override
  bool shouldRepaint(covariant _SleepTimelinePainter old) {
    // important: repaint when new record/phases are provided
    return old.sleepRecord != sleepRecord ||
        old.sleepRecordSleepPhases.length != sleepRecordSleepPhases.length;
  }
}

/// Displays hourly time labels along the bottom of the sleep timeline.
class SleepHourlyAxis extends StatelessWidget {
  const SleepHourlyAxis({
    super.key,
    required this.start,
    required this.end,
    this.maxLabels = 6,
  });

  final DateTime start;
  final DateTime end;
  final int maxLabels;

  @override
  Widget build(BuildContext context) {
    final labels = _hourTicks(start, end, maxLabels);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (t) => Text(
          _fmtHHmm(t),
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      )
          .toList(),
    );
  }

  /// Generates evenly-spaced hourly time ticks between start and end, respecting maxLabels limit.
  static List<DateTime> _hourTicks(DateTime start, DateTime end, int maxLabels) {
    if (!end.isAfter(start)) return [start, end];

    final ticks = <DateTime>[start];

    final firstFullHour = DateTime(start.year, start.month, start.day, start.hour)
        .add(const Duration(hours: 1));

    for (var t = firstFullHour; t.isBefore(end); t = t.add(const Duration(hours: 1))) {
      ticks.add(t);
    }

    ticks.add(end);

    if (ticks.length <= maxLabels) return ticks;

    final desiredMiddle = maxLabels - 2;
    if (desiredMiddle <= 0) return [start, end];

    final middle = ticks.sublist(1, ticks.length - 1);

    final sampled = <DateTime>[start];
    for (int i = 0; i < desiredMiddle; i++) {
      final idx = ((i + 1) * (middle.length) / (desiredMiddle + 1)).round() - 1;
      final clamped = idx.clamp(0, middle.length - 1);
      final candidate = middle[clamped];

      if (sampled.last != candidate) sampled.add(candidate);
    }

    if (sampled.last != end) sampled.add(end);

    final result = <DateTime>[];
    for (final t in sampled) {
      if (result.isEmpty || result.last != t) result.add(t);
    }
    return result;
  }


  /// Formats a DateTime to HH:mm string format.
  static String _fmtHHmm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Legend dot + label for the chart.
class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// SMALL STAGE CARDS: Awake / REM / Deep
/// ------------------------------------------------------------
/// Row displaying summary cards for Awake, REM, and Deep sleep durations.
class _SleepStageSummaryRow extends StatelessWidget {
  const _SleepStageSummaryRow({ required this.sleepRecord });

  final SleepRecord sleepRecord;

  @override
  Widget build(BuildContext context) {
    final awake = formatTime(sleepRecord.awakeDuration);
    final rem = formatTime(sleepRecord.remSleepDuration);
    final deep = formatTime(sleepRecord.deepSleepDuration);

    return Row(
      children: [
        Expanded(
          child: _StageStat(
            title: 'Awake',
            value: awake,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StageStat(
            title: 'REM',
            value: rem,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StageStat(
            title: 'Deep',
            value: deep,
          ),
        ),
      ],
    );
  }
}

/// Individual sleep stage stat card displaying title and formatted time value.
class _StageStat extends StatelessWidget {
  final String title;
  final String value;

  const _StageStat({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// HEART RATE SUMMARY CARD (UI only, fake data)
/// ------------------------------------------------------------
/// Heart rate summary card with fake chart and min/average/max values.
/// Todo: implement real data.
class _HeartRateSummaryCard extends StatelessWidget {
  const _HeartRateSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.favorite, size: 20, color: Colors.pinkAccent),
              SizedBox(width: 8),
              Text(
                'Heart rate during sleep',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Resting heart rate (example values only).',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CustomPaint(
              painter: _FakeHeartRatePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _HeartRateValue(label: 'Min', value: '52 bpm'),
              _HeartRateValue(label: 'Average', value: '63 bpm'),
              _HeartRateValue(label: 'Max', value: '92 bpm'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Displays a single heart rate metric with label and value.
class _HeartRateValue extends StatelessWidget {
  final String label;
  final String value;

  const _HeartRateValue({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

/// Very simple fake line chart for heart rate.
/// Very simple fake line chart for heart rate.
class _FakeHeartRatePainter extends CustomPainter {
  /// Paints a simple line path with predefined points for visual effect.
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE1BEE7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.6),
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.35),
      Offset(size.width * 0.3, size.height * 0.55),
      Offset(size.width * 0.4, size.height * 0.45),
      Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.55),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.62),
      Offset(size.width, size.height * 0.55),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, paint);
  }

  /// Always returns false as fake chart data never changes.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ------------------------------------------------------------
/// SUBJECTIVE RATING: Bad / Average / Good
/// ------------------------------------------------------------
/// Section for selecting subjective sleep quality rating (Bad/Average/Good).
class _RatingSection extends StatelessWidget {
  const _RatingSection({
    required this.selectedRating,
    required this.onRatingSelected,
  });

  final String? selectedRating;
  final ValueChanged<String> onRatingSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How did this night feel?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap a button to save your subjective sleep quality for this night.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RatingButton(
                label: 'Bad',
                emoji: '😴',
                value: 'bad',
                isSelected: selectedRating == 'bad',
                onTap: () => onRatingSelected('bad'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RatingButton(
                label: 'Average',
                emoji: '😐',
                value: 'average',
                isSelected: selectedRating == 'average',
                onTap: () => onRatingSelected('average'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RatingButton(
                label: 'Good',
                emoji: '😊',
                value: 'good',
                isSelected: selectedRating == 'good',
                onTap: () => onRatingSelected('good'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Animated button for selecting a sleep quality rating with emoji indicator.
class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.emoji,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Blue-ish highlight when selected, subtle gray otherwise.
    final baseColor = Colors.white.withOpacity(0.08);
    final selectedColor = const Color(0xFF3B5998).withOpacity(0.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : baseColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.85)
                : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// COMPARISON TO YOUR AVERAGE – rolling 7-day window + mini line chart.
/// ------------------------------------------------------------
/// Comparison card showing how current night's rating compares to 7-day rolling average.
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.currentDate,
    required this.currentRating,
    required this.ratingsByDate,
  });

  final DateTime currentDate;
  final String? currentRating;
  final Map<DateTime, String?> ratingsByDate;

  /// Converts string rating to numeric score (bad=0, average=1, good=2).
  int? _ratingToScore(String? rating) {
    switch (rating) {
      case 'bad':
        return 0;
      case 'average':
        return 1;
      case 'good':
        return 2;
    }
    return null;
  }

  /// Converts numeric score to human-readable label.
  String _scoreToLabel(int score) {
    switch (score) {
      case 0:
        return 'mostly bad';
      case 1:
        return 'mostly average';
      case 2:
        return 'mostly good';
      default:
        return 'mixed';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normalize current date to year-month-day (no time part).
    final normalizedCurrent =
    DateTime(currentDate.year, currentDate.month, currentDate.day);

    // 7-day window ending on the selected date: [day-6, ..., day].
    final List<DateTime> weekDays = List.generate(
      7,
          (i) => normalizedCurrent.subtract(Duration(days: 6 - i)),
    );

    // Scores from previous 6 days only.
    final previousScores = <int>[];
    for (int i = 0; i < 6; i++) {
      final day = weekDays[i];
      final rating = ratingsByDate[day];
      final score = _ratingToScore(rating);
      if (score != null) previousScores.add(score);
    }

    String bodyText;

    if (currentRating == null) {
      bodyText =
      'Rate this night to see how it compares to your usual nights in this week.';
    } else if (previousScores.isEmpty) {
      bodyText =
      'Once you have rated a few nights in this week, we will show whether this night felt better or worse than usual.';
    } else {
      final currentScore = _ratingToScore(currentRating)!;
      final average =
          previousScores.reduce((a, b) => a + b) / previousScores.length;

      late String comparison;
      if (currentScore > average + 0.25) {
        comparison = 'better than your usual nights';
      } else if (currentScore < average - 0.25) {
        comparison = 'worse than your usual nights';
      } else {
        comparison = 'similar to your usual nights';
      }

      bodyText =
      'Based on your ratings from the last 6 days, this night felt $comparison.\n'
          'Your recent nights were ${_scoreToLabel(average.round())}.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparison to your average',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bodyText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),

          // Weekly mini line chart.
          _WeekRatingChart(
            weekDays: weekDays,
            ratingsByDate: ratingsByDate,
            currentDate: normalizedCurrent,
          ),
        ],
      ),
    );
  }
}

/// Small weekly line chart for the last 7 days (ending on currentDate).
/// x-axis: 7 consecutive days, labeled with weekday abbreviations.
/// y-axis: Good / Average / Bad.
class _WeekRatingChart extends StatelessWidget {
  const _WeekRatingChart({
    required this.weekDays,
    required this.ratingsByDate,
    required this.currentDate,
  });

  final List<DateTime> weekDays; // length == 7, chronological
  final Map<DateTime, String?> ratingsByDate;
  final DateTime currentDate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _WeekRatingPainter(
          weekDays: weekDays,
          ratingsByDate: ratingsByDate,
          currentDate: currentDate,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Renders a weekly rating line chart with grid lines, points, and weekday labels.
class _WeekRatingPainter extends CustomPainter {
  /// Initializes painter with week days, rating history, and current date for highlighting.
  _WeekRatingPainter({
    required this.weekDays,
    required this.ratingsByDate,
    required this.currentDate,
  });

  final List<DateTime> weekDays;
  final Map<DateTime, String?> ratingsByDate;
  final DateTime currentDate;

  /// Converts string rating to numeric score (bad=0, average=1, good=2).
  int? _ratingToScore(String? rating) {
    switch (rating) {
      case 'bad':
        return 0;
      case 'average':
        return 1;
      case 'good':
        return 2;
    }
    return null;
  }

  /// Paints the weekly chart with grid lines, rating points, connecting lines, and labels.
  @override
  void paint(Canvas canvas, Size size) {
    const paddingLeft = 40.0;
    const paddingRight = 8.0;
    const paddingTop = 8.0;
    const paddingBottom = 22.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;
    final baseBottom = paddingTop + chartHeight;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Map score (0=bad, 1=average, 2=good) to y-position.
    double yForScore(int score) {
      final step = chartHeight / 2; // 3 levels: 0,1,2
      return baseBottom - score * step;
    }

    double xForIndex(int index) {
      if (weekDays.length == 1) return paddingLeft;
      return paddingLeft + (chartWidth * index / (weekDays.length - 1));
    }

    // Draw horizontal grid lines + y labels (Good / Average / Bad).
    const levels = [
      {'label': 'Good', 'score': 2},
      {'label': 'Average', 'score': 1},
      {'label': 'Bad', 'score': 0},
    ];

    for (final level in levels) {
      final score = level['score']! as int;
      final y = yForScore(score);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: level['label']! as String,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Build list of points for rated days.
    final points = <Offset>[];
    final scores = <int?>[];

    for (int i = 0; i < weekDays.length; i++) {
      final day = DateTime(weekDays[i].year, weekDays[i].month, weekDays[i].day);
      final rating = ratingsByDate[day];
      final score = _ratingToScore(rating);
      scores.add(score);

      if (score != null) {
        points.add(Offset(xForIndex(i), yForScore(score)));
      } else {
        points.add(Offset(xForIndex(i), yForScore(1))); // placeholder y
      }
    }

    // Draw line connecting only consecutive rated days.
    Offset? lastRatedPoint;
    for (int i = 0; i < weekDays.length; i++) {
      final score = scores[i];
      final pt = points[i];

      if (score != null) {
        if (lastRatedPoint != null) {
          canvas.drawLine(lastRatedPoint, pt, linePaint);
        }
        lastRatedPoint = pt;
      } else {
        lastRatedPoint = null;
      }
    }

    // Draw points (small circles) for rated days.
    for (int i = 0; i < weekDays.length; i++) {
      final score = scores[i];
      final pt = points[i];
      if (score != null) {
        canvas.drawCircle(pt, 3.0, pointPaint);
      }
    }

    // Highlight current date if it has a rating.
    final currentIndex =
    weekDays.indexWhere((d) => d.year == currentDate.year && d.month == currentDate.month && d.day == currentDate.day);
    if (currentIndex != -1 && scores[currentIndex] != null) {
      final pt = points[currentIndex];
      canvas.drawCircle(
        pt,
        5.0,
        Paint()
          ..color = const Color(0xFF3B5998)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(pt, 5.0, pointPaint..strokeWidth = 1..style = PaintingStyle.stroke);
    }

    // Draw weekday labels at the bottom (Mon, Tue, ...).
    for (int i = 0; i < weekDays.length; i++) {
      final day = weekDays[i];
      final label = DateFormat('E').format(day); // e.g. Mon, Tue
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final x = xForIndex(i) - tp.width / 2;
      final y = baseBottom + 4;
      tp.paint(canvas, Offset(x, y));
    }
  }

  /// Determines if repainting is needed when week data or current date changes.
  @override
  bool shouldRepaint(covariant _WeekRatingPainter oldDelegate) =>
      oldDelegate.weekDays != weekDays ||
          oldDelegate.ratingsByDate != ratingsByDate ||
          oldDelegate.currentDate != currentDate;
}

/// Formats time in minutes to human-readable string (e.g. "7h 30m").
String formatTime(int? timeInMinutes) {
  if (timeInMinutes == null) {
    return "0m";
  }

  final hours = (timeInMinutes / 60).floor();
  final minutes = timeInMinutes % 60;

  if (hours == 0) {
    return "${minutes}m";
  }

  return "${hours}h ${minutes}m";
}