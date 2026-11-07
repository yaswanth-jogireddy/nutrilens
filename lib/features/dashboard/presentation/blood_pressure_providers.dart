import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrinutri/core/providers.dart';
import 'package:nutrinutri/features/dashboard/presentation/dashboard_providers.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';

/// Blood pressure readings for the 14 days ending on (and including) the
/// given day: the last 7 days plus the 7 days before them, so the dashboard
/// can compare this week with the previous one.
///
/// Invalidate the whole family (`ref.invalidate(bloodPressureWindowProvider)`)
/// after adding, editing, deleting, or importing entries.
final bloodPressureWindowProvider = FutureProvider.autoDispose
    .family<List<BpReading>, DateTime>((ref, lastDay) async {
      ref.watch(syncUpdateProvider);
      final period = BpPeriod.daysEnding(lastDay, 14);
      final entries = await ref
          .watch(diaryServiceProvider)
          .getBloodPressureEntries(from: period.start, toExclusive: period.end);
      return entries
          .map((entry) => entry.bpReading)
          .whereType<BpReading>()
          .toList(growable: false);
    });
