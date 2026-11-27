import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../shared/widgets/info_card.dart';

/// Interactive BMI & BMR (Mifflin-St Jeor) calculator card.
class BmiBmrCalculatorCard extends StatefulWidget {
  final double initialHeightCm;
  final double initialWeightKg;
  final int initialAge;

  const BmiBmrCalculatorCard({
    super.key,
    this.initialHeightCm = 175.0,
    this.initialWeightKg = 75.0,
    this.initialAge = 28,
  });

  @override
  State<BmiBmrCalculatorCard> createState() => _BmiBmrCalculatorCardState();
}

class _BmiBmrCalculatorCardState extends State<BmiBmrCalculatorCard> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _ageController;
  String _gender = 'Male';

  double? _bmi;
  double? _bmr;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.initialHeightCm.toStringAsFixed(0),
    );
    _weightController = TextEditingController(
      text: widget.initialWeightKg.toStringAsFixed(1),
    );
    _ageController = TextEditingController(
      text: widget.initialAge.toString(),
    );
    _recalculate();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final h = double.tryParse(_heightController.text.trim());
    final w = double.tryParse(_weightController.text.trim());
    final age = int.tryParse(_ageController.text.trim());

    if (h == null || h <= 0 || w == null || w <= 0 || age == null || age <= 0) {
      setState(() {
        _bmi = null;
        _bmr = null;
      });
      return;
    }

    final heightM = h / 100.0;
    final bmi = w / (heightM * heightM);
    // Mifflin-St Jeor BMR formula
    final baseBmr = (10 * w) + (6.25 * h) - (5 * age);
    final bmr = _gender == 'Male' ? baseBmr + 5 : baseBmr - 161;

    setState(() {
      _bmi = bmi;
      _bmr = bmr > 0 ? bmr : null;
    });
  }

  ({String label, Color color, Color bg}) _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return (label: 'Underweight', color: AppColors.info, bg: AppColors.infoBg);
    }
    if (bmi < 25.0) {
      return (label: 'Normal Range', color: AppColors.success, bg: AppColors.successBg);
    }
    if (bmi < 30.0) {
      return (label: 'Overweight', color: AppColors.warning, bg: AppColors.warningBg);
    }
    return (label: 'Elevated (30+)', color: AppColors.error, bg: AppColors.errorBg);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    return InfoCard(
      title: 'BMI & BMR Calculator',
      subtitle: 'Body Mass Index & Basal Metabolic Rate (Mifflin-St Jeor)',
      icon: Icons.calculate_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final heightField = TextField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  isDense: true,
                ),
                onChanged: (_) => _recalculate(),
              );
              final weightField = TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  isDense: true,
                ),
                onChanged: (_) => _recalculate(),
              );
              final ageField = TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age (yrs)',
                  isDense: true,
                ),
                onChanged: (_) => _recalculate(),
              );
              final genderToggle = Row(
                mainAxisSize: MainAxisSize.min,
                children: ['Male', 'Female'].map((g) {
                  final selected = _gender == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: selected,
                      selectedColor: AppColors.limeAccent.withValues(alpha: 0.35),
                      onSelected: (_) {
                        setState(() => _gender = g);
                        _recalculate();
                      },
                    ),
                  );
                }).toList(),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: heightField),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: weightField),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: ageField),
                        const SizedBox(width: AppSpacing.sm),
                        genderToggle,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: heightField),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: weightField),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: ageField),
                  const SizedBox(width: AppSpacing.md),
                  genderToggle,
                ],
              );
            },
          ),

          SizedBox(height: isMobile ? AppSpacing.sm + 2 : AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              final bmiVal = _bmi;
              final bmrVal = _bmr;
              final cat = bmiVal != null ? _bmiCategory(bmiVal) : null;

              final bmiBox = Container(
                padding: EdgeInsets.all(isMobile ? 10 : AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BMI Result',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (cat != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cat.bg,
                              borderRadius: AppRadius.roundedFull,
                            ),
                            child: Text(
                              cat.label,
                              style: AppTextStyles.caption.copyWith(
                                color: cat.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bmiVal != null ? bmiVal.toStringAsFixed(1) : '--',
                      style: AppTextStyles.h2.copyWith(fontSize: isMobile ? 20 : 24),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'kg/m² • Healthy reference: 18.5 – 24.9',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              );

              final bmrBox = Container(
                padding: EdgeInsets.all(isMobile ? 10 : AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMR Result (Resting Energy)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bmrVal != null ? '${bmrVal.round()} kcal/day' : '--',
                      style: AppTextStyles.h2.copyWith(fontSize: isMobile ? 20 : 24),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bmrVal != null
                          ? 'Active maintenance est: ~${(bmrVal * 1.55).round()} kcal/day'
                          : 'Enter valid height, weight & age',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bmiBox,
                    const SizedBox(height: AppSpacing.sm),
                    bmrBox,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: bmiBox),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: bmrBox),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
