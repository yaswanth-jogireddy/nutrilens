import 'package:flutter/material.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';

/// Green used for readings in range (below 140/90). Dark enough for white
/// text in both light and dark themes.
const bpInRangeColor = Color(0xFF2E7D32);

/// Text color for a reading: green when it is in range, otherwise the normal
/// text color. High readings are deliberately not shown in red so the screen
/// does not alarm.
Color bpCategoryColor(BpCategory category, ColorScheme colorScheme) {
  if (!category.isInRange) return colorScheme.onSurface;
  return colorScheme.brightness == Brightness.dark
      ? const Color(0xFF81C784)
      : bpInRangeColor;
}

class BpCategoryChip extends StatelessWidget {
  const BpCategoryChip({super.key, required this.category, this.large = false});

  final BpCategory category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inRange = category.isInRange;
    final textStyle = large
        ? theme.textTheme.labelLarge
        : theme.textTheme.labelSmall;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: inRange ? bpInRangeColor : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: textStyle?.copyWith(
          color: inRange ? Colors.white : colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
