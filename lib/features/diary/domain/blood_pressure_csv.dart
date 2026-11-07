import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';

/// Column names of the blood pressure CSV export, in order.
const bpCsvColumns = ['date', 'time', 'reading', 'arm', 'note'];

/// Builds the blood pressure export: a plain CSV with one header row and
/// then one row per reading, oldest first. No title or summary rows, so it
/// can be read directly by code (for example `pandas.read_csv`).
///
/// - `date`: yyyy-MM-dd
/// - `time`: HH:mm, 24-hour
/// - `reading`: systolic/diastolic, for example `150/98`
/// - `arm`: `left`, `right`, or empty when unknown
/// - `note`: free text, quoted when it has commas, quotes or line breaks
String buildBloodPressureCsv(List<BpReading> readings) {
  final sorted = [...readings]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final buffer = StringBuffer()..writeln(bpCsvColumns.join(','));
  for (final reading in sorted) {
    final cells = [
      _date(reading.timestamp),
      _time(reading.timestamp),
      reading.display,
      normalizeBpArm(reading.arm) ?? '',
      reading.note?.trim() ?? '',
    ];
    buffer.writeln(cells.map(_csvCell).join(','));
  }
  return buffer.toString();
}

// Built by hand (not DateFormat) so the digits are always plain ASCII,
// whatever the phone's language is.
String _two(int value) => value.toString().padLeft(2, '0');

String _date(DateTime value) =>
    '${value.year}-${_two(value.month)}-${_two(value.day)}';

String _time(DateTime value) => '${_two(value.hour)}:${_two(value.minute)}';

String _csvCell(String value) {
  const quote = '"';
  if (value.contains(',') ||
      value.contains(quote) ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '$quote${value.replaceAll(quote, quote + quote)}$quote';
  }
  return value;
}
