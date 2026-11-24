import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/fitness_measurement.dart';

enum ChartMetric { weight, bodyFat, waist, muscleMass }

enum DateRangeFilter { allTime, last6Months, last3Months }

/// Interactive Fitness Progress line chart created from actual measurement records.
class FitnessChartCard extends StatefulWidget {
  final List<FitnessMeasurement> measurements;
  final bool isMetric;

  const FitnessChartCard({
    super.key,
    required this.measurements,
    required this.isMetric,
  });

  @override
  State<FitnessChartCard> createState() => _FitnessChartCardState();
}

class _FitnessChartCardState extends State<FitnessChartCard> {
  ChartMetric _selectedMetric = ChartMetric.weight;
  DateRangeFilter _selectedDateRange = DateRangeFilter.allTime;

  List<FitnessMeasurement> _getFilteredMeasurements() {
    final sorted = List<FitnessMeasurement>.from(widget.measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.isEmpty) return [];

    final now = DateTime.now();
    switch (_selectedDateRange) {
      case DateRangeFilter.last3Months:
        final cutoff = DateTime(now.year, now.month - 3, now.day);
        final filtered = sorted.where((m) => m.date.isAfter(cutoff)).toList();
        return filtered.isNotEmpty ? filtered : sorted;
      case DateRangeFilter.last6Months:
        final cutoff = DateTime(now.year, now.month - 6, now.day);
        final filtered = sorted.where((m) => m.date.isAfter(cutoff)).toList();
        return filtered.isNotEmpty ? filtered : sorted;
      case DateRangeFilter.allTime:
        return sorted;
    }
  }

  String _getMetricUnitLabel() {
    switch (_selectedMetric) {
      case ChartMetric.weight:
        return widget.isMetric ? 'kg' : 'lb';
      case ChartMetric.bodyFat:
        return '%';
      case ChartMetric.waist:
        return widget.isMetric ? 'cm' : 'in';
      case ChartMetric.muscleMass:
        return widget.isMetric ? 'kg' : 'lb';
    }
  }

  String _getMetricTitle() {
    switch (_selectedMetric) {
      case ChartMetric.weight:
        return 'Body Weight Progression';
      case ChartMetric.bodyFat:
        return 'Body Fat Percentage Trend';
      case ChartMetric.waist:
        return 'Waist Circumference Trend';
      case ChartMetric.muscleMass:
        return 'Skeletal Muscle Mass';
    }
  }

  double? _extractValue(FitnessMeasurement m) {
    switch (_selectedMetric) {
      case ChartMetric.weight:
        return widget.isMetric ? m.weightKg : m.weightLb;
      case ChartMetric.bodyFat:
        return m.bodyFatPercentage;
      case ChartMetric.waist:
        return widget.isMetric ? m.waistCm : m.waistInches;
      case ChartMetric.muscleMass:
        return widget.isMetric ? m.muscleMassKg : m.muscleMassLb;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredMeasurements();
    final validPoints = <FlSpot>[];
    final validDates = <DateTime>[];

    for (int i = 0; i < filtered.length; i++) {
      final val = _extractValue(filtered[i]);
      if (val != null) {
        validPoints.add(FlSpot(validPoints.length.toDouble(), val));
        validDates.add(filtered[i].date);
      }
    }

    final unitLabel = _getMetricUnitLabel();

    double minY = 0;
    double maxY = 100;
    if (validPoints.isNotEmpty) {
      final values = validPoints.map((s) => s.y).toList();
      minY = values.reduce((a, b) => a < b ? a : b) - 2;
      maxY = values.reduce((a, b) => a > b ? a : b) + 2;
      if (minY < 0) minY = 0;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title and Date Range Filter
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final titleWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        color: AppColors.darkCharcoal,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _getMetricTitle(),
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unit: $unitLabel • Based on actual logged entries',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );

              final rangeFilters = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRangeChip('All Time', DateRangeFilter.allTime),
                  const SizedBox(width: 4),
                  _buildRangeChip('6 Months', DateRangeFilter.last6Months),
                  const SizedBox(width: 4),
                  _buildRangeChip('3 Months', DateRangeFilter.last3Months),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: rangeFilters,
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleWidget),
                    rangeFilters,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Metric Switcher Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetricTab('Weight', ChartMetric.weight),
                const SizedBox(width: AppSpacing.xs),
                _buildMetricTab('Body Fat %', ChartMetric.bodyFat),
                const SizedBox(width: AppSpacing.xs),
                _buildMetricTab('Waist', ChartMetric.waist),
                const SizedBox(width: AppSpacing.xs),
                _buildMetricTab('Muscle Mass', ChartMetric.muscleMass),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Line Chart View
          validPoints.isEmpty
              ? Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: Text(
                    'No measurement data logged for this metric yet.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxY - minY) > 10 ? 5 : 2,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.borderSubtle.withValues(alpha: 0.6),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < validDates.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    AppFormatters.formatShortDate(validDates[index])
                                        .split(',')[0],
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toStringAsFixed(1)} $unitLabel',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBorderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final dateStr = spot.x.toInt() < validDates.length
                                  ? AppFormatters.formatShortDate(
                                      validDates[spot.x.toInt()])
                                  : '';
                              return LineTooltipItem(
                                '$dateStr\n${spot.y.toStringAsFixed(1)} $unitLabel',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: validPoints,
                          isCurved: true,
                          curveSmoothness: 0.25,
                          color: AppColors.limeAccentDark,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.limeAccentDark,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.limeAccent.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMetricTab(String label, ChartMetric metric) {
    final isSelected = _selectedMetric == metric;
    return InkWell(
      onTap: () => setState(() => _selectedMetric = metric),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.darkCharcoal
              : AppColors.cardSubtleBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.darkCharcoal : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.limeAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRangeChip(String label, DateRangeFilter range) {
    final isSelected = _selectedDateRange == range;
    return InkWell(
      onTap: () => setState(() => _selectedDateRange = range),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.limeAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? AppColors.limeAccentDark
                : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.darkCharcoal : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
