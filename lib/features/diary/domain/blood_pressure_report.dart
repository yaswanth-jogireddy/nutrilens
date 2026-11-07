import 'package:intl/intl.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';

/// Builds the blood pressure CSV report: a summary block at the top, a
/// week-by-week summary, then every reading with its date and time.
///
/// Readings may be passed in any order. [now] decides which days count as
/// "Last 7 days" and "Last 30 days".
String buildBloodPressureReportCsv(
  List<BpReading> readings, {
  required DateTime now,
}) {
  final all = BpStats.from(readings);
  final today = DateTime(now.year, now.month, now.day);
  final last7 = BpPeriod.daysEnding(today, 7);
  final last30 = BpPeriod.daysEnding(today, 30);
  final lines = <List<Object?>>[];

  lines
    ..add(['Blood Pressure Report'])
    ..add(['Exported on', _dateTime(now)])
    ..add(['Total readings', all.count]);
  if (!all.isEmpty) {
    lines
      ..add(['First reading', _dateTime(all.readings.first.timestamp)])
      ..add(['Latest reading', _dateTime(all.readings.last.timestamp)]);
  }
  lines
    ..add(['High means', '$bpHighLimitLabel or above'])
    ..add(const [])
    ..add(['SUMMARY'])
    ..add(['Period', ..._summaryHeaders])
    ..add(['Last 7 days', ..._summaryCells(last7, last7.statsOf(readings))])
    ..add([
      'Previous 7 days',
      ..._summaryCells(last7.previous, last7.previous.statsOf(readings)),
    ])
    ..add(['Last 30 days', ..._summaryCells(last30, last30.statsOf(readings))]);
  if (!all.isEmpty) {
    lines.add([
      'All readings',
      ..._summaryCells(
        BpPeriod(
          start: _startOfDay(all.readings.first.timestamp),
          end: _startOfDay(all.readings.last.timestamp).add(
            const Duration(days: 1),
          ),
        ),
        all,
      ),
    ]);
  }

  lines
    ..add(const [])
    ..add(['WEEKLY SUMMARY (Monday to Sunday)'])
    ..add(['Week', ..._summaryHeaders]);
  final weeks = <BpPeriod>{
    for (final reading in all.readings) BpPeriod.weekOf(reading.timestamp),
  }.toList()..sort((a, b) => b.start.compareTo(a.start));
  if (weeks.isEmpty) {
    lines.add(['No readings yet']);
  }
  for (final week in weeks) {
    lines.add([
      'Week of ${_date(week.start)}',
      ..._summaryCells(week, week.statsOf(all.readings)),
    ]);
  }

  lines
    ..add(const [])
    ..add(['ALL READINGS (newest first)'])
    ..add(const ['Date', 'Time', 'Reading', 'Arm', 'Note']);
  // Just what was written down: no status labels next to each reading.
  for (final reading in all.readings.reversed) {
    lines.add([
      _date(reading.timestamp),
      _time(reading.timestamp),
      reading.display,
      bpArmLabel(reading.arm),
      reading.note?.trim() ?? '',
    ]);
  }

  final buffer = StringBuffer();
  for (final line in lines) {
    buffer.writeln(line.map(_csvCell).join(','));
  }
  return buffer.toString();
}

const _summaryHeaders = [
  'From',
  'To',
  'Readings',
  'Average',
  'Average status',
  'Highest',
  'Highest on',
  'Lowest',
  'Lowest on',
  'High readings ($bpHighLimitLabel+)',
];

List<Object?> _summaryCells(BpPeriod period, BpStats stats) {
  final average = stats.average;
  final highest = stats.highest;
  final lowest = stats.lowest;
  return [
    _date(period.start),
    _date(period.lastDay),
    stats.count,
    average?.display,
    average?.category.label,
    highest?.display,
    highest == null ? null : _dateTime(highest.timestamp),
    lowest?.display,
    lowest == null ? null : _dateTime(lowest.timestamp),
    stats.isEmpty ? null : '${stats.highCount} of ${stats.count}',
  ];
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _date(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

String _time(DateTime value) => DateFormat('h:mm a').format(value);

String _dateTime(DateTime value) => '${_date(value)} ${_time(value)}';

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  const quote = '"';
  if (text.contains(',') ||
      text.contains(quote) ||
      text.contains('\n') ||
      text.contains('\r')) {
    return '$quote${text.replaceAll(quote, quote + quote)}$quote';
  }
  return text;
}
