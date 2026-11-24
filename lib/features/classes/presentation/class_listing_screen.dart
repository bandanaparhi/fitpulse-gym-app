import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/gym_class.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/class_card.dart';
import 'widgets/class_filter_bar.dart';

/// Class listing screen at `/classes`.
///
/// Features:
/// - Class listing with title, category, instructor, timing, room, and available spots
/// - Filters for date, category, and available spots only
/// - Duplicate booking prevention with instant state sync
/// - Direct navigation to class details and My Bookings pass view
class ClassListingScreen extends ConsumerStatefulWidget {
  const ClassListingScreen({super.key});

  @override
  ConsumerState<ClassListingScreen> createState() =>
      _ClassListingScreenState();
}

class _ClassListingScreenState extends ConsumerState<ClassListingScreen> {
  String _selectedDateFilter = 'All Dates';
  String _selectedCategory = 'All Categories';
  bool _availableOnly = false;

  List<GymClass> _applyFilters(List<GymClass> classes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(const Duration(days: 7));

    return classes.where((c) {
      // 1. Date filter
      if (_selectedDateFilter == 'Today') {
        final classDay =
            DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
        if (classDay != today) return false;
      } else if (_selectedDateFilter == 'Tomorrow') {
        final classDay =
            DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
        if (classDay != tomorrow) return false;
      } else if (_selectedDateFilter == 'This Week') {
        if (c.startTime.isAfter(endOfWeek)) return false;
      }

      // 2. Category filter
      if (_selectedCategory != 'All Categories') {
        if (c.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // 3. Availability filter
      if (_availableOnly) {
        if (c.isFull) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesListProvider);
    final bookingsAsync = ref.watch(classBookingsProvider);

    return classesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading studio classes...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Classes',
          message: err.toString(),
          onRetry: () => ref.read(classesListProvider.notifier).refresh(),
        ),
      ),
      data: (classes) {
        final bookings = bookingsAsync.value ?? [];
        final bookedClassIds = bookings
            .where((b) => b.status == 'Confirmed')
            .map((b) => b.classId)
            .toSet();

        final upcomingBookingsCount =
            bookings.where((b) => b.isUpcoming).length;

        final filteredClasses = _applyFilters(classes);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with "My Bookings" Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Classes & Studio Schedules',
                      subtitle:
                          'Browse group fitness classes, reserve your spot, and view studio timetables.',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCharcoal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 18,
                    ),
                    label: Text(
                      'My Bookings ($upcomingBookingsCount)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => context.go('/classes/bookings'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Filter Controls Bar
              ClassFilterBar(
                selectedDateFilter: _selectedDateFilter,
                selectedCategory: _selectedCategory,
                availableOnly: _availableOnly,
                onDateFilterChanged: (val) {
                  setState(() => _selectedDateFilter = val);
                },
                onCategoryChanged: (val) {
                  setState(() => _selectedCategory = val);
                },
                onAvailableOnlyChanged: (val) {
                  setState(() => _availableOnly = val);
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // Filter count info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Available Classes (${filteredClasses.length})',
                      style: AppTextStyles.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedCategory != 'All Categories' ||
                      _selectedDateFilter != 'All Dates' ||
                      _availableOnly)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDateFilter = 'All Dates';
                          _selectedCategory = 'All Categories';
                          _availableOnly = false;
                        });
                      },
                      child: const Text('Reset Filters'),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Classes List / Empty State
              if (filteredClasses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'No Classes Match Your Filter',
                    message:
                        'Try expanding your date, category, or availability filters to view other scheduled studio sessions.',
                    actionLabel: 'Show All Classes',
                    onAction: () {
                      setState(() {
                        _selectedDateFilter = 'All Dates';
                        _selectedCategory = 'All Categories';
                        _availableOnly = false;
                      });
                    },
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;
                    if (isDesktop) {
                      return Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: filteredClasses.map((gymClass) {
                          final isBooked =
                              bookedClassIds.contains(gymClass.id);
                          return SizedBox(
                            width: (constraints.maxWidth - AppSpacing.md) / 2,
                            child: ClassCard(
                              gymClass: gymClass,
                              isBookedByMember: isBooked,
                              onBook: () => _handleBookClass(gymClass),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return Column(
                        children: filteredClasses.map((gymClass) {
                          final isBooked =
                              bookedClassIds.contains(gymClass.id);
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ClassCard(
                              gymClass: gymClass,
                              isBookedByMember: isBooked,
                              onBook: () => _handleBookClass(gymClass),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleBookClass(GymClass gymClass) async {
    final success = await ref
        .read(classBookingsProvider.notifier)
        .bookClass(gymClass.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.darkCharcoal,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.limeAccent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Your spot in "${gymClass.title}" is confirmed!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'View Pass',
              textColor: AppColors.limeAccent,
              onPressed: () => context.go('/classes/bookings'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            content: Text(
              gymClass.isFull
                  ? 'Unable to book: This class is at full capacity.'
                  : 'You already have an active reservation for this class.',
            ),
          ),
        );
      }
    }
  }
}
