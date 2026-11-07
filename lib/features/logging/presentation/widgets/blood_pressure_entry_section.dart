import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:nutrinutri/features/diary/domain/blood_pressure.dart';
import 'package:nutrinutri/features/logging/presentation/widgets/entry_action_buttons.dart';

class BloodPressureEntrySection extends StatefulWidget {
  const BloodPressureEntrySection({
    super.key,
    required this.isEditing,
    required this.systolicController,
    required this.diastolicController,
    required this.noteController,
    required this.selectedArm,
    required this.selectedDate,
    required this.selectedTime,
    required this.onArmChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSave,
    required this.onDeleteConfirmed,
  });

  final bool isEditing;
  final TextEditingController systolicController;
  final TextEditingController diastolicController;
  final TextEditingController noteController;
  final String selectedArm;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<String> onArmChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final Future<void> Function() onSave;
  final Future<void> Function() onDeleteConfirmed;

  @override
  State<BloodPressureEntrySection> createState() =>
      _BloodPressureEntrySectionState();
}

class _BloodPressureEntrySectionState extends State<BloodPressureEntrySection> {
  final _diastolicFocus = FocusNode();

  @override
  void dispose() {
    _diastolicFocus.dispose();
    super.dispose();
  }

  void _onSystolicChanged(String value) {
    // Most top numbers have three digits; jump to the bottom number then.
    if (value.length == 3) {
      _diastolicFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
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
                    child: Text(
                      'Blood Pressure',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: widget.systolicController,
                      label: 'Top',
                      helper: 'Systolic (mmHg)',
                      autofocus: !widget.isEditing,
                      textInputAction: TextInputAction.next,
                      onChanged: _onSystolicChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      '/',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _NumberField(
                      controller: widget.diastolicController,
                      focusNode: _diastolicFocus,
                      label: 'Bottom',
                      helper: 'Diastolic (mmHg)',
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              ListenableBuilder(
                listenable: Listenable.merge([
                  widget.systolicController,
                  widget.diastolicController,
                ]),
                builder: (context, _) => _ReadingHint(
                  systolic: int.tryParse(widget.systolicController.text),
                  diastolic: int.tryParse(widget.diastolicController.text),
                ),
              ),
              const Gap(20),
              Text(
                'Arm',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'left', label: Text('Left arm')),
                  ButtonSegment(value: 'right', label: Text('Right arm')),
                ],
                selected: {normalizeBpArm(widget.selectedArm) ?? 'left'},
                onSelectionChanged: (selection) {
                  widget.onArmChanged(selection.first);
                },
              ),
              const Gap(16),
              TextField(
                controller: widget.noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Optional, e.g. before tablet, after walk',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onPickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('d MMM yyyy').format(widget.selectedDate),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onPickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(widget.selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const Gap(12),
              Text(
                'Tip: sit and rest for 5 minutes before measuring.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Gap(24),
        EntryActionButtons(
          isEditing: widget.isEditing,
          onSave: widget.onSave,
          onDeleteConfirmed: widget.onDeleteConfirmed,
        ),
        const Gap(32),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.helper,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String helper;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      onChanged: onChanged,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// A plain hint under the numbers. It only changes to point out a typo
/// (for example, top smaller than bottom); it never rates the reading.
class _ReadingHint extends StatelessWidget {
  const _ReadingHint({required this.systolic, required this.diastolic});

  final int? systolic;
  final int? diastolic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final top = systolic;
    final bottom = diastolic;
    final error = top == null || bottom == null
        ? null
        : validateBpReading(top, bottom);

    return Text(
      error ?? 'Enter the top and bottom numbers from the BP machine.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: error == null ? colorScheme.onSurfaceVariant : colorScheme.error,
      ),
    );
  }
}
