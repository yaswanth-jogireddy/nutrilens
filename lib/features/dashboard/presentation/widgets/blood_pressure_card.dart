import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nutrinutri/features/dashboard/presentation/blood_pressure_providers.dart';
import 'package:nutrinutri/features/dashboard/presentation/widgets/bp_category_chip.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';

/// Highlighted blood pressure summary shown at the top of the dashboard:
/// latest reading plus the last 7 days (average, highest, lowest, high count,
/// and a chart).
class BloodPressureCard extends ConsumerWidget {
  const BloodPressureCard({
    super.key,
    required this.day,
    required this.onLogBp,
  });

  /// Last day of the 7-day window (the date selected on the dashboard).
  final DateTime day;
  final VoidCallback onLogBp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(bloodPressureWindowProvider(day));

    return _BpCardFrame(
      onLogBp: onLogBp,
      subtitle: _periodLabel(day),
      child: readingsAsync.when(
        data: (readings) => _BpCardBody(day: day, readings: readings),
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Text('Error loading blood pressure: $err'),
      ),
    );
  }
}

String _periodLabel(DateTime day) {
  final now = DateTime.now();
  final isToday =
      day.year == now.year && day.month == now.month && day.day == now.day;
  if (isToday) return 'Last 7 days';
  return '7 days up to ${DateFormat('d MMM').format(day)}';
}

/// "Today 8:10 AM", "Yesterday 7:45 PM", or "Tue 3 Nov, 8:10 AM".
String bpWhenLabel(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final clock = DateFormat('h:mm a').format(time);
  if (day == today) return 'Today $clock';
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return 'Yesterday $clock';
  }
  return '${DateFormat('EEE d MMM').format(time)}, $clock';
}

class _BpCardFrame extends StatelessWidget {
  const _BpCardFrame({
    required this.onLogBp,
    required this.subtitle,
    required this.child,
  });

  final VoidCallback onLogBp;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      color: Color.alphaBlend(
        colorScheme.primaryContainer.withValues(alpha: 0.35),
        colorScheme.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  child: const Icon(Icons.monitor_heart),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Pressure',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: onLogBp,
                  tooltip: 'Log BP',
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const Gap(16),
            child,
          ],
        ),
      ),
    );
  }
}

class _BpCardBody extends StatelessWidget {
  const _BpCardBody({required this.day, required this.readings});

  final DateTime day;
  final List<BpReading> readings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final current = BpPeriod.daysEnding(day, 7);
    final stats = current.statsOf(readings);
    final previousAverage = current.previous.statsOf(readings).average;
    final latest = BpStats.from(readings).latest;

    if (latest == null) {
      return Text(
        'No BP readings in the last 2 weeks. Tap + or Log BP to add one.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LatestReading(reading: latest),
        const Gap(16),
        if (stats.isEmpty)
          Text(
            'No readings in the last 7 days.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          Text(
            '${_periodLabel(day)} · ${stats.count} '
            'reading${stats.count == 1 ? '' : 's'}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(10),
          _StatGrid(stats: stats, previousAverage: previousAverage),
          const Gap(16),
          SizedBox(
            height: 180,
            child: _BpChart(period: current, readings: stats.readings),
          ),
          const Gap(8),
          const _ChartLegend(),
        ],
      ],
    );
  }
}

class _LatestReading extends StatelessWidget {
  const _LatestReading({required this.reading});

  final BpReading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final arm = bpArmLabel(reading.arm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              reading.display,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: bpCategoryColor(reading.category, colorScheme),
              ),
            ),
            const Gap(6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'mmHg',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: BpCategoryChip(category: reading.category, large: true),
            ),
          ],
        ),
        Text(
          'Latest · ${bpWhenLabel(reading.timestamp)}'
          '${arm.isEmpty ? '' : ' · $arm'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats, required this.previousAverage});

  final BpStats stats;
  final BpAverage? previousAverage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final average = stats.average!;
    final highest = stats.highest!;
    final lowest = stats.lowest!;
    final highCount = stats.highCount;
    final previous = previousAverage;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Average',
                  value: average.display,
                  valueColor: bpCategoryColor(average.category, colorScheme),
                  detail: previous == null
                      ? 'Previous 7 days: no readings'
                      : 'Previous 7 days: ${previous.display}',
                ),
              ),
              const Gap(10),
              Expanded(
                child: _StatTile(
                  label: 'Highest',
                  value: highest.display,
                  valueColor: bpCategoryColor(highest.category, colorScheme),
                  detail: bpWhenLabel(highest.timestamp),
                ),
              ),
            ],
          ),
        ),
        const Gap(10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Lowest',
                  value: lowest.display,
                  valueColor: bpCategoryColor(lowest.category, colorScheme),
                  detail: bpWhenLabel(lowest.timestamp),
                ),
              ),
              const Gap(10),
              Expanded(
                child: _StatTile(
                  label: 'High readings',
                  value: '$highCount of ${stats.count}',
                  valueColor: bpCategoryColor(
                    highCount == 0 ? BpCategory.normal : BpCategory.high,
                    colorScheme,
                  ),
                  detail: '$bpHighLimitLabel or above',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.detail,
    this.valueColor,
  });

  final String label;
  final String value;
  final String detail;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const Gap(2),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BpChart extends StatelessWidget {
  const _BpChart({required this.period, required this.readings});

  final BpPeriod period;
  final List<BpReading> readings;

  /// Day index with each day's noon at a whole number, so weekday labels sit
  /// in the middle of their day.
  double _x(DateTime time) {
    final minutes = time.difference(period.start).inMinutes;
    return minutes / (24 * 60) - 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final systolicColor = colorScheme.primary;
    final diastolicColor = colorScheme.tertiary;
    // Neutral limit lines: the chart should inform, not alarm.
    final limitColor = colorScheme.outline;

    final systolicSpots = [
      for (final reading in readings)
        FlSpot(_x(reading.timestamp), reading.systolic.toDouble()),
    ];
    final diastolicSpots = [
      for (final reading in readings)
        FlSpot(_x(reading.timestamp), reading.diastolic.toDouble()),
    ];

    final lowestValue = readings.map((r) => r.diastolic).reduce(math.min);
    final highestValue = readings.map((r) => r.systolic).reduce(math.max);
    final minY = ((math.min(lowestValue, 60) - 10) / 20).floor() * 20.0;
    final maxY = ((math.max(highestValue, 150) + 10) / 20).ceil() * 20.0;

    HorizontalLine limitLine(double y) => HorizontalLine(
      y: y,
      color: limitColor.withValues(alpha: 0.75),
      strokeWidth: 1.5,
      dashArray: const [6, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: theme.textTheme.labelSmall?.copyWith(
          color: limitColor,
          fontWeight: FontWeight.w700,
        ),
        labelResolver: (line) => line.y.round().toString(),
      ),
    );

    return LineChart(
      LineChartData(
        minX: -0.5,
        maxX: 6.5,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            limitLine(bpHighSystolic.toDouble()),
            limitLine(bpHighDiastolic.toDouble()),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble() || value < 0 || value > 6) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(
                  period.start.year,
                  period.start.month,
                  period.start.day + value.round(),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('E').format(date),
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 34,
              getTitlesWidget: (value, meta) => Text(
                value.round().toString(),
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: systolicSpots,
            color: systolicColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: diastolicSpots,
            color: diastolicColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget item(Color color, String label, {bool dashed = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: dashed ? 2 : 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(6),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(colorScheme.primary, 'Top (systolic)'),
        item(colorScheme.tertiary, 'Bottom (diastolic)'),
        item(colorScheme.outline, 'High limit $bpHighLimitLabel', dashed: true),
      ],
    );
  }
}
