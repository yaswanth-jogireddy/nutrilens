import 'package:flutter_test/flutter_test.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure_report.dart';
import 'package:nutrinutri/features/diary/domain/diary_entry.dart';

BpReading reading(
  DateTime time,
  int systolic,
  int diastolic, {
  String? arm,
  String? note,
}) {
  return BpReading(
    timestamp: time,
    systolic: systolic,
    diastolic: diastolic,
    arm: arm,
    note: note,
  );
}

void main() {
  group('BpCategory.classify (140/90 limit)', () {
    test('uses the higher of the two numbers', () {
      expect(BpCategory.classify(120, 80), BpCategory.normal);
      expect(BpCategory.classify(129, 84), BpCategory.normal);
      expect(BpCategory.classify(130, 80), BpCategory.highNormal);
      expect(BpCategory.classify(120, 85), BpCategory.highNormal);
      expect(BpCategory.classify(139, 89), BpCategory.highNormal);
      expect(BpCategory.classify(140, 80), BpCategory.high);
      expect(BpCategory.classify(120, 90), BpCategory.high);
      expect(BpCategory.classify(160, 90), BpCategory.veryHigh);
      expect(BpCategory.classify(150, 100), BpCategory.veryHigh);
      expect(BpCategory.classify(180, 100), BpCategory.dangerous);
      expect(BpCategory.classify(150, 110), BpCategory.dangerous);
    });

    test('flags low pressure, but high takes priority', () {
      expect(BpCategory.classify(89, 70), BpCategory.low);
      expect(BpCategory.classify(110, 59), BpCategory.low);
      expect(BpCategory.classify(150, 58), BpCategory.high);
    });

    test('isHigh starts at 140/90', () {
      expect(BpCategory.highNormal.isHigh, isFalse);
      expect(BpCategory.high.isHigh, isTrue);
      expect(BpCategory.dangerous.isHigh, isTrue);
      expect(BpCategory.low.isHigh, isFalse);
    });

    test('isInRange covers 90/60 up to 140/90', () {
      expect(BpCategory.normal.isInRange, isTrue);
      expect(BpCategory.highNormal.isInRange, isTrue);
      expect(BpCategory.low.isInRange, isFalse);
      expect(BpCategory.high.isInRange, isFalse);
      expect(BpCategory.veryHigh.isInRange, isFalse);
    });
  });

  test('validateBpReading rejects impossible readings', () {
    expect(validateBpReading(null, 80), isNotNull);
    expect(validateBpReading(120, null), isNotNull);
    expect(validateBpReading(40, 30), isNotNull);
    expect(validateBpReading(120, 20), isNotNull);
    expect(validateBpReading(80, 90), isNotNull);
    expect(validateBpReading(120, 120), isNotNull);
    expect(validateBpReading(120, 80), isNull);
  });

  test('normalizeBpArm accepts common spellings', () {
    expect(normalizeBpArm('Left'), 'left');
    expect(normalizeBpArm(' R '), 'right');
    expect(normalizeBpArm('right_arm'), 'right');
    expect(normalizeBpArm(''), isNull);
    expect(normalizeBpArm(null), isNull);
    expect(bpArmLabel('left'), 'Left arm');
    expect(bpArmLabel(null), '');
  });

  group('BpStats', () {
    final readings = [
      reading(DateTime(2026, 11, 5, 20, 0), 130, 84),
      reading(DateTime(2026, 11, 3, 7, 45), 124, 78),
      reading(DateTime(2026, 11, 7, 8, 10), 150, 95),
      reading(DateTime(2026, 11, 6, 8, 0), 150, 92),
      reading(DateTime(2026, 11, 4, 18, 0), 124, 76),
    ];
    final stats = BpStats.from(readings);

    test('sorts readings and finds the latest', () {
      expect(stats.count, 5);
      expect(stats.readings.first.timestamp, DateTime(2026, 11, 3, 7, 45));
      expect(stats.latest!.display, '150/95');
    });

    test('average is rounded per number', () {
      // (130+124+150+150+124)/5 = 135.6, (84+78+95+92+76)/5 = 85
      final average = stats.average!;
      expect(average.display, '136/85');
      expect(average.count, 5);
      expect(average.category, BpCategory.highNormal);
    });

    test('highest and lowest break ties on the bottom number', () {
      expect(stats.highest!.display, '150/95');
      expect(stats.lowest!.display, '124/76');
    });

    test('counts readings at or above 140/90', () {
      expect(stats.highCount, 2);
    });

    test('empty stats have no numbers', () {
      final empty = BpStats.from(const []);
      expect(empty.isEmpty, isTrue);
      expect(empty.average, isNull);
      expect(empty.highest, isNull);
      expect(empty.lowest, isNull);
      expect(empty.latest, isNull);
      expect(empty.highCount, 0);
    });
  });

  group('BpPeriod', () {
    test('daysEnding covers whole days and crosses month ends', () {
      final period = BpPeriod.daysEnding(DateTime(2026, 11, 3, 15, 30), 7);
      expect(period.start, DateTime(2026, 10, 28));
      expect(period.end, DateTime(2026, 11, 4));
      expect(period.lastDay, DateTime(2026, 11, 3));
      expect(period.contains(DateTime(2026, 10, 28)), isTrue);
      expect(period.contains(DateTime(2026, 11, 3, 23, 59)), isTrue);
      expect(period.contains(DateTime(2026, 11, 4)), isFalse);
      expect(period.contains(DateTime(2026, 10, 27, 23, 59)), isFalse);
    });

    test('previous is the same length just before', () {
      final previous = BpPeriod.daysEnding(DateTime(2026, 11, 7), 7).previous;
      expect(previous.start, DateTime(2026, 10, 25));
      expect(previous.end, DateTime(2026, 11, 1));
    });

    test('weekOf starts on Monday', () {
      // 7 Nov 2026 is a Saturday.
      final week = BpPeriod.weekOf(DateTime(2026, 11, 7, 20));
      expect(week.start, DateTime(2026, 11, 2));
      expect(week.end, DateTime(2026, 11, 9));
      expect(BpPeriod.weekOf(DateTime(2026, 11, 2)), week);
      expect(BpPeriod.weekOf(DateTime(2026, 11, 8, 23, 59)), week);
    });
  });

  test('DiaryEntry exposes a BP reading only for complete BP entries', () {
    final entry = DiaryEntry(
      id: 'bp-1',
      name: 'BP 132/84',
      type: EntryType.bloodPressure,
      timestamp: DateTime(2026, 11, 7, 8, 10),
      description: '  after walk ',
      bpSystolic: 132,
      bpDiastolic: 84,
      bpArm: 'right',
    );
    final bp = entry.bpReading!;
    expect(bp.display, '132/84');
    expect(bp.note, 'after walk');
    expect(bp.arm, 'right');
    expect(entry.bpDisplay, '132/84 mmHg');
    expect(entry.copyWithAiReviewMark(true).bpReading!.display, '132/84');

    final food = DiaryEntry(
      id: 'food-1',
      name: 'Idli',
      timestamp: DateTime(2026, 11, 7),
      bpSystolic: 132,
      bpDiastolic: 84,
    );
    expect(food.bpReading, isNull);
  });

  group('buildBloodPressureReportCsv', () {
    final now = DateTime(2026, 11, 7, 20, 0);
    final readings = [
      reading(DateTime(2026, 10, 1, 9, 0), 118, 76, arm: 'left'),
      reading(
        DateTime(2026, 11, 7, 8, 10),
        150,
        95,
        arm: 'left',
        note: 'before tablet, felt "dizzy"',
      ),
      reading(DateTime(2026, 11, 6, 19, 30), 130, 84, arm: 'right'),
      reading(DateTime(2026, 11, 3, 7, 45), 124, 78, arm: 'left'),
      reading(DateTime(2026, 10, 30, 8, 0), 160, 100),
    ];
    final lines = buildBloodPressureReportCsv(readings, now: now).split('\n');

    test('starts with the summary block', () {
      expect(lines.first, 'Blood Pressure Report');
      expect(lines, contains('Exported on,2026-11-07 8:00 PM'));
      expect(lines, contains('Total readings,5'));
      expect(lines, contains('First reading,2026-10-01 9:00 AM'));
      expect(lines, contains('Latest reading,2026-11-07 8:10 AM'));
      expect(lines, contains('High means,140/90 or above'));
      expect(
        lines.indexOf('SUMMARY'),
        lessThan(lines.indexOf('WEEKLY SUMMARY (Monday to Sunday)')),
      );
      expect(
        lines.indexOf('WEEKLY SUMMARY (Monday to Sunday)'),
        lessThan(lines.indexOf('ALL READINGS (newest first)')),
      );
    });

    test('summarizes the last 7 and previous 7 days', () {
      expect(
        lines,
        contains(
          'Last 7 days,2026-11-01,2026-11-07,3,135/86,High-normal,'
          '150/95,2026-11-07 8:10 AM,124/78,2026-11-03 7:45 AM,1 of 3',
        ),
      );
      expect(
        lines,
        contains(
          'Previous 7 days,2026-10-25,2026-10-31,1,160/100,Very high,'
          '160/100,2026-10-30 8:00 AM,160/100,2026-10-30 8:00 AM,1 of 1',
        ),
      );
      expect(
        lines.firstWhere((line) => line.startsWith('Last 30 days,')),
        startsWith('Last 30 days,2026-10-09,2026-11-07,4,'),
      );
      expect(
        lines.firstWhere((line) => line.startsWith('All readings,')),
        startsWith('All readings,2026-10-01,2026-11-07,5,'),
      );
    });

    test('lists weeks newest first', () {
      final weekLines = lines
          .where((line) => line.startsWith('Week of '))
          .toList();
      expect(weekLines, hasLength(3));
      expect(weekLines[0], startsWith('Week of 2026-11-02,2026-11-02,2026-11-08,3,'));
      expect(weekLines[1], startsWith('Week of 2026-10-26,2026-10-26,2026-11-01,1,'));
      expect(weekLines[2], startsWith('Week of 2026-09-28,2026-09-28,2026-10-04,1,'));
    });

    test('lists every reading with date, time, and escaped notes', () {
      final header = lines.indexOf('Date,Time,Reading,Arm,Note');
      expect(header, greaterThan(0));
      expect(
        lines[header + 1],
        '2026-11-07,8:10 AM,150/95,Left arm,"before tablet, felt ""dizzy"""',
      );
      expect(lines[header + 2], '2026-11-06,7:30 PM,130/84,Right arm,');
      expect(lines[header + 4], '2026-10-30,8:00 AM,160/100,,');
      expect(lines[header + 5], '2026-10-01,9:00 AM,118/76,Left arm,');
    });

    test('works with no readings', () {
      final empty = buildBloodPressureReportCsv(const [], now: now);
      expect(empty, contains('Total readings,0'));
      expect(empty, contains('Last 7 days,2026-11-01,2026-11-07,0,'));
      expect(empty, contains('No readings yet'));
    });
  });
}
