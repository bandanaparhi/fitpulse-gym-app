import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/fitness_measurement.dart';

/// Modal dialog for adding or editing a body measurement record.
class AddEditMeasurementModal extends StatefulWidget {
  final FitnessMeasurement? measurement; // null if adding new
  final bool initialIsMetric;
  final ValueChanged<FitnessMeasurement> onSave;

  const AddEditMeasurementModal({
    super.key,
    this.measurement,
    this.initialIsMetric = true,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    FitnessMeasurement? measurement,
    bool isMetric = true,
    required ValueChanged<FitnessMeasurement> onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddEditMeasurementModal(
        measurement: measurement,
        initialIsMetric: isMetric,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditMeasurementModal> createState() =>
      _AddEditMeasurementModalState();
}

class _AddEditMeasurementModalState extends State<AddEditMeasurementModal> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late String _selectedType;
  late String _selectedUnit;

  late final TextEditingController _valueController;
  late final TextEditingController _bodyFatController;
  late final TextEditingController _muscleMassController;
  late final TextEditingController _chestController;
  late final TextEditingController _waistController;
  late final TextEditingController _hipsController;

  bool _isComprehensive = false;

  static const List<String> _measurementTypes = [
    'Body Weight',
    'Body Fat %',
    'Waist Circumference',
    'Chest Circumference',
    'Hips Circumference',
    'Skeletal Muscle Mass',
    'Comprehensive Body Scan',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.measurement;
    _selectedDate = m?.date ?? DateTime.now();

    if (m != null) {
      _selectedType = 'Body Weight';
      _selectedUnit = widget.initialIsMetric ? 'kg' : 'lb';
      final weightVal = widget.initialIsMetric ? m.weightKg : m.weightLb;
      _valueController =
          TextEditingController(text: weightVal.toStringAsFixed(1));
      _bodyFatController = TextEditingController(
          text: m.bodyFatPercentage?.toStringAsFixed(1) ?? '');
      _muscleMassController = TextEditingController(
          text: m.muscleMassKg != null
              ? (widget.initialIsMetric
                      ? m.muscleMassKg!
                      : m.muscleMassLb!)
                  .toStringAsFixed(1)
              : '');
      _chestController = TextEditingController(
          text: m.chestCm != null
              ? (widget.initialIsMetric ? m.chestCm! : m.chestInches!)
                  .toStringAsFixed(1)
              : '');
      _waistController = TextEditingController(
          text: m.waistCm != null
              ? (widget.initialIsMetric ? m.waistCm! : m.waistInches!)
                  .toStringAsFixed(1)
              : '');
      _hipsController = TextEditingController(
          text: m.hipsCm != null
              ? (widget.initialIsMetric ? m.hipsCm! : m.hipsInches!)
                  .toStringAsFixed(1)
              : '');
    } else {
      _selectedType = 'Body Weight';
      _selectedUnit = widget.initialIsMetric ? 'kg' : 'lb';
      _valueController = TextEditingController();
      _bodyFatController = TextEditingController();
      _muscleMassController = TextEditingController();
      _chestController = TextEditingController();
      _waistController = TextEditingController();
      _hipsController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    super.dispose();
  }

  void _updateUnitForType(String type) {
    setState(() {
      _selectedType = type;
      _isComprehensive = type == 'Comprehensive Body Scan';
      if (type == 'Body Weight' || type == 'Skeletal Muscle Mass') {
        _selectedUnit = widget.initialIsMetric ? 'kg' : 'lb';
      } else if (type == 'Body Fat %') {
        _selectedUnit = '%';
      } else if (type.contains('Circumference')) {
        _selectedUnit = widget.initialIsMetric ? 'cm' : 'inches';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.measurement;
    double weightKg = existing?.weightKg ?? 78.4;
    double? bodyFat = existing?.bodyFatPercentage;
    double? muscleMass = existing?.muscleMassKg;
    double? chest = existing?.chestCm;
    double? waist = existing?.waistCm;
    double? hips = existing?.hipsCm;

    if (_isComprehensive) {
      final w = double.tryParse(_valueController.text.trim());
      if (w != null) {
        weightKg = _selectedUnit == 'lb' ? w / 2.20462 : w;
      }
      bodyFat = double.tryParse(_bodyFatController.text.trim());
      final mm = double.tryParse(_muscleMassController.text.trim());
      if (mm != null) {
        muscleMass = _selectedUnit == 'lb' ? mm / 2.20462 : mm;
      }
      final c = double.tryParse(_chestController.text.trim());
      if (c != null) {
        chest = _selectedUnit == 'inches' ? c / 0.393701 : c;
      }
      final ws = double.tryParse(_waistController.text.trim());
      if (ws != null) {
        waist = _selectedUnit == 'inches' ? ws / 0.393701 : ws;
      }
      final h = double.tryParse(_hipsController.text.trim());
      if (h != null) {
        hips = _selectedUnit == 'inches' ? h / 0.393701 : h;
      }
    } else {
      final val = double.parse(_valueController.text.trim());
      switch (_selectedType) {
        case 'Body Weight':
          weightKg = _selectedUnit == 'lb' ? val / 2.20462 : val;
          break;
        case 'Body Fat %':
          bodyFat = val;
          break;
        case 'Skeletal Muscle Mass':
          muscleMass = _selectedUnit == 'lb' ? val / 2.20462 : val;
          break;
        case 'Chest Circumference':
          chest = _selectedUnit == 'inches' ? val / 0.393701 : val;
          break;
        case 'Waist Circumference':
          waist = _selectedUnit == 'inches' ? val / 0.393701 : val;
          break;
        case 'Hips Circumference':
          hips = _selectedUnit == 'inches' ? val / 0.393701 : val;
          break;
      }
    }

    // Calculated BMI: weight (kg) / (height (m))^2. Assuming height ~1.83m (6'0")
    final calculatedBmi =
        double.parse((weightKg / (1.83 * 1.83)).toStringAsFixed(1));

    final record = FitnessMeasurement(
      id: existing?.id ?? 'FM-${DateTime.now().millisecondsSinceEpoch}',
      memberId: 'GM-1024',
      date: _selectedDate,
      weightKg: double.parse(weightKg.toStringAsFixed(1)),
      bodyFatPercentage: bodyFat != null
          ? double.parse(bodyFat.toStringAsFixed(1))
          : null,
      muscleMassKg: muscleMass != null
          ? double.parse(muscleMass.toStringAsFixed(1))
          : null,
      chestCm: chest != null ? double.parse(chest.toStringAsFixed(1)) : null,
      waistCm: waist != null ? double.parse(waist.toStringAsFixed(1)) : null,
      hipsCm: hips != null ? double.parse(hips.toStringAsFixed(1)) : null,
      bmi: calculatedBmi,
    );

    widget.onSave(record);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.measurement != null;

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
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Measurement' : 'Add Measurement',
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
                  'Record body weight, circumferences, and body composition.',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: AppSpacing.md),

                // Form Scrollable Area
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Measurement Type Dropdown
                        Text(
                          'Measurement Type',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardSubtleBg,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedType,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              dropdownColor: AppColors.cardBackground,
                              items: _measurementTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _updateUnitForType(val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Date & Unit Picker Row
                        Row(
                          children: [
                            // Date Picker
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: AppTextStyles.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm + 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardSubtleBg,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.md),
                                        border: Border.all(
                                          color: AppColors.borderSubtle,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            AppFormatters.formatShortDate(
                                                _selectedDate),
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: AppSpacing.md),

                            // Unit Dropdown
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
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedUnit,
                                        isExpanded: true,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.md),
                                        dropdownColor: AppColors.cardBackground,
                                        items: _getUnitsForType(_selectedType)
                                            .map((u) {
                                          return DropdownMenuItem<String>(
                                            value: u,
                                            child: Text(u),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedUnit = val);
                                          }
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

                        // Value Input Field
                        Text(
                          _isComprehensive
                              ? 'Weight Value ($_selectedUnit)'
                              : '$_selectedType Value',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _valueController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 78.5',
                            suffixText: _selectedUnit,
                            filled: true,
                            fillColor: AppColors.cardSubtleBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide:
                                  const BorderSide(color: AppColors.borderSubtle),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide:
                                  const BorderSide(color: AppColors.borderSubtle),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a measurement value';
                            }
                            if (double.tryParse(val.trim()) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),

                        if (_isComprehensive) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildExtraField(
                            label: 'Body Fat (%)',
                            controller: _bodyFatController,
                            suffix: '%',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildExtraField(
                            label: 'Muscle Mass ($_selectedUnit)',
                            controller: _muscleMassController,
                            suffix: _selectedUnit,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildExtraField(
                            label: 'Waist Circumference',
                            controller: _waistController,
                            suffix: widget.initialIsMetric ? 'cm' : 'in',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildExtraField(
                            label: 'Chest Circumference',
                            controller: _chestController,
                            suffix: widget.initialIsMetric ? 'cm' : 'in',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: AppSpacing.md),

                // Submit Button
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
                      child: Text(isEditing ? 'Update Entry' : 'Save Measurement'),
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

  Widget _buildExtraField({
    required String label,
    required TextEditingController controller,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Optional',
            suffixText: suffix,
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
        ),
      ],
    );
  }

  List<String> _getUnitsForType(String type) {
    if (type == 'Body Weight' ||
        type == 'Skeletal Muscle Mass' ||
        type == 'Comprehensive Body Scan') {
      return ['kg', 'lb'];
    } else if (type == 'Body Fat %') {
      return ['%'];
    } else {
      return ['cm', 'inches'];
    }
  }
}
