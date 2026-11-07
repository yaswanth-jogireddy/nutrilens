import 'package:nutrinutri/core/domain/nutrition_metric.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.name,
    this.type = EntryType.food,
    Map<NutritionMetricType, double>? metrics,
    required this.timestamp,
    String? imagePath,
    List<String>? imagePaths,
    this.icon,
    this.status = FoodEntryStatus.synced,
    this.description,
    this.reasoning,
    this.markedForAiReview = false,
    this.durationMinutes,
    this.temperatureValue,
    this.temperatureUnit,
    this.temperatureSite,
    this.bpSystolic,
    this.bpDiastolic,
    this.bpArm,
  }) : imagePaths = List.unmodifiable(_normalizeImagePaths(
         imagePath,
         imagePaths,
       )),
       imagePath = imagePath ?? _firstImagePath(imagePaths),
       metrics = Map.unmodifiable(metrics ?? const {});

  final String id;
  final String name;
  final EntryType type;
  final Map<NutritionMetricType, double> metrics;
  final DateTime timestamp;
  final String? imagePath;
  final List<String> imagePaths;
  final String? icon;
  final FoodEntryStatus status;
  final String? description;
  final String? reasoning;
  final bool markedForAiReview;
  final int? durationMinutes;
  final double? temperatureValue;
  final String? temperatureUnit;
  final String? temperatureSite;
  final int? bpSystolic;
  final int? bpDiastolic;
  final String? bpArm;

  double metricValue(NutritionMetricType type) {
    return metrics[type] ?? 0;
  }

  double get calories => metricValue(NutritionMetricType.calories);
  double get protein => metricValue(NutritionMetricType.protein);
  double get carbs => metricValue(NutritionMetricType.carbs);
  double get fats => metricValue(NutritionMetricType.fats);

  bool get isTemperature => type == EntryType.temperature;
  bool get isBloodPressure => type == EntryType.bloodPressure;

  /// The blood pressure reading, or null when this is not a complete BP entry.
  BpReading? get bpReading {
    final systolic = bpSystolic;
    final diastolic = bpDiastolic;
    if (type != EntryType.bloodPressure ||
        systolic == null ||
        diastolic == null) {
      return null;
    }
    final note = description?.trim();
    return BpReading(
      id: id,
      timestamp: timestamp,
      systolic: systolic,
      diastolic: diastolic,
      arm: bpArm,
      note: note == null || note.isEmpty ? null : note,
    );
  }

  String get bpDisplay {
    final systolic = bpSystolic;
    final diastolic = bpDiastolic;
    if (systolic == null || diastolic == null) return 'No reading';
    return '$systolic/$diastolic mmHg';
  }

  DiaryEntry copyWithAiReviewMark(bool marked) {
    return DiaryEntry(
      id: id,
      name: name,
      type: type,
      metrics: metrics,
      timestamp: timestamp,
      imagePath: imagePath,
      imagePaths: imagePaths,
      icon: icon,
      status: status,
      description: description,
      reasoning: reasoning,
      markedForAiReview: marked,
      durationMinutes: durationMinutes,
      temperatureValue: temperatureValue,
      temperatureUnit: temperatureUnit,
      temperatureSite: temperatureSite,
      bpSystolic: bpSystolic,
      bpDiastolic: bpDiastolic,
      bpArm: bpArm,
    );
  }

  double? get temperatureCelsius {
    final value = temperatureValue;
    if (value == null) return null;

    final unit = (temperatureUnit ?? 'C').trim().toUpperCase();
    if (unit == 'F') {
      return (value - 32) * 5 / 9;
    }
    return value;
  }

  String get temperatureDisplay {
    final value = temperatureValue;
    if (value == null) return 'No reading';
    final unit = (temperatureUnit ?? 'C').trim().toUpperCase();
    return '${_formatTemperature(value)} $unit';
  }

  String get temperatureSiteLabel {
    final site = (temperatureSite ?? 'under_tongue')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    return switch (site) {
      'left' || 'left_hand' => 'Left hand',
      'right' || 'right_hand' => 'Right hand',
      _ => 'Under tongue',
    };
  }
}

// Stored by index in the database: only ever append new values.
enum EntryType { food, exercise, temperature, bloodPressure }

enum FoodEntryStatus { synced, processing, failed, cancelled }

class DiaryEntryImage {
  const DiaryEntryImage({
    required this.id,
    required this.entryId,
    required this.localPath,
    this.originalName,
    this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String entryId;
  final String localPath;
  final String? originalName;
  final String? mimeType;
  final DateTime createdAt;
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.entryId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadataJson,
  });

  final String id;
  final String entryId;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? metadataJson;
}

List<String> _normalizeImagePaths(String? imagePath, List<String>? imagePaths) {
  final seen = <String>{};
  final normalized = <String>[];

  void add(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty || !seen.add(trimmed)) return;
    normalized.add(trimmed);
  }

  add(imagePath);
  if (imagePaths != null) {
    for (final path in imagePaths) {
      add(path);
    }
  }
  return normalized;
}

String? _firstImagePath(List<String>? imagePaths) {
  if (imagePaths == null || imagePaths.isEmpty) return null;
  final first = imagePaths.first.trim();
  return first.isEmpty ? null : first;
}

String _formatTemperature(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
