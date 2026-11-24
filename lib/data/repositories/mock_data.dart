import '../models/member.dart';
import '../models/membership.dart';
import '../models/attendance_record.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/fitness_measurement.dart';
import '../models/diet_plan.dart';
import '../models/gym_class.dart';
import '../models/class_booking.dart';
import '../models/trainer.dart';
import '../models/payment.dart';
import '../models/notification_item.dart';
import '../models/announcement.dart';
import '../models/completed_workout.dart';
import '../models/fitness_goal.dart';
import '../models/training_session.dart';

/// Centralized repository of demonstration mock data.
///
/// Designed to be replaced seamlessly by Firestore / Firebase repositories.
class MockData {
  MockData._();

  /// Primary demonstration member conforming to strict specification:
  /// - Member name: Alex Morgan
  /// - Member ID: GM-1024
  /// - Membership: Premium
  /// - Membership status: Active
  /// - Membership expiry: December 30, 2026
  /// - Attendance this month: 18 visits
  /// - Pending payment: ₹0
  /// - Assigned trainer: Jordan Lee
  static final Member demoMember = Member(
    id: 'GM-1024',
    name: 'Alex Morgan',
    email: 'alex.morgan@fitpulse.com',
    phone: '+91 98765 43210',
    photoUrl: null,
    membershipId: 'MEM-PREM-2026',
    membershipPlan: 'Premium',
    membershipStatus: 'Active',
    membershipExpiry: DateTime(2026, 12, 30),
    attendanceCountThisMonth: 18,
    pendingPaymentAmount: 0.0,
    assignedTrainer: 'Jordan Lee',
    joinedDate: DateTime(2025, 1, 15),
    dateOfBirth: DateTime(1994, 6, 15),
    emergencyContact: 'Sarah Morgan (+91 98765 99887) - Spouse',
  );

  /// Demo membership plan details
  static final Membership demoMembership = Membership(
    id: 'MEM-PREM-2026',
    planName: 'Premium All-Access',
    status: 'Active',
    startDate: DateTime(2026, 1, 1),
    expiryDate: DateTime(2026, 12, 30),
    price: 24999.0,
    durationMonths: '12 Months',
    benefits: const [
      'Unlimited access to all gym locations',
      'Dedicated personal trainer consultation',
      'Free access to Steam & Sauna',
      'Unlimited group fitness & Yoga classes',
      'Customized monthly diet & nutrition plan',
      'Free guest passes (2 per month)',
    ],
  );

  /// Previous membership history for Alex Morgan
  static final List<Membership> demoMembershipHistory = [
    Membership(
      id: 'MEM-STD-2025',
      planName: 'Standard Fitness Tier',
      status: 'Expired',
      startDate: DateTime(2025, 1, 1),
      expiryDate: DateTime(2025, 12, 31),
      price: 14999.0,
      durationMonths: '12 Months',
      benefits: const [
        'Full cardio & strength floor access',
        'Locker & shower facilities',
        'Initial fitness assessment & goal setting',
      ],
    ),
  ];

  /// Available membership plans for renewal
  static final List<Membership> availablePlans = [
    demoMembership,
    Membership(
      id: 'MEM-ELITE-6M',
      planName: 'Semi-Annual Elite',
      status: 'Active',
      startDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      price: 14499.0,
      durationMonths: '6 Months',
      benefits: const [
        'Full access to all club zones',
        'Bi-weekly trainer check-in',
        'Group classes & Spin studio access',
        'Steam & Sauna recovery suite',
      ],
    ),
    Membership(
      id: 'MEM-FLEX-1M',
      planName: 'Monthly Flex Pass',
      status: 'Active',
      startDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      price: 2999.0,
      durationMonths: '1 Month',
      benefits: const [
        'Gym floor & cardio deck access',
        'Standard locker room amenities',
        'No long-term commitment',
      ],
    ),
  ];

  /// Assigned trainer details
  static const Trainer demoTrainer = Trainer(
    id: 'TR-301',
    name: 'Jordan Lee',
    specialty: 'Hypertrophy & Functional Conditioning',
    bio: 'Certified CSCS coach with 8+ years experience in strength training, Olympic weightlifting, and athletic performance.',
    rating: 4.9,
    totalClients: 42,
    phone: '+91 98112 34567',
    email: 'jordan.lee@fitpulse.com',
    qualifications: [
      'CSCS (Certified Strength & Conditioning Specialist)',
      'USAW Level 2 Olympic Weightlifting Coach',
      'Precision Nutrition Certified (Pn1)',
      'B.S. in Kinesiology & Exercise Science',
    ],
    specializations: [
      'Hypertrophy & Lean Muscle Gain',
      'Functional Conditioning & Mobility',
      'Olympic Weightlifting & Powerlifting',
      'Biomechanical Form Assessment & Injury Prevention',
    ],
  );

  /// Recent attendance history
  static final List<AttendanceRecord> demoAttendance = _buildDemoAttendance();

  static List<AttendanceRecord> _buildDemoAttendance() {
    final now = DateTime.now();
    final List<AttendanceRecord> records = [];

    final locations = [
      'Downtown Main Floor',
      'Olympic Lifting Zone',
      'CrossFit Arena',
      'Cardio Deck & Track',
      'Strength & Conditioning Floor',
    ];

    // 1. Current Month: Exactly 18 visits up to today
    final List<int> currentMonthDays;
    if (now.day >= 18) {
      final step = (now.day - 1) / 17.0;
      final set = <int>{};
      for (int i = 0; i < 18; i++) {
        set.add((1 + (i * step).round()).clamp(1, now.day));
      }
      int candidate = now.day;
      while (set.length < 18 && candidate >= 1) {
        set.add(candidate);
        candidate--;
      }
      currentMonthDays = set.toList()..sort();
    } else {
      currentMonthDays = List.generate(18, (i) => (i % now.day) + 1);
    }

    // Add 18 visits for current month
    for (int i = 0; i < currentMonthDays.length; i++) {
      final day = currentMonthDays[i];
      final hour = i % 2 == 0 ? 6 : 17;
      final minute = (i * 7) % 45;
      final durationMins = 65 + ((i * 13) % 40); // 65m - 105m
      final checkInTime = DateTime(now.year, now.month, day, hour, minute);
      final checkOutTime = checkInTime.add(Duration(minutes: durationMins));
      final location = locations[i % locations.length];

      records.add(
        AttendanceRecord(
          id: 'ATT-${now.year}-${now.month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}-$i',
          memberId: 'GM-1024',
          checkIn: checkInTime,
          checkOut: checkOutTime,
          location: location,
          status: 'Completed',
        ),
      );
    }

    // 2. Previous months in current year (Months 1 to now.month - 1)
    final monthlyCounts = [18, 16, 20, 17, 19, 18, 21, 18, 19, 20, 18, 18];
    for (int m = 1; m < now.month; m++) {
      final count = monthlyCounts[(m - 1) % monthlyCounts.length];
      final daysInMonth = DateTime(now.year, m + 1, 0).day;
      for (int k = 0; k < count; k++) {
        final day = ((k * (daysInMonth - 1)) ~/ count) + 1;
        final hour = k % 2 == 0 ? 7 : 18;
        final minute = (k * 11) % 45;
        final durationMins = 60 + ((k * 15) % 45);
        final checkIn = DateTime(now.year, m, day, hour, minute);
        records.add(
          AttendanceRecord(
            id: 'ATT-${now.year}-${m.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}-$k',
            memberId: 'GM-1024',
            checkIn: checkIn,
            checkOut: checkIn.add(Duration(minutes: durationMins)),
            location: locations[(m + k) % locations.length],
            status: 'Completed',
          ),
        );
      }
    }

    // 3. Previous year (now.year - 1): Nov and Dec records for historical browsing
    for (int m = 10; m <= 12; m++) {
      final daysInMonth = DateTime(now.year - 1, m + 1, 0).day;
      for (int k = 0; k < 18; k++) {
        final day = ((k * (daysInMonth - 1)) ~/ 18) + 1;
        final hour = 7;
        final checkIn = DateTime(now.year - 1, m, day, hour, 30);
        records.add(
          AttendanceRecord(
            id: 'ATT-${now.year - 1}-${m.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}-$k',
            memberId: 'GM-1024',
            checkIn: checkIn,
            checkOut: checkIn.add(const Duration(minutes: 80)),
            location: locations[k % locations.length],
            status: 'Completed',
          ),
        );
      }
    }

    // Sort newest first
    records.sort((a, b) => b.checkIn.compareTo(a.checkIn));
    return records;
  }

  /// Active workout plan
  static const List<Workout> demoWorkouts = [
    Workout(
      id: 'WK-01',
      title: 'Upper Body Power & Hypertrophy',
      category: 'Strength',
      durationMinutes: 60,
      level: 'Intermediate',
      notes: 'Focus on full range of motion and explosive concentric phase.',
      exercises: [
        Exercise(
          id: 'EX-01',
          name: 'Barbell Incline Bench Press',
          targetMuscle: 'Upper Chest & Front Delts',
          sets: 4,
          reps: 8,
          weightKg: 75.0,
          restSeconds: 90,
          instructions:
              'Set incline bench to 30°. Grip barbell slightly wider than shoulder-width. Lower bar with control to upper chest, then press upward explosively while keeping shoulder blades retracted.',
        ),
        Exercise(
          id: 'EX-02',
          name: 'Weighted Pull-Ups',
          targetMuscle: 'Lats & Upper Back',
          sets: 4,
          reps: 6,
          weightKg: 10.0,
          restSeconds: 90,
          instructions:
              'Attach weight belt securely. Grip pull-up bar with overhand grip slightly outside shoulders. Pull elbows down and back until chin clears the bar. Lower with full control.',
        ),
        Exercise(
          id: 'EX-03',
          name: 'Standing Overhead Barbell Press',
          targetMuscle: 'Shoulders & Triceps',
          sets: 3,
          reps: 10,
          weightKg: 45.0,
          restSeconds: 60,
          instructions:
              'Hold barbell at clavicle height with elbows under wrists. Brace core and glutes. Press bar straight upward overhead until arms lock out, then lower back to collarbone with control.',
        ),
      ],
    ),
    Workout(
      id: 'WK-02',
      title: 'Lower Body Strength & Core',
      category: 'Strength',
      durationMinutes: 55,
      level: 'Intermediate',
      notes: 'Prioritize hip hinge depth and controlled eccentric tempo.',
      exercises: [
        Exercise(
          id: 'EX-04',
          name: 'Barbell Back Squat',
          targetMuscle: 'Quadriceps & Glutes',
          sets: 5,
          reps: 5,
          weightKg: 110.0,
          restSeconds: 120,
          instructions:
              'Rest barbell on upper traps. Feet shoulder-width apart, toes slightly flared. Descend by hinging hips back and bending knees until hip crease is below knees. Drive through heels to stand.',
        ),
        Exercise(
          id: 'EX-05',
          name: 'Romanian Deadlift',
          targetMuscle: 'Hamstrings & Posterior Chain',
          sets: 3,
          reps: 10,
          weightKg: 85.0,
          restSeconds: 90,
          instructions:
              'Stand tall holding barbell with overhand grip. Keep slight bend in knees. Hinge at hips pushing hips backward until hamstrings stretch, then engage glutes to return upright.',
        ),
      ],
    ),
  ];

  /// Initial completed workout logs for demonstration member Alex Morgan
  static final List<CompletedWorkout> demoCompletedWorkouts = [
    CompletedWorkout(
      id: 'COMP-101',
      workoutId: 'WK-02',
      workoutTitle: 'Lower Body Strength & Core',
      category: 'Strength',
      completedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      durationMinutes: 52,
      totalExercises: 2,
      totalSetsCompleted: 8,
      totalVolumeKg: 3820.0,
    ),
    CompletedWorkout(
      id: 'COMP-102',
      workoutId: 'WK-01',
      workoutTitle: 'Upper Body Power & Hypertrophy',
      category: 'Strength',
      completedAt: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
      durationMinutes: 61,
      totalExercises: 3,
      totalSetsCompleted: 11,
      totalVolumeKg: 4210.0,
    ),
    CompletedWorkout(
      id: 'COMP-103',
      workoutId: 'WK-02',
      workoutTitle: 'Lower Body Strength & Core',
      category: 'Strength',
      completedAt: DateTime.now().subtract(const Duration(days: 5, hours: 3)),
      durationMinutes: 54,
      totalExercises: 2,
      totalSetsCompleted: 8,
      totalVolumeKg: 3750.0,
    ),
    CompletedWorkout(
      id: 'COMP-104',
      workoutId: 'WK-01',
      workoutTitle: 'Upper Body Power & Hypertrophy',
      category: 'Strength',
      completedAt: DateTime.now().subtract(const Duration(days: 7, hours: 5)),
      durationMinutes: 58,
      totalExercises: 3,
      totalSetsCompleted: 11,
      totalVolumeKg: 4150.0,
    ),
  ];

  /// Diet plan assigned to Alex Morgan by Coach Jordan Lee
  static final DietPlan demoDietPlan = DietPlan(
    id: 'DP-2026',
    title: 'Lean Muscle & Metabolic Optimization',
    goal: 'Muscle Gain & Leanness',
    assignedProfessional: 'Coach Jordan Lee, CSCS',
    startDate: DateTime(2026, 1, 15),
    lastUpdated: DateTime(2026, 11, 10),
    dailyCalorieTarget: 2650,
    proteinGrams: 180,
    carbsGrams: 280,
    fatGrams: 75,
    hydrationRecommendation: '3.5 - 4.0 Litres daily',
    trainerGeneralNotes:
        'Focus on nutrient timing around workouts. Drink 500ml water immediately upon waking. Consume your pre-workout meal 90 minutes prior to training for optimal glycogen storage. Avoid heavy sodium or processed foods late in the evening.',
    mealSummaries: const [
      'Breakfast: 4 whole eggs, oats with berries & raw honey (650 kcal, 42g P)',
      'Mid-Morning: Greek yogurt, almonds & whey protein shake (420 kcal, 38g P)',
      'Lunch: Grilled chicken breast, brown basmati rice & steamed broccoli (720 kcal, 50g P)',
      'Pre-Workout: 1 banana, rice cakes with peanut butter (310 kcal, 8g P)',
      'Dinner: Pan-seared salmon fillet, sweet potato mash & mixed greens (550 kcal, 42g P)',
    ],
    days: [
      DietDay(
        dayName: 'Training Day (Mon, Thu, Fri)',
        description:
            'Higher carbohydrate fueling day designed around heavy lifting sessions.',
        dayCalorieTarget: 2650,
        dayProteinGrams: 180,
        dayCarbsGrams: 280,
        dayFatGrams: 75,
        meals: const [
          Meal(
            id: 'M-01',
            name: 'Breakfast',
            scheduledTime: '07:30 AM',
            calories: 650,
            proteinGrams: 42,
            carbsGrams: 68,
            fatGrams: 22,
            trainerNotes:
                'Cook eggs with light cooking spray. Drink a glass of warm water with lemon.',
            foodItems: [
              MealFoodItem(
                name: 'Large Pasture-Raised Whole Eggs',
                portionSize: '4 whole eggs (200g)',
                notes: 'Poached or soft-scrambled',
              ),
              MealFoodItem(
                name: 'Rolled Oats with Fresh Blueberries',
                portionSize: '80g dry oats + 50g blueberries',
                notes: 'Cook in water or unsweetened almond milk',
              ),
              MealFoodItem(
                name: 'Whole Grain Sourdough Toast',
                portionSize: '1 thick slice (45g)',
              ),
            ],
          ),
          Meal(
            id: 'M-02',
            name: 'Mid-Morning Snack',
            scheduledTime: '10:30 AM',
            calories: 420,
            proteinGrams: 38,
            carbsGrams: 18,
            fatGrams: 12,
            trainerNotes:
                'Quick protein top-up between breakfast and lunch to maintain amino acid levels.',
            foodItems: [
              MealFoodItem(
                name: '0% Fat Plain Greek Yogurt',
                portionSize: '200g bowl',
              ),
              MealFoodItem(
                name: 'Whey Protein Isolate',
                portionSize: '1 scoop (30g)',
                notes: 'Mix into yogurt or drink with cold water',
              ),
              MealFoodItem(
                name: 'Raw Crushed Almonds',
                portionSize: '25g (approx. 20 almonds)',
              ),
            ],
          ),
          Meal(
            id: 'M-03',
            name: 'Lunch',
            scheduledTime: '01:30 PM',
            calories: 720,
            proteinGrams: 52,
            carbsGrams: 76,
            fatGrams: 14,
            trainerNotes:
                'Major midday fuel source. Season chicken with herbs and garlic.',
            foodItems: [
              MealFoodItem(
                name: 'Grilled Skinless Chicken Breast',
                portionSize: '200g (cooked weight)',
                notes: 'Seasoned with oregano, paprika, and garlic',
              ),
              MealFoodItem(
                name: 'Steamed Brown Basmati Rice',
                portionSize: '180g (cooked weight)',
              ),
              MealFoodItem(
                name: 'Steamed Broccoli & Zucchini Florets',
                portionSize: '150g',
              ),
              MealFoodItem(
                name: 'Cold-Pressed Extra Virgin Olive Oil',
                portionSize: '1 tsp (5ml)',
                notes: 'Drizzle over steamed greens',
              ),
            ],
          ),
          Meal(
            id: 'M-04',
            name: 'Pre-Workout Snack',
            scheduledTime: '04:30 PM',
            calories: 310,
            proteinGrams: 8,
            carbsGrams: 46,
            fatGrams: 10,
            trainerNotes:
                'Eat 60-90 minutes prior to training session for sustained glycogen.',
            foodItems: [
              MealFoodItem(
                name: 'Ripe Medium Banana',
                portionSize: '1 medium fruit (120g)',
              ),
              MealFoodItem(
                name: 'Brown Rice Cakes',
                portionSize: '2 cakes (20g)',
              ),
              MealFoodItem(
                name: 'Natural Crunchy Peanut Butter',
                portionSize: '20g (1 tablespoon)',
                notes: 'Spread over rice cakes',
              ),
            ],
          ),
          Meal(
            id: 'M-05',
            name: 'Dinner',
            scheduledTime: '08:00 PM',
            calories: 550,
            proteinGrams: 40,
            carbsGrams: 48,
            fatGrams: 18,
            trainerNotes:
                'Nutrient-dense recovery dinner rich in omega-3 fatty acids.',
            foodItems: [
              MealFoodItem(
                name: 'Pan-Seared Wild Alaskan Salmon Fillet',
                portionSize: '180g fillet',
                notes: 'Pan-seared with sea salt and lemon juice',
              ),
              MealFoodItem(
                name: 'Baked Sweet Potato Mash',
                portionSize: '200g',
              ),
              MealFoodItem(
                name: 'Steamed Asparagus & Baby Spinach',
                portionSize: '120g',
              ),
            ],
          ),
        ],
      ),
      DietDay(
        dayName: 'Recovery Day (Wed, Sun)',
        description:
            'Lower carb, moderate fat recovery day to support tissue repair and rest.',
        dayCalorieTarget: 2350,
        dayProteinGrams: 180,
        dayCarbsGrams: 200,
        dayFatGrams: 85,
        meals: const [
          Meal(
            id: 'M-06',
            name: 'Breakfast',
            scheduledTime: '08:00 AM',
            calories: 580,
            proteinGrams: 40,
            carbsGrams: 45,
            fatGrams: 24,
            trainerNotes:
                'Healthy fats and protein to support sustained morning satiety on rest days.',
            foodItems: [
              MealFoodItem(
                name: 'Whole Eggs with Egg Whites Scramble',
                portionSize: '3 whole eggs + 2 egg whites',
              ),
              MealFoodItem(
                name: 'Hass Avocado Slices',
                portionSize: '1/2 medium avocado (75g)',
              ),
              MealFoodItem(
                name: 'Rye Toast',
                portionSize: '1 slice (40g)',
              ),
            ],
          ),
          Meal(
            id: 'M-07',
            name: 'Lunch',
            scheduledTime: '01:00 PM',
            calories: 680,
            proteinGrams: 48,
            carbsGrams: 55,
            fatGrams: 22,
            trainerNotes: 'Lean beef provides iron and zinc for recovery.',
            foodItems: [
              MealFoodItem(
                name: 'Extra Lean Grass-Fed Beef Mince (95%)',
                portionSize: '180g (cooked weight)',
              ),
              MealFoodItem(
                name: 'Quinoa & Black Beans Medley',
                portionSize: '150g (cooked)',
              ),
              MealFoodItem(
                name: 'Mixed Leaf Garden Salad',
                portionSize: '150g with balsamic vinegar',
              ),
            ],
          ),
          Meal(
            id: 'M-08',
            name: 'Afternoon Snack',
            scheduledTime: '04:30 PM',
            calories: 380,
            proteinGrams: 32,
            carbsGrams: 22,
            fatGrams: 14,
            trainerNotes: 'Keep hydrated with water or herbal infusion.',
            foodItems: [
              MealFoodItem(
                name: 'Cottage Cheese (2% low fat)',
                portionSize: '200g bowl',
              ),
              MealFoodItem(
                name: 'Mixed Raw Walnuts & Cashews',
                portionSize: '20g',
              ),
              MealFoodItem(
                name: 'Fresh Strawberries',
                portionSize: '100g sliced',
              ),
            ],
          ),
          Meal(
            id: 'M-09',
            name: 'Dinner',
            scheduledTime: '07:30 PM',
            calories: 610,
            proteinGrams: 46,
            carbsGrams: 42,
            fatGrams: 22,
            trainerNotes: 'Light and easily digestible evening meal.',
            foodItems: [
              MealFoodItem(
                name: 'Oven-Baked Cod or White Fish',
                portionSize: '220g fillet',
                notes: 'Baked with garlic, parsley, and lemon',
              ),
              MealFoodItem(
                name: 'Steamed Jasmine Rice',
                portionSize: '120g (cooked)',
              ),
              MealFoodItem(
                name: 'Roasted Mediterranean Vegetables',
                portionSize: '180g (bell peppers, zucchini, onion)',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  /// Fitness progress measurements (actual recorded entries)
  static final List<FitnessMeasurement> demoMeasurements = [
    FitnessMeasurement(
      id: 'FM-01',
      memberId: 'GM-1024',
      date: DateTime(2026, 11, 1),
      weightKg: 78.4,
      bodyFatPercentage: 14.2,
      muscleMassKg: 64.1,
      chestCm: 104.0,
      waistCm: 81.5,
      bmi: 23.4,
    ),
    FitnessMeasurement(
      id: 'FM-02',
      memberId: 'GM-1024',
      date: DateTime(2026, 10, 1),
      weightKg: 79.1,
      bodyFatPercentage: 15.0,
      muscleMassKg: 63.5,
      chestCm: 103.0,
      waistCm: 82.5,
      bmi: 23.8,
    ),
    FitnessMeasurement(
      id: 'FM-03',
      memberId: 'GM-1024',
      date: DateTime(2026, 9, 1),
      weightKg: 79.8,
      bodyFatPercentage: 15.6,
      muscleMassKg: 63.0,
      chestCm: 102.5,
      waistCm: 83.0,
      bmi: 24.1,
    ),
    FitnessMeasurement(
      id: 'FM-04',
      memberId: 'GM-1024',
      date: DateTime(2026, 8, 1),
      weightKg: 80.5,
      bodyFatPercentage: 16.2,
      muscleMassKg: 62.4,
      chestCm: 102.0,
      waistCm: 84.0,
      bmi: 24.5,
    ),
  ];

  /// Personal fitness goals for demonstration member Alex Morgan
  static final List<FitnessGoal> demoGoals = [
    FitnessGoal(
      id: 'GOAL-01',
      memberId: 'GM-1024',
      title: 'Target Body Weight',
      metricType: 'Weight',
      startValue: 80.5,
      currentValue: 78.4,
      targetValue: 76.5,
      unit: 'kg',
      startDate: DateTime(2026, 8, 1),
      targetDate: DateTime(2026, 12, 31),
    ),
    FitnessGoal(
      id: 'GOAL-02',
      memberId: 'GM-1024',
      title: 'Target Body Fat',
      metricType: 'Body Fat',
      startValue: 16.2,
      currentValue: 14.2,
      targetValue: 12.5,
      unit: '%',
      startDate: DateTime(2026, 8, 1),
      targetDate: DateTime(2027, 2, 28),
    ),
  ];

  /// Available gym classes
  static final List<GymClass> demoClasses = [
    GymClass(
      id: 'CLS-01',
      title: 'High-Octane Spin Revolution',
      trainerName: 'Sara Jenkins',
      startTime: DateTime.now().add(const Duration(hours: 4)),
      durationMinutes: 45,
      capacity: 25,
      bookedCount: 22,
      room: 'Studio A (Cycle Studio)',
      category: 'Spin',
      difficulty: 'Intermediate',
      description:
          'High-intensity indoor cycling interval training designed to push your cardiovascular capacity and burn maximal calories with rhythm-based sprints and climbs.',
      instructorBio:
          'Sara is an elite certified spinning instructor with over 7 years of studio endurance training experience and a passion for high-energy playlists.',
    ),
    GymClass(
      id: 'CLS-02',
      title: 'Power Vinyasa Flow Yoga',
      trainerName: 'Maya Patel',
      startTime: DateTime.now().add(const Duration(hours: 6)),
      durationMinutes: 60,
      capacity: 20,
      bookedCount: 15,
      room: 'Mind & Body Studio',
      category: 'Yoga',
      difficulty: 'All Levels',
      description:
          'Dynamic and breath-synchronized flow combining core engagement, active hip openers, balance postures, and mindful decompression.',
      instructorBio:
          'RYT-500 certified yoga instructor specializing in mobility, functional flexibility, and mindful breathwork for strength athletes.',
    ),
    GymClass(
      id: 'CLS-03',
      title: 'CrossFit Metabolic Conditioning',
      trainerName: 'Jordan Lee',
      startTime: DateTime.now().add(const Duration(hours: 8)),
      durationMinutes: 50,
      capacity: 16,
      bookedCount: 16, // Full
      room: 'CrossFit Arena',
      category: 'CrossFit',
      difficulty: 'Advanced',
      description:
          'High-workload barbell, kettlebell, and gymnastic conditioning circuits focusing on power endurance, lactate tolerance, and work capacity.',
      instructorBio:
          'CSCS coach and Olympic lifting specialist with 8+ years experience guiding functional fitness athletes.',
    ),
    GymClass(
      id: 'CLS-04',
      title: 'Boxing Conditioning & Heavy Bags',
      trainerName: 'Marcus Reed',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      durationMinutes: 60,
      capacity: 18,
      bookedCount: 10,
      room: 'Boxing Studio & Ringside',
      category: 'Boxing',
      difficulty: 'Intermediate',
      description:
          'Combination punching, footwork agility, heavy bag rounds, and rotational core intervals for full-body athletic conditioning.',
      instructorBio:
          'Former amateur Golden Gloves competitor and certified boxing fitness coach specializing in authentic technique and conditioning.',
    ),
    GymClass(
      id: 'CLS-05',
      title: 'Zumba High-Energy Dance Cardio',
      trainerName: 'Elena Gomez',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
      durationMinutes: 45,
      capacity: 30,
      bookedCount: 24,
      room: 'Studio B (Main Dance Floor)',
      category: 'Zumba',
      difficulty: 'All Levels',
      description:
          'Electrifying dance fitness party moving to Latin and world rhythms. Easy-to-follow choreography focused on cardiovascular conditioning and fun.',
      instructorBio:
          'Licensed Zumba and aerobic fitness trainer bringing joyful, uplifting energy to every group session.',
    ),
    GymClass(
      id: 'CLS-06',
      title: 'Restorative Yin Yoga & Sound Bath',
      trainerName: 'Maya Patel',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      durationMinutes: 75,
      capacity: 15,
      bookedCount: 7,
      room: 'Mind & Body Studio',
      category: 'Yoga',
      difficulty: 'All Levels',
      description:
          'Deep passive stretching held for 3-5 minutes per posture targeting connective tissue and fascia, concluding with an acoustic crystal singing bowl meditation.',
      instructorBio:
          'RYT-500 certified yoga instructor specializing in mobility, functional flexibility, and mindful breathwork.',
    ),
  ];

  /// Member class bookings for Alex Morgan (GM-1024)
  static final List<ClassBooking> demoBookings = [
    ClassBooking(
      id: 'BKG-501',
      classId: 'CLS-01',
      className: 'High-Octane Spin Revolution',
      memberId: 'GM-1024',
      classStartTime: DateTime.now().add(const Duration(hours: 4)),
      bookedAt: DateTime.now().subtract(const Duration(hours: 24)),
      status: 'Confirmed',
      trainerName: 'Sara Jenkins',
      room: 'Studio A (Cycle Studio)',
      durationMinutes: 45,
    ),
    ClassBooking(
      id: 'BKG-500',
      classId: 'CLS-02',
      className: 'Power Vinyasa Flow Yoga',
      memberId: 'GM-1024',
      classStartTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      bookedAt: DateTime.now().subtract(const Duration(days: 4)),
      status: 'Attended',
      trainerName: 'Maya Patel',
      room: 'Mind & Body Studio',
      durationMinutes: 60,
    ),
    ClassBooking(
      id: 'BKG-499',
      classId: 'CLS-03',
      className: 'CrossFit Metabolic Conditioning',
      memberId: 'GM-1024',
      classStartTime: DateTime.now().subtract(const Duration(days: 6, hours: 2)),
      bookedAt: DateTime.now().subtract(const Duration(days: 8)),
      status: 'Cancelled',
      trainerName: 'Jordan Lee',
      room: 'CrossFit Arena',
      durationMinutes: 50,
    ),
  ];

  /// Personal training sessions for Alex Morgan (GM-1024)
  static final List<TrainingSession> demoTrainingSessions = [
    TrainingSession(
      id: 'PTS-101',
      trainerId: 'TR-301',
      trainerName: 'Jordan Lee',
      memberId: 'GM-1024',
      sessionTitle: '1-on-1 Strength & Technique Coaching',
      sessionDate: DateTime.now().add(const Duration(days: 2, hours: 3)),
      durationMinutes: 60,
      location: 'Olympic Lifting Platform 2 (Main Floor)',
      status: 'Scheduled',
      focusArea: 'Barbell back squat depth, bar trajectory & posterior chain engagement.',
      notes: 'Please bring your lifting shoes and perform a 10-minute dynamic warm-up prior to session start.',
    ),
    TrainingSession(
      id: 'PTS-102',
      trainerId: 'TR-301',
      trainerName: 'Jordan Lee',
      memberId: 'GM-1024',
      sessionTitle: 'Upper Body Hypertrophy & Form Review',
      sessionDate: DateTime.now().add(const Duration(days: 6, hours: 2)),
      durationMinutes: 45,
      location: 'Strength & Conditioning Floor - Zone A',
      status: 'Scheduled',
      focusArea: 'Incline dumbbell press sticking point analysis and rotator cuff activation.',
      notes: 'Focus on eccentric tempo (3 seconds down) and scapular retraction.',
    ),
    TrainingSession(
      id: 'PTS-100',
      trainerId: 'TR-301',
      trainerName: 'Jordan Lee',
      memberId: 'GM-1024',
      sessionTitle: 'Initial Biomechanical Movement Assessment',
      sessionDate: DateTime.now().subtract(const Duration(days: 12, hours: 4)),
      durationMinutes: 60,
      location: 'Private Assessment Studio B',
      status: 'Completed',
      focusArea: 'Overhead squat mobility screening, ankle dorsiflexion, and core bracing baseline.',
      notes: 'Assessment completed. Customized 4-day split assigned with emphasis on hip mobility.',
    ),
  ];

  /// Payment records
  static final List<Payment> demoPayments = [
    Payment(
      id: 'PAY-8921',
      memberId: 'GM-1024',
      amount: 24999.0,
      date: DateTime(2026, 1, 1, 11, 30),
      status: 'Paid',
      paymentMethod: 'UPI (Google Pay)',
      invoiceNumber: 'INV-2026-0042',
      description: 'Annual Premium Membership Subscription (12 Months)',
      serviceName: 'Premium Annual All-Access Membership',
      subtotal: 21185.59,
      taxAmount: 3813.41,
    ),
    Payment(
      id: 'PAY-7450',
      memberId: 'GM-1024',
      amount: 8500.0,
      date: DateTime(2025, 8, 14, 15, 45),
      status: 'Paid',
      paymentMethod: 'Credit Card (Visa •••• 4242)',
      invoiceNumber: 'INV-2025-0819',
      description: 'Personal Training Coaching Block (10 Sessions with Coach Jordan Lee)',
      serviceName: '1-on-1 Personal Training (10 Sessions)',
      subtotal: 7203.39,
      taxAmount: 1296.61,
    ),
    Payment(
      id: 'PAY-6120',
      memberId: 'GM-1024',
      amount: 19999.0,
      date: DateTime(2025, 1, 1, 10, 15),
      status: 'Paid',
      paymentMethod: 'Net Banking (HDFC Bank)',
      invoiceNumber: 'INV-2025-0012',
      description: 'Annual Standard Fitness Membership (12 Months)',
      serviceName: 'Standard Annual Gym Membership',
      subtotal: 16948.31,
      taxAmount: 3050.69,
    ),
    Payment(
      id: 'PAY-5580',
      memberId: 'GM-1024',
      amount: 2499.0,
      date: DateTime(2024, 11, 20, 18, 20),
      status: 'Paid',
      paymentMethod: 'UPI (PhonePe)',
      invoiceNumber: 'INV-2024-0498',
      description: 'Fitness Nutrition Assessment & Custom Meal Plan Protocol',
      serviceName: 'Sports Nutrition Consultation',
      subtotal: 2117.80,
      taxAmount: 381.20,
    ),
  ];

  /// Notifications
  static final List<NotificationItem> demoNotifications = [
    NotificationItem(
      id: 'NOTIF-01',
      title: 'Class Booking Confirmed',
      message: 'Your spot in "High-Octane Spin Revolution" at 6:00 PM today is reserved.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: 'class',
      actionRoute: '/classes/bookings',
      actionLabel: 'View Reservation',
    ),
    NotificationItem(
      id: 'NOTIF-02',
      title: 'Milestone Unlocked! 🎯',
      message: 'You have completed 18 visits this month! Great dedication toward your fitness goal.',
      timestamp: DateTime.now().subtract(const Duration(hours: 14)),
      isRead: false,
      type: 'workout',
      actionRoute: '/attendance',
      actionLabel: 'View Attendance',
    ),
    NotificationItem(
      id: 'NOTIF-03',
      title: 'Coach Jordan Lee Session Check-in',
      message: 'Your customized 1-on-1 technique coaching session is confirmed for Thursday at 10:00 AM.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: false,
      type: 'trainer',
      actionRoute: '/trainer',
      actionLabel: 'View Session Details',
    ),
    NotificationItem(
      id: 'NOTIF-04',
      title: 'Payment Receipt Available',
      message: 'Official invoice INV-2026-0042 for Annual Premium Subscription (₹24,999) has been recorded.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      isRead: true,
      type: 'payment',
      actionRoute: '/payments/PAY-8921',
      actionLabel: 'View Tax Invoice',
    ),
    NotificationItem(
      id: 'NOTIF-05',
      title: 'Membership Status: Active',
      message: 'Your Annual Premium All-Access membership is active and valid through December 30, 2026.',
      timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 2)),
      isRead: true,
      type: 'membership',
      actionRoute: '/membership',
      actionLabel: 'View Membership',
    ),
    NotificationItem(
      id: 'NOTIF-06',
      title: 'Lean Muscle Diet Protocol Assigned',
      message: 'Coach Jordan Lee published your daily nutritional protocol targeting 2,650 kcal and 180g protein.',
      timestamp: DateTime.now().subtract(const Duration(days: 6, hours: 5)),
      isRead: true,
      type: 'diet',
      actionRoute: '/diet-plan',
      actionLabel: 'View Diet Plan',
    ),
  ];

  /// Announcements
  static final List<Announcement> demoAnnouncements = [
    Announcement(
      id: 'ANN-101',
      title: 'Holiday Schedule & Facility Maintenance Notice',
      content:
          'Please be advised that the hydrotherapy suite, Finnish sauna, and cold-plunge recovery zone will undergo scheduled ozone purification and antimicrobial treatment this coming Sunday between 2:00 PM and 5:00 PM.\n\nThe main strength deck, Olympic lifting platforms, and cardio mezzanine will remain fully accessible 24/7 without interruption. Locker rooms, shower suites, and towel services will operate as usual.\n\nWe apologize for any temporary inconvenience as we maintain our rigorous facility hygiene standards.',
      shortDescription:
          'Spa & recovery suite scheduled ozone purification on Sunday from 2 PM to 5 PM. Gym floor remains accessible 24/7.',
      date: DateTime.now().subtract(const Duration(days: 2)),
      author: 'Gym Administration',
      category: 'Facility Maintenance',
      priority: 'Important',
      isPublished: true,
      attachments: const [
        AnnouncementAttachment(
          id: 'ATT-01',
          fileName: 'Holiday_Operating_Hours_2026.pdf',
          fileType: 'pdf',
          fileSize: '480 KB',
          url: 'https://fitpulse.demo/docs/holiday_schedule.pdf',
        ),
      ],
    ),
    Announcement(
      id: 'ANN-102',
      title: 'New Rogue Olympic Lifting Platforms Installed',
      content:
          'We are thrilled to unveil two brand-new custom Rogue Olympic Weightlifting platforms in the rear strength arena (Platforms 3 & 4).\n\nUpgrades include:\n• Precision IWF-calibrated competition steel and urethane bumper plates\n• 20kg & 15kg Eleiko Olympic training barbells with needle-bearing collars\n• Heavy-duty rubber vibration dampening shock tiles\n• Dual magnetic chalk dispensers and rapid-lock safety collars\n\nMembers are kindly reminded to wipe down barbells after chalk usage and always use bumper plates when dropping weights from overhead.',
      shortDescription:
          'Platforms 3 and 4 upgraded with competition bumper plates, calibrated Eleiko barbells, and chalk stations.',
      date: DateTime.now().subtract(const Duration(days: 6)),
      author: 'Head Coach Jordan Lee',
      category: 'Equipment Upgrade',
      priority: 'Normal',
      isPublished: true,
      attachments: const [
        AnnouncementAttachment(
          id: 'ATT-02',
          fileName: 'Olympic_Platform_Etiquette_Guide.pdf',
          fileType: 'pdf',
          fileSize: '1.2 MB',
          url: 'https://fitpulse.demo/docs/platform_rules.pdf',
        ),
        AnnouncementAttachment(
          id: 'ATT-03',
          fileName: 'Equipment_Overview_Diagram.png',
          fileType: 'image',
          fileSize: '850 KB',
          url: 'https://fitpulse.demo/images/platforms.png',
        ),
      ],
    ),
    Announcement(
      id: 'ANN-103',
      title: 'Spring Functional Fitness Challenge 2026',
      content:
          'Registration is officially open for our annual in-house Spring Functional Fitness Throwdown!\n\nThe challenge features individual and partner divisions across beginner, intermediate, and RX categories.\n\nEvent Stations:\n1. 1,000m SkiErg pacing challenge\n2. 50m Heavy Sled Push (125kg / 75kg)\n3. 80m Burpee Broad Jumps\n4. 1,000m Concept2 Rower sprint\n5. 200m Farmer’s Carry (2x24kg / 2x16kg)\n6. 100 Wall Balls (9kg / 6kg standard)\n\nSign up at the front reception desk or speak directly with your assigned coach. Custom finisher medals and sponsor gift packs provided for all podium finishers!',
      shortDescription:
          'Annual in-house fitness throwdown featuring 6 functional workout stations. Registration open at the front desk.',
      date: DateTime.now().subtract(const Duration(days: 10)),
      author: 'Event Coordinator Sara Jenkins',
      category: 'Events & Competitions',
      priority: 'Normal',
      isPublished: true,
      attachments: const [
        AnnouncementAttachment(
          id: 'ATT-04',
          fileName: 'Spring_Throwdown_Event_Handbook.pdf',
          fileType: 'pdf',
          fileSize: '2.4 MB',
          url: 'https://fitpulse.demo/docs/throwdown_handbook.pdf',
        ),
      ],
    ),
    // Unpublished draft announcement to verify "Display only published announcements" rule
    Announcement(
      id: 'ANN-DRAFT',
      title: 'Draft: Upcoming Steam Room Tile Renovation',
      content: 'This draft notice is pending contractor confirmation.',
      shortDescription: 'Internal facility draft not yet released to members.',
      date: DateTime.now().subtract(const Duration(days: 12)),
      author: 'Facilities Team',
      category: 'Internal Notice',
      isPublished: false,
    ),
  ];
}
