import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/fitness_goal.dart';

/// Modal dialog for creating a personal fitness goal.
class CreateFitnessGoalModal extends StatefulWidget {
  final bool initialIsMetric;
  final ValueChanged<FitnessGoal> onSave;

  const CreateFitnessGoalModal({
    super.key,
    this.initialIsMetric = true,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    bool isMetric = true,
    required ValueChanged<FitnessGoal> onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateFitnessGoalModal(
        initialIsMetric: isMetric,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CreateFitnessGoalModal> createState() => _CreateFitnessGoalModalState();
}

class _CreateFitnessGoalModalState extends State<CreateFitnessGoalModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _startValueController;
  late final TextEditingController _targetValueController;

  String _metricType = 'Weight';
  String _unit = 'kg';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 60));

  @override
  void initState() {
    super.initState();
    _unit = widget.initialIsMetric ? 'kg' : 'lb';
    _titleController = TextEditingController(text: 'Target Body Weight');
    _startValueController = TextEditingController(
      text: widget.initialIsMetric ? '78.4' : '172.8',
    );
    _targetValueController = TextEditingController(
      text: widget.initialIsMetric ? '75.0' : '165.3',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startValueController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  void _onMetricTypeChanged(String val) {
    setState(() {
      _metricType = val;
      _titleController.text = 'Target $val';
      if (val == 'Weight' || val == 'Muscle Mass') {
        _unit = widget.initialIsMetric ? 'kg' : 'lb';
      } else if (val == 'Body Fat') {
        _unit = '%';
      } else {
        _unit = widget.initialIsMetric ? 'cm' : 'in';
      }
    });
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final start = double.parse(_startValueController.text.trim());
    final target = double.parse(_targetValueController.text.trim());

    final goal = FitnessGoal(
      id: 'GOAL-${DateTime.now().millisecondsSinceEpoch}',
      memberId: 'GM-1024',
      title: _titleController.text.trim(),
      metricType: _metricType,
      startValue: start,
      currentValue: start,
      targetValue: target,
      unit: _unit,
      startDate: DateTime.now(),
      targetDate: _targetDate,
    );

    widget.onSave(goal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Fitness Goal',
                      style: AppTextStyles.h3,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Set target metrics and a deadline to stay consistent and accountable.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: AppSpacing.md),

                // Goal Title
                Text(
                  'Goal Title',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Target Body Weight',
                    filled: true,
                    fillColor: AppColors.cardSubtleBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Enter a goal title' : null,
                ),

                const SizedBox(height: AppSpacing.md),

                // Metric Type & Unit
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Metric',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardSubtleBg,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _metricType,
                                isExpanded: true,
                                dropdownColor: AppColors.cardBackground,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Weight',
                                    child: Text('Weight'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Body Fat',
                                    child: Text('Body Fat %'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Waist',
                                    child: Text('Waist'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Muscle Mass',
                                    child: Text('Muscle Mass'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) _onMetricTypeChanged(val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardSubtleBg,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _unit,
                                isExpanded: true,
                                dropdownColor: AppColors.cardBackground,
                                items: (_metricType == 'Body Fat'
                                        ? ['%']
                                        : _metricType == 'Waist'
                                            ? ['cm', 'in']
                                            : ['kg', 'lb'])
                                    .map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _unit = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Start Value & Target Value
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Value',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _startValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              suffixText: _unit,
                              filled: true,
                              fillColor: AppColors.cardSubtleBg,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSubtle),
                              ),
                            ),
                            validator: (val) =>
                                val == null || double.tryParse(val.trim()) == null
                                    ? 'Valid number'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Value',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _targetValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              suffixText: _unit,
                              filled: true,
                              fillColor: AppColors.cardSubtleBg,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(
                                    color: AppColors.borderSubtle),
                              ),
                            ),
                            validator: (val) =>
                                val == null || double.tryParse(val.trim()) == null
                                    ? 'Valid number'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Target Date
                Text(
                  'Target Deadline Date',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: _pickTargetDate,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardSubtleBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          AppFormatters.formatDate(_targetDate),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: AppSpacing.md),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: _submit,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.darkCharcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm + 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text('Set Goal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
