-- FitPulse Gym Management — Catalog Seed Data (Idempotent)
-- Safe to run after migrations to populate membership plans, trainers, exercises, classes, and published notices.

insert into public.membership_plans (code, name, description, duration, duration_months, price, features, active_status)
values
  (
    'PLAN-PREMIUM-12M',
    'Premium All-Access',
    'Complete 12-month gym, recovery lounge, class, and coaching access.',
    '12 Months',
    12,
    14999.00,
    array[
      '24/7 Unlimited Gym Floor Access',
      'Unlimited Group Fitness & Yoga Classes',
      'Customized Monthly Diet & Nutrition Plan',
      'Bi-weekly Personal Trainer Assessment',
      'Sauna, Steam & Recovery Lounge Access',
      '1 Guest Pass per Month'
    ],
    true
  ),
  (
    'PLAN-ELITE-6M',
    'Semi-Annual Elite',
    '6-month full gym and group class membership.',
    '6 Months',
    6,
    8499.00,
    array[
      'Unlimited Gym Floor Access',
      'Unlimited Group Classes',
      'Monthly Fitness Progress Check-in'
    ],
    true
  ),
  (
    'PLAN-FLEX-1M',
    'Monthly Flex Pass',
    'Flexible month-to-month gym floor access.',
    '1 Month',
    1,
    1799.00,
    array[
      'Standard Gym Floor Access',
      'Locker & Shower Facilities'
    ],
    true
  )
on conflict (code) do nothing;

insert into public.exercises (slug, name, description, target_muscles, equipment, difficulty, category, instructions, common_mistakes, easier_variation, harder_variation, alternative_exercise_slug, rest_seconds)
values
  (
    'ex_bench_press',
    'Barbell Bench Press',
    'Classic horizontal compound chest press.',
    'Chest, Anterior Deltoids & Triceps',
    'Barbell & Rack',
    'Intermediate',
    'Compound',
    array[
      'Lie on the bench with eyes directly beneath the barbell and feet planted firmly.',
      'Pull shoulder blades back and down into the bench; grip bar slightly wider than shoulders.',
      'Lower bar smoothly to mid/lower chest with elbows angled ~45° from torso.',
      'Press cleanly back over shoulders until arms extend.'
    ],
    array[
      'Flaring elbows wide to 90 degrees.',
      'Bouncing the bar off the chest or lifting glutes off the bench.'
    ],
    'Chest Press Machine or Push-ups',
    'Paused Barbell Bench Press',
    'ex_db_incline',
    120
  ),
  (
    'ex_barbell_squat',
    'Barbell Back Squat',
    'Foundational lower-body strength movement.',
    'Quadriceps, Glutes & Core',
    'Barbell & Rack',
    'Intermediate',
    'Compound',
    array[
      'Set rack pins at mid-chest height and place safety arms appropriately.',
      'Rest bar across upper traps/rear delts, grip evenly, and unrack with a tight brace.',
      'Descend with hips and knees bending together while keeping heels planted.',
      'Drive steadily upward while keeping torso angle consistent.'
    ],
    array[
      'Skipping safety spotter arms in the squat rack.',
      'Collapsing knees inward.'
    ],
    'Dumbbell Goblet Squat or Leg Press Machine',
    'Paused Barbell Back Squat',
    'ex_goblet_squat',
    120
  ),
  (
    'ex_rdl',
    'Romanian Deadlift',
    'Posterior chain hip-hinge strength exercise.',
    'Hamstrings, Glutes & Spinal Erectors',
    'Barbell & Rack',
    'Intermediate',
    'Compound',
    array[
      'Hold barbell or dumbbells at hip level with shoulder blades packed down.',
      'Unlock knees slightly and push hips straight back.',
      'Lower weight close down the front of your thighs to mid-shin level and return smoothly.'
    ],
    array[
      'Rounding the lower back.',
      'Letting the bar drift away from the legs.'
    ],
    'Glute Bridge or Light Dumbbell RDL',
    'Tempo Barbell RDL',
    'ex_db_rdl',
    105
  ),
  (
    'ex_plank',
    'Forearm Plank',
    'Isometric core stability hold.',
    'Deep Core, Abdominals & Shoulders',
    'Bodyweight',
    'Beginner',
    'Core',
    array[
      'Rest on forearms with elbows directly under shoulders.',
      'Brace core and glutes to hold a straight line from head to heels.',
      'Breathe steadily for the target hold duration.'
    ],
    array[
      'Letting hips sag toward the floor.',
      'Holding breath during the hold.'
    ],
    'Incline Plank on a sturdy bench',
    'Plank with shoulder taps',
    'ex_dead_bug',
    60
  )
on conflict (slug) do nothing;

insert into public.notifications (id, user_id, title, message, notification_type, action_route, action_label, is_read, is_published)
values
  (
    '00000000-0000-0000-0000-000000000101',
    null,
    'Holiday Schedule & Facility Maintenance Notice',
    'Adjusted facility operating hours and scheduled maintenance details for the upcoming week.',
    'announcement',
    '/announcements',
    'Read Notice',
    false,
    true
  ),
  (
    '00000000-0000-0000-0000-000000000102',
    null,
    'New Olympic Lifting Platforms Installed',
    'Platforms 3 and 4 upgraded with competition bumper plates and calibrated barbells.',
    'announcement',
    '/announcements',
    'Read Notice',
    false,
    true
  )
on conflict (id) do nothing;
