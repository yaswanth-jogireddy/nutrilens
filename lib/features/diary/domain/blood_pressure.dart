// Blood pressure domain logic shared by the dashboard card and the BP export.
//
// Categories follow the ISH 2020 / Indian hypertension guideline, where a
// reading of 140/90 or above counts as high.

/// Systolic/diastolic limit at or above which a reading counts as high.
const bpHighSystolic = 140;
const bpHighDiastolic = 90;
const bpHighLimitLabel = '$bpHighSystolic/$bpHighDiastolic';

/// Accepted input range, wide enough for any real home reading.
const bpMinSystolic = 50;
const bpMaxSystolic = 300;
const bpMinDiastolic = 30;
const bpMaxDiastolic = 200;

enum BpCategory {
  low('Low', 'Below 90/60'),
  normal('Normal', 'Below 130/85'),
  highNormal('High-normal', '130-139 / 85-89'),
  high('High', '140/90 or above'),
  veryHigh('Very high', '160/100 or above'),
  dangerous('Dangerous', '180/110 or above - call a doctor');

  const BpCategory(this.label, this.rangeLabel);

  final String label;
  final String rangeLabel;

  /// True for readings at or above the 140/90 limit.
  bool get isHigh => index >= BpCategory.high.index;

  /// True for readings from 90/60 up to (not including) 140/90.
  bool get isInRange =>
      this == BpCategory.normal || this == BpCategory.highNormal;

  static BpCategory classify(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 110) return BpCategory.dangerous;
    if (systolic >= 160 || diastolic >= 100) return BpCategory.veryHigh;
    if (systolic >= bpHighSystolic || diastolic >= bpHighDiastolic) {
      return BpCategory.high;
    }
    if (systolic >= 130 || diastolic >= 85) return BpCategory.highNormal;
    if (systolic < 90 || diastolic < 60) return BpCategory.low;
    return BpCategory.normal;
  }
}

/// Normalizes a stored arm value to `left`, `right`, or null when unknown.
String? normalizeBpArm(String? value) {
  final arm = value?.trim().toLowerCase();
  return switch (arm) {
    'left' || 'l' || 'left_arm' => 'left',
    'right' || 'r' || 'right_arm' => 'right',
    _ => null,
  };
}

String bpArmLabel(String? value) {
  return switch (normalizeBpArm(value)) {
    'left' => 'Left arm',
    'right' => 'Right arm',
    _ => '',
  };
}

/// Returns an error message when the numbers are not a plausible reading.
String? validateBpReading(int? systolic, int? diastolic) {
  if (systolic == null || diastolic == null) {
    return 'Enter both the top and bottom numbers.';
  }
  if (systolic < bpMinSystolic || systolic > bpMaxSystolic) {
    return 'Top number should be between $bpMinSystolic and $bpMaxSystolic.';
  }
  if (diastolic < bpMinDiastolic || diastolic > bpMaxDiastolic) {
    return 'Bottom number should be between $bpMinDiastolic and '
        '$bpMaxDiastolic.';
  }
  if (systolic <= diastolic) {
    return 'Top number must be bigger than the bottom number.';
  }
  return null;
}

class BpReading {
  const BpReading({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    this.id,
    this.arm,
    this.note,
  });

  final String? id;
  final DateTime timestamp;
  final int systolic;
  final int diastolic;
  final String? arm;
  final String? note;

  BpCategory get category => BpCategory.classify(systolic, diastolic);
  String get display => '$systolic/$diastolic';
}

/// Rounded average of a group of readings.
class BpAverage {
  const BpAverage({
    required this.systolic,
    required this.diastolic,
    required this.count,
  });

  final int systolic;
  final int diastolic;
  final int count;

  BpCategory get category => BpCategory.classify(systolic, diastolic);
  String get display => '$systolic/$diastolic';

  static BpAverage? of(Iterable<BpReading> readings) {
    var count = 0;
    var systolicSum = 0;
    var diastolicSum = 0;
    for (final reading in readings) {
      count++;
      systolicSum += reading.systolic;
      diastolicSum += reading.diastolic;
    }
    if (count == 0) return null;
    return BpAverage(
      systolic: (systolicSum / count).round(),
      diastolic: (diastolicSum / count).round(),
      count: count,
    );
  }
}

/// Summary numbers for a set of readings (for example, the last 7 days).
class BpStats {
  BpStats._(this.readings);

  factory BpStats.from(Iterable<BpReading> readings) {
    final sorted = readings.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return BpStats._(List.unmodifiable(sorted));
  }

  /// Readings sorted from oldest to newest.
  final List<BpReading> readings;

  int get count => readings.length;
  bool get isEmpty => readings.isEmpty;

  BpReading? get latest => readings.isEmpty ? null : readings.last;

  BpAverage? get average => BpAverage.of(readings);

  /// Reading with the highest top number (ties go to the higher bottom one).
  BpReading? get highest {
    BpReading? best;
    for (final reading in readings) {
      if (best == null ||
          reading.systolic > best.systolic ||
          (reading.systolic == best.systolic &&
              reading.diastolic > best.diastolic)) {
        best = reading;
      }
    }
    return best;
  }

  /// Reading with the lowest top number (ties go to the lower bottom one).
  BpReading? get lowest {
    BpReading? best;
    for (final reading in readings) {
      if (best == null ||
          reading.systolic < best.systolic ||
          (reading.systolic == best.systolic &&
              reading.diastolic < best.diastolic)) {
        best = reading;
      }
    }
    return best;
  }

  /// Number of readings at or above the 140/90 limit.
  int get highCount =>
      readings.where((reading) => reading.category.isHigh).length;
}

/// A run of whole calendar days, from [start] (inclusive) to [end] (exclusive).
class BpPeriod {
  const BpPeriod({required this.start, required this.end});

  /// The [days] calendar days ending on (and including) [lastDay].
  factory BpPeriod.daysEnding(DateTime lastDay, int days) {
    final end = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
    final start = DateTime(lastDay.year, lastDay.month, lastDay.day - days + 1);
    return BpPeriod(start: start, end: end);
  }

  /// The Monday-to-Sunday week that contains [day].
  factory BpPeriod.weekOf(DateTime day) {
    final start = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    final end = DateTime(start.year, start.month, start.day + 7);
    return BpPeriod(start: start, end: end);
  }

  final DateTime start;
  final DateTime end;

  /// The last day inside the period.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  /// The period of the same length directly before this one.
  BpPeriod get previous {
    final days = DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
    return BpPeriod(
      start: DateTime(start.year, start.month, start.day - days),
      end: start,
    );
  }

  bool contains(DateTime time) => !time.isBefore(start) && time.isBefore(end);

  BpStats statsOf(Iterable<BpReading> readings) {
    return BpStats.from(readings.where((reading) => contains(reading.timestamp)));
  }

  @override
  bool operator ==(Object other) =>
      other is BpPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
