import '../models/fitness_profile.dart';
import '../models/personal_record.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

/// Pure domain engine that supplies the exercise library, generates personalized
/// weekly plans from a [FitnessProfile], and evaluates safe multi-session progression.
class WorkoutPlannerEngine {
  WorkoutPlannerEngine._();

  /// Complete exercise library with step-by-step instructions, common mistakes,
  /// variations, equipment requirements, and safe swap alternatives.
  static final Map<String, ExerciseDetail> exerciseLibrary = {
    // --- WARM-UPS & CARDIO ---
    'wu_treadmill': const ExerciseDetail(
      id: 'wu_treadmill',
      name: 'Brisk Treadmill Walk or Stationary Bike',
      targetMuscles: 'Cardiovascular & Lower Body Warm-Up',
      equipment: 'Cardio Machines',
      difficulty: 'Beginner',
      category: 'Cardio',
      instructions: [
        'Start at a comfortable walking or light pedaling pace for 2 minutes.',
        'Gradually raise pace or light incline/resistance until breathing is slightly elevated.',
        'Maintain relaxed shoulders and steady breathing for 5–10 minutes.',
      ],
      commonMistakes: [
        'Starting too fast before joints feel warm.',
        'Leaning heavily on treadmill handrails instead of keeping an upright posture.',
      ],
      easierVariation: 'Flat pace at gentle walking speed for 5 minutes',
      harderVariation: 'Moderate incline walk (4–6%) or brisk cycling intervals',
      alternativeExerciseId: 'wu_marching',
      alternativeExerciseName: 'March in Place & Arm Circles (Bodyweight)',
      restSeconds: 30,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '5–10 min', durationSeconds: 420),
      ],
    ),
    'wu_marching': const ExerciseDetail(
      id: 'wu_marching',
      name: 'March in Place & Dynamic Arm Circles',
      targetMuscles: 'Full Body Circulation & Shoulder Mobility',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Mobility',
      instructions: [
        'Stand tall and march briskly in place, swinging arms naturally for 3 minutes.',
        'Perform 10 slow forward and 10 backward arm circles with relaxed traps.',
        'Finish with 10 gentle hip hinges and 10 bodyweight torso rotations.',
      ],
      commonMistakes: [
        'Rushing mobility movements with jerky momentum.',
        'Holding your breath instead of breathing smoothly.',
      ],
      easierVariation: 'Seated marching and gentle shoulder rolls',
      harderVariation: 'High-knee march paired with world’s greatest stretch',
      alternativeExerciseId: 'wu_treadmill',
      alternativeExerciseName: 'Brisk Treadmill Walk or Stationary Bike',
      restSeconds: 30,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '5 min', durationSeconds: 300),
      ],
    ),
    'wu_mobility_upper': const ExerciseDetail(
      id: 'wu_mobility_upper',
      name: 'Band Pull-Aparts & Thoracic Openers',
      targetMuscles: 'Shoulders, Upper Back & Thoracic Spine',
      equipment: 'Resistance Bands',
      difficulty: 'Beginner',
      category: 'Mobility',
      instructions: [
        'Hold a light band at shoulder height with straight arms and pull apart smoothly.',
        'Pause 1 second with shoulder blades squeezed together, then return slowly.',
        'Follow with 8 thoracic rotations per side and 1–2 light ramp-up sets on your first lift.',
      ],
      commonMistakes: [
        'Shrugging traps toward your ears while pulling the band.',
        'Arching the lower back to complete the pull.',
      ],
      easierVariation: 'Scapular wall slides without band resistance',
      harderVariation: 'Use medium-tension band with 2-second isometric pause',
      alternativeExerciseId: 'wu_marching',
      alternativeExerciseName: 'March in Place & Dynamic Arm Circles',
      restSeconds: 30,
      sets: [
        SetSpec(setNumber: 1, targetReps: 15, repRangeLabel: '12–15 reps'),
        SetSpec(setNumber: 2, targetReps: 15, repRangeLabel: '12–15 reps'),
      ],
    ),
    'wu_mobility_lower': const ExerciseDetail(
      id: 'wu_mobility_lower',
      name: 'Hip Circles, World’s Greatest Stretch & Air Squats',
      targetMuscles: 'Hips, Ankles, Glutes & Quads',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Mobility',
      instructions: [
        'Perform 8 controlled hip circles per leg to lubricate the hip joint.',
        'Step into a long lunge, place opposite hand down, and rotate chest toward front knee (5/side).',
        'Finish with 10 slow bodyweight squats focusing on balanced foot pressure.',
      ],
      commonMistakes: [
        'Letting heels lift during warm-up air squats.',
        'Forcing deep stretches if hips feel tight—ease into range gradually.',
      ],
      easierVariation: 'Supported chair squats and standing hip swings',
      harderVariation: 'Add a 3-second pause at the bottom of each air squat',
      alternativeExerciseId: 'wu_treadmill',
      alternativeExerciseName: 'Brisk Treadmill Walk or Stationary Bike',
      restSeconds: 30,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '6–8 min', durationSeconds: 420),
      ],
    ),

    // --- COOL-DOWNS ---
    'cd_stretch': const ExerciseDetail(
      id: 'cd_stretch',
      name: 'Easy Walk & Gentle Full-Body Stretching',
      targetMuscles: 'Chest, Lats, Hip Flexors & Hamstrings',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Mobility',
      instructions: [
        'Walk at an easy, relaxed pace for 3 minutes to let breathing normalize.',
        'Hold a gentle doorway chest stretch and hamstring stretch for 20–30 seconds each side if comfortable.',
        'Drink water and take 5 slow nasal breaths before finishing.',
      ],
      commonMistakes: [
        'Bouncing aggressively inside a stretch.',
        'Stretching into sharp joint pain—keep stretches mild and comfortable.',
      ],
      easierVariation: '3 minutes slow walking and seated breathing only',
      harderVariation: 'Add 60-second thoracic foam roll and child’s pose',
      alternativeExerciseId: 'cd_breathing',
      alternativeExerciseName: 'Seated Nasal Breathing & Calf/Quad Stretch',
      restSeconds: 0,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '5 min', durationSeconds: 300),
      ],
    ),
    'cd_breathing': const ExerciseDetail(
      id: 'cd_breathing',
      name: 'Down-Regulation Breathing & Hip Flexor Stretch',
      targetMuscles: 'Nervous System Recovery, Hips & Lower Back',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Mobility',
      instructions: [
        'Kneel comfortably on a mat in a half-kneeling stance and gently tuck pelvis under.',
        'Hold 25 seconds per side without overarching the lower back.',
        'Lie back or sit comfortably for 6 slow 4-second inhales and 6-second exhales.',
      ],
      commonMistakes: [
        'Arching the lumbar spine to force hip extension.',
        'Skipping recovery cool-down immediately after high-effort work.',
      ],
      easierVariation: 'Standing quad stretch holding a wall',
      harderVariation: '90/90 hip switches with controlled breathing',
      alternativeExerciseId: 'cd_stretch',
      alternativeExerciseName: 'Easy Walk & Gentle Full-Body Stretching',
      restSeconds: 0,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '5 min', durationSeconds: 300),
      ],
    ),

    // --- LOWER BODY ---
    'ex_bw_squat': const ExerciseDetail(
      id: 'ex_bw_squat',
      name: 'Bodyweight Squat',
      targetMuscles: 'Quadriceps, Glutes & Core',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Bodyweight',
      instructions: [
        'Stand with feet shoulder-width apart and toes angled slightly outward.',
        'Brace your core gently and sit hips back and down as if lowering onto a chair.',
        'Keep knees tracking over your toes and chest proud down to a comfortable depth.',
        'Push evenly through midfoot and heels to stand tall.',
      ],
      commonMistakes: [
        'Knees caving inward toward each other.',
        'Heels lifting off the floor at the bottom.',
        'Rounding the lower back aggressively.',
      ],
      easierVariation: 'Box or Chair Squat (tap a bench lightly and stand)',
      harderVariation: 'Goblet Squat holding a dumbbell at chest height',
      alternativeExerciseId: 'ex_leg_press',
      alternativeExerciseName: 'Leg Press Machine',
      restSeconds: 75,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–12'),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–12'),
      ],
    ),
    'ex_leg_press': const ExerciseDetail(
      id: 'ex_leg_press',
      name: 'Leg Press Machine',
      targetMuscles: 'Quadriceps & Glutes',
      equipment: 'Machines',
      difficulty: 'Beginner',
      category: 'Machine',
      instructions: [
        'Sit firmly with lower back and hips pressed flush against the seat pad.',
        'Place feet shoulder-width apart in the middle of the sled.',
        'Release safety handles and lower the sled with control until knees reach ~90°.',
        'Press through whole feet without locking knees forcefully at the top.',
      ],
      commonMistakes: [
        'Letting lower back peel off the pad at the bottom.',
        'Locking knees aggressively at top extension.',
      ],
      easierVariation: 'Bodyweight Squat or Box Squat',
      harderVariation: 'Barbell Back Squat',
      alternativeExerciseId: 'ex_bw_squat',
      alternativeExerciseName: 'Bodyweight Squat',
      restSeconds: 75,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–12', targetWeightKg: 60),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–12', targetWeightKg: 60),
      ],
    ),
    'ex_barbell_squat': const ExerciseDetail(
      id: 'ex_barbell_squat',
      name: 'Barbell Back Squat',
      targetMuscles: 'Quadriceps, Glutes & Core',
      equipment: 'Barbell & Rack',
      difficulty: 'Intermediate',
      category: 'Compound',
      requiresSupervisionNote: true,
      instructions: [
        'Set rack pins at mid-chest height and place safety arms appropriately.',
        'Rest bar across upper traps/rear delts, grip evenly, and unrack with a tight brace.',
        'Step back 2–3 steps, inhale into your torso, and descend with hips and knees bending together.',
        'Drive steadily upward while keeping torso angle consistent.',
      ],
      commonMistakes: [
        'Skipping safety spotter arms in the squat rack.',
        'Cutting depth too shallow with excessive weight or collapsing knees inward.',
      ],
      easierVariation: 'Dumbbell Goblet Squat or Leg Press Machine',
      harderVariation: 'Paused Barbell Back Squat (2-sec pause at bottom)',
      alternativeExerciseId: 'ex_goblet_squat',
      alternativeExerciseName: 'Dumbbell Goblet Squat',
      restSeconds: 120,
      coachingCue: 'Use rack safety pins; keep 1–2 reps in reserve on working sets.',
      sets: [
        SetSpec(setNumber: 1, targetReps: 8, repRangeLabel: '6–10', targetWeightKg: 90),
        SetSpec(setNumber: 2, targetReps: 8, repRangeLabel: '6–10', targetWeightKg: 90),
        SetSpec(setNumber: 3, targetReps: 8, repRangeLabel: '6–10', targetWeightKg: 90),
      ],
    ),
    'ex_goblet_squat': const ExerciseDetail(
      id: 'ex_goblet_squat',
      name: 'Dumbbell Goblet Squat',
      targetMuscles: 'Quadriceps, Glutes & Upper Back Posture',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      category: 'Compound',
      instructions: [
        'Cup the top head of one dumbbell against your chest with elbows tucked down.',
        'Stand shoulder-width apart and descend cleanly between your knees.',
        'Keep torso upright and drive evenly through feet to stand.',
      ],
      commonMistakes: [
        'Letting the dumbbell drift forward away from the chest.',
        'Rounding upper back as weight increases.',
      ],
      easierVariation: 'Bodyweight Squat',
      harderVariation: 'Barbell Back Squat',
      alternativeExerciseId: 'ex_bw_squat',
      alternativeExerciseName: 'Bodyweight Squat',
      restSeconds: 90,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '8–12', targetWeightKg: 20),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '8–12', targetWeightKg: 20),
        SetSpec(setNumber: 3, targetReps: 10, repRangeLabel: '8–12', targetWeightKg: 20),
      ],
    ),
    'ex_rdl': const ExerciseDetail(
      id: 'ex_rdl',
      name: 'Romanian Deadlift',
      targetMuscles: 'Hamstrings, Glutes & Spinal Erectors',
      equipment: 'Barbell & Rack',
      difficulty: 'Intermediate',
      category: 'Compound',
      instructions: [
        'Hold barbell or dumbbells at hip level with shoulder blades packed down.',
        'Unlock knees slightly (soft bend) and keep them fixed at that angle.',
        'Push hips straight back while sliding weight close down the front of your thighs.',
        'Stop once hips stop moving back (mid-shin level) and squeeze glutes to stand.',
      ],
      commonMistakes: [
        'Turning the hinge into a squat by bending knees deeper.',
        'Allowing the bar to drift away from the legs or rounding the lower back.',
      ],
      easierVariation: 'Glute Bridge or Light Dumbbell Romanian Deadlift',
      harderVariation: 'Barbell RDL with 3-second eccentric tempo',
      alternativeExerciseId: 'ex_db_rdl',
      alternativeExerciseName: 'Dumbbell Romanian Deadlift',
      restSeconds: 105,
      sets: [
        SetSpec(setNumber: 1, targetReps: 9, repRangeLabel: '8–10', targetWeightKg: 80),
        SetSpec(setNumber: 2, targetReps: 9, repRangeLabel: '8–10', targetWeightKg: 80),
        SetSpec(setNumber: 3, targetReps: 9, repRangeLabel: '8–10', targetWeightKg: 80),
      ],
    ),
    'ex_db_rdl': const ExerciseDetail(
      id: 'ex_db_rdl',
      name: 'Dumbbell Romanian Deadlift',
      targetMuscles: 'Hamstrings & Glutes',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      category: 'Compound',
      instructions: [
        'Hold a pair of dumbbells in front of your thighs with soft knees.',
        'Hinge hips straight back while keeping your spine neutral and dumbbells close.',
        'Drive hips forward smoothly once you feel a gentle hamstring stretch.',
      ],
      commonMistakes: [
        'Looking up forcefully instead of keeping neck neutral with spine.',
        'Dropping dumbbells too low with a rounded back.',
      ],
      easierVariation: 'Glute Bridge',
      harderVariation: 'Single-Leg Dumbbell RDL or Barbell RDL',
      alternativeExerciseId: 'ex_glute_bridge',
      alternativeExerciseName: 'Glute Bridge',
      restSeconds: 90,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '8–10', targetWeightKg: 18),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '8–10', targetWeightKg: 18),
        SetSpec(setNumber: 3, targetReps: 10, repRangeLabel: '8–10', targetWeightKg: 18),
      ],
    ),
    'ex_glute_bridge': const ExerciseDetail(
      id: 'ex_glute_bridge',
      name: 'Glute Bridge',
      targetMuscles: 'Glutes & Hamstrings',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Bodyweight',
      instructions: [
        'Lie on your back with knees bent and feet flat hip-width apart.',
        'Brace your core slightly and press through your heels to lift hips until torso aligns with thighs.',
        'Pause for 1 second squeezing glutes at top, then lower smoothly.',
      ],
      commonMistakes: [
        'Hyperextending the lower back at the top instead of squeezing glutes.',
        'Placing feet too far away or pressing onto toes.',
      ],
      easierVariation: 'Reduced-range pelvic tilt bridge',
      harderVariation: 'Single-leg glute bridge or Dumbbell hip thrust',
      alternativeExerciseId: 'ex_db_rdl',
      alternativeExerciseName: 'Dumbbell Romanian Deadlift',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '12'),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '12'),
      ],
    ),
    'ex_lunges': const ExerciseDetail(
      id: 'ex_lunges',
      name: 'Walking Lunges',
      targetMuscles: 'Quadriceps, Glutes & Single-Leg Stability',
      equipment: 'Bodyweight',
      difficulty: 'Intermediate',
      category: 'Compound',
      instructions: [
        'Stand tall and take a controlled forward stride slightly wider than a tightrope.',
        'Lower back knee smoothly toward the floor while keeping front shin mostly vertical.',
        'Push through front heel to step forward into the next lunge.',
      ],
      commonMistakes: [
        'Stepping on a narrow line causing side-to-side wobble.',
        'Slamming the back knee onto the floor.',
      ],
      easierVariation: 'Split Squat holding a support rail',
      harderVariation: 'Dumbbell Walking Lunges',
      alternativeExerciseId: 'ex_split_squat',
      alternativeExerciseName: 'Bodyweight Split Squat',
      restSeconds: 75,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '10 each leg'),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '10 each leg'),
        SetSpec(setNumber: 3, targetReps: 10, repRangeLabel: '10 each leg'),
      ],
    ),
    'ex_split_squat': const ExerciseDetail(
      id: 'ex_split_squat',
      name: 'Bodyweight Split Squat',
      targetMuscles: 'Quads & Glutes',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Bodyweight',
      instructions: [
        'Take a staggered stance on flat ground with rear heel lifted.',
        'Lower straight down until both knees are roughly at 90 degrees.',
        'Press evenly through the front foot to return up; complete all reps per side.',
      ],
      commonMistakes: [
        'Front heel lifting off the floor.',
        'Leaning excessively forward.',
      ],
      easierVariation: 'Hold wall or rack upright for balance',
      harderVariation: 'Bulgarian Split Squat or Dumbbell Split Squat',
      alternativeExerciseId: 'ex_lunges',
      alternativeExerciseName: 'Walking Lunges',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '10 each leg'),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '10 each leg'),
      ],
    ),
    'ex_leg_curl': const ExerciseDetail(
      id: 'ex_leg_curl',
      name: 'Seated or Lying Leg Curl',
      targetMuscles: 'Hamstrings',
      equipment: 'Machines',
      difficulty: 'Beginner',
      category: 'Isolation',
      instructions: [
        'Align your knee joint with the machine pivot axis and secure the thigh/ankle pad.',
        'Curl heels smoothly toward glutes without lifting hips off the seat.',
        'Control the return back to straight legs over 2 seconds.',
      ],
      commonMistakes: [
        'Jerking hips upward on heavy reps.',
        'Dropping the weight stack quickly on the return.',
      ],
      easierVariation: 'Glute Bridge with heels elevated',
      harderVariation: 'Single-leg eccentric leg curl',
      alternativeExerciseId: 'ex_glute_bridge',
      alternativeExerciseName: 'Glute Bridge',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–12', targetWeightKg: 40),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–12', targetWeightKg: 40),
        SetSpec(setNumber: 3, targetReps: 12, repRangeLabel: '10–12', targetWeightKg: 40),
      ],
    ),
    'ex_calf_raise': const ExerciseDetail(
      id: 'ex_calf_raise',
      name: 'Standing Calf Raises',
      targetMuscles: 'Calves (Gastrocnemius & Soleus)',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Isolation',
      instructions: [
        'Stand with balls of feet on a low step or flat floor near support.',
        'Lower heels slowly for a full stretch, then rise high onto toes for 1 second.',
        'Avoid bouncing through the Achilles tendon.',
      ],
      commonMistakes: [
        'Bouncing fast without pausing at bottom or top.',
        'Bending knees during standing reps.',
      ],
      easierVariation: 'Two-leg calf raises on flat floor',
      harderVariation: 'Single-leg dumbbell calf raise on a step',
      alternativeExerciseId: 'ex_calf_raise',
      alternativeExerciseName: 'Flat-Floor Standing Calf Raises',
      restSeconds: 45,
      sets: [
        SetSpec(setNumber: 1, targetReps: 15, repRangeLabel: '12–15'),
        SetSpec(setNumber: 2, targetReps: 15, repRangeLabel: '12–15'),
        SetSpec(setNumber: 3, targetReps: 15, repRangeLabel: '12–15'),
      ],
    ),

    // --- UPPER BODY PUSH ---
    'ex_chest_press_machine': const ExerciseDetail(
      id: 'ex_chest_press_machine',
      name: 'Chest Press Machine',
      targetMuscles: 'Chest, Front Shoulders & Triceps',
      equipment: 'Machines',
      difficulty: 'Beginner',
      category: 'Machine',
      instructions: [
        'Adjust seat height so handles align roughly with mid-chest level.',
        'Keep shoulder blades resting back against the pad and feet flat.',
        'Press handles forward smoothly without locking elbows hard, then return with control.',
      ],
      commonMistakes: [
        'Setting the seat too low so shoulders roll upward toward ears.',
        'Letting elbows flare straight out at 90 degrees.',
      ],
      easierVariation: 'Wall or Incline Push-ups',
      harderVariation: 'Barbell Bench Press or Dumbbell Bench Press',
      alternativeExerciseId: 'ex_pushup',
      alternativeExerciseName: 'Push-Ups (or Incline Push-Ups)',
      restSeconds: 75,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–12', targetWeightKg: 35),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–12', targetWeightKg: 35),
      ],
    ),
    'ex_bench_press': const ExerciseDetail(
      id: 'ex_bench_press',
      name: 'Barbell Bench Press',
      targetMuscles: 'Chest, Anterior Deltoids & Triceps',
      equipment: 'Barbell & Rack',
      difficulty: 'Intermediate',
      category: 'Compound',
      requiresSupervisionNote: true,
      instructions: [
        'Lie on the bench with eyes directly beneath the barbell and feet planted firmly.',
        'Pull shoulder blades back and down into the bench; grip bar slightly wider than shoulders.',
        'Lower bar smoothly to mid/lower chest with elbows angled ~45° from torso.',
        'Press cleanly back over shoulders until arms extend.',
      ],
      commonMistakes: [
        'Flaring elbows wide to 90 degrees.',
        'Bouncing the bar off the chest or lifting glutes off the bench.',
      ],
      easierVariation: 'Chest Press Machine or Push-ups',
      harderVariation: 'Paused Barbell Bench Press',
      alternativeExerciseId: 'ex_db_incline',
      alternativeExerciseName: 'Incline Dumbbell Press',
      restSeconds: 120,
      coachingCue: 'Use safety pins or a spotter on heavy working sets.',
      sets: [
        SetSpec(setNumber: 1, targetReps: 8, repRangeLabel: '6–8', targetWeightKg: 70),
        SetSpec(setNumber: 2, targetReps: 8, repRangeLabel: '6–8', targetWeightKg: 70),
        SetSpec(setNumber: 3, targetReps: 8, repRangeLabel: '6–8', targetWeightKg: 70),
      ],
    ),
    'ex_db_incline': const ExerciseDetail(
      id: 'ex_db_incline',
      name: 'Incline Dumbbell Press',
      targetMuscles: 'Upper Chest, Front Shoulders & Triceps',
      equipment: 'Dumbbells',
      difficulty: 'Intermediate',
      category: 'Compound',
      instructions: [
        'Set bench to a modest 30° incline.',
        'Press dumbbells up over upper chest with wrists stacked over elbows.',
        'Lower dumbbells slowly until upper arms are just below parallel to the floor.',
      ],
      commonMistakes: [
        'Setting the bench too steep (45°+), turning it primarily into a shoulder press.',
        'Clanging dumbbells forcefully at the top.',
      ],
      easierVariation: 'Incline Push-Ups or Chest Press Machine',
      harderVariation: '3-second eccentric Incline Dumbbell Press',
      alternativeExerciseId: 'ex_pushup',
      alternativeExerciseName: 'Push-Ups (or Floor Dumbbell Press)',
      restSeconds: 90,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '8–10', targetWeightKg: 24),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '8–10', targetWeightKg: 24),
        SetSpec(setNumber: 3, targetReps: 10, repRangeLabel: '8–10', targetWeightKg: 24),
      ],
    ),
    'ex_pushup': const ExerciseDetail(
      id: 'ex_pushup',
      name: 'Push-Ups (Hands Elevated or Floor)',
      targetMuscles: 'Chest, Shoulders, Triceps & Core',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Bodyweight',
      instructions: [
        'Place hands slightly wider than shoulder-width in a straight head-to-heel plank.',
        'Brace core and glutes so hips do not sag.',
        'Lower chest toward floor/bench with elbows angled back ~45°, then press back up.',
      ],
      commonMistakes: [
        'Letting hips drop or poking neck forward toward the floor.',
        'Flaring elbows wide.',
      ],
      easierVariation: 'Hands elevated on a sturdy bench or wall push-ups',
      harderVariation: 'Tempo push-ups (3s lower) or feet-elevated push-ups',
      alternativeExerciseId: 'ex_chest_press_machine',
      alternativeExerciseName: 'Chest Press Machine',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '8–12'),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '8–12'),
        SetSpec(setNumber: 3, targetReps: 10, repRangeLabel: '8–12'),
      ],
    ),
    'ex_ohp': const ExerciseDetail(
      id: 'ex_ohp',
      name: 'Dumbbell or Barbell Overhead Press',
      targetMuscles: 'Shoulders, Upper Chest & Triceps',
      equipment: 'Dumbbells',
      difficulty: 'Intermediate',
      category: 'Compound',
      instructions: [
        'Hold weights at shoulder height with forearms vertical and core/glutes braced.',
        'Press weights smoothly overhead until arms extend near ears without leaning back.',
        'Lower under control back to shoulder level.',
      ],
      commonMistakes: [
        'Overarching the lower back to press heavier weights.',
        'Flaring elbows straight out behind the torso.',
      ],
      easierVariation: 'Seated Dumbbell Shoulder Press with back support',
      harderVariation: 'Standing Barbell Strict Overhead Press',
      alternativeExerciseId: 'ex_lateral_raise',
      alternativeExerciseName: 'Dumbbell Lateral Raises',
      restSeconds: 90,
      sets: [
        SetSpec(setNumber: 1, targetReps: 8, repRangeLabel: '6–10', targetWeightKg: 18),
        SetSpec(setNumber: 2, targetReps: 8, repRangeLabel: '6–10', targetWeightKg: 18),
        SetSpec(setNumber: 3, targetReps: 8, repRangeLabel: '6–10', targetWeightKg: 18),
      ],
    ),
    'ex_lateral_raise': const ExerciseDetail(
      id: 'ex_lateral_raise',
      name: 'Dumbbell Lateral Raises',
      targetMuscles: 'Side Deltoids (Shoulders)',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      category: 'Isolation',
      instructions: [
        'Stand tall holding light dumbbells at your sides with a slight elbow bend.',
        'Raise arms outward in the scapular plane (slightly forward of body) to shoulder height.',
        'Pause briefly and lower over 2 seconds without swinging torso.',
      ],
      commonMistakes: [
        'Using momentum/hip swing with overly heavy dumbbells.',
        'Shrugging traps high toward the neck.',
      ],
      easierVariation: 'Lighter resistance band lateral raises',
      harderVariation: '1.5-rep lateral raises or cable lateral raises',
      alternativeExerciseId: 'ex_band_row',
      alternativeExerciseName: 'Resistance Band Lateral / Rear Delt Raise',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 14, repRangeLabel: '12–15', targetWeightKg: 8),
        SetSpec(setNumber: 2, targetReps: 14, repRangeLabel: '12–15', targetWeightKg: 8),
        SetSpec(setNumber: 3, targetReps: 14, repRangeLabel: '12–15', targetWeightKg: 8),
      ],
    ),
    'ex_triceps_pushdown': const ExerciseDetail(
      id: 'ex_triceps_pushdown',
      name: 'Cable Triceps Pushdown',
      targetMuscles: 'Triceps',
      equipment: 'Cables',
      difficulty: 'Beginner',
      category: 'Isolation',
      instructions: [
        'Attach rope or straight bar at high pulley and tuck elbows close to your ribs.',
        'Press handle downward until arms straighten smoothly without moving upper arms.',
        'Control the handle back up to 90° elbow bend.',
      ],
      commonMistakes: [
        'Letting elbows flare forward and using shoulder momentum.',
        'Leaning chest over the bar.',
      ],
      easierVariation: 'Light band triceps pushdown',
      harderVariation: 'Overhead dumbbell triceps extension',
      alternativeExerciseId: 'ex_db_triceps',
      alternativeExerciseName: 'Dumbbell Overhead Triceps Extension',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–15', targetWeightKg: 20),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–15', targetWeightKg: 20),
      ],
    ),
    'ex_db_triceps': const ExerciseDetail(
      id: 'ex_db_triceps',
      name: 'Dumbbell Overhead Triceps Extension',
      targetMuscles: 'Triceps (Long Head)',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      category: 'Isolation',
      instructions: [
        'Sit or stand tall holding one dumbbell overhead with both hands.',
        'Keep elbows pointing mostly forward and lower the weight smoothly behind your head.',
        'Extend arms smoothly back overhead without flaring elbows wide.',
      ],
      commonMistakes: [
        'Arching lower back excessively.',
        'Dropping weight too quickly at the bottom.',
      ],
      easierVariation: 'Lighter dumbbell or bench triceps dips (bent knees)',
      harderVariation: 'Single-arm overhead dumbbell extension',
      alternativeExerciseId: 'ex_triceps_pushdown',
      alternativeExerciseName: 'Cable Triceps Pushdown',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–15', targetWeightKg: 14),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–15', targetWeightKg: 14),
      ],
    ),

    // --- UPPER BODY PULL ---
    'ex_lat_pulldown': const ExerciseDetail(
      id: 'ex_lat_pulldown',
      name: 'Lat Pulldown',
      targetMuscles: 'Latissimus Dorsi, Upper Back & Biceps',
      equipment: 'Cables',
      difficulty: 'Beginner',
      category: 'Machine',
      instructions: [
        'Secure thighs snugly under the pad and grip the bar slightly wider than shoulders.',
        'Depress shoulder blades first, then pull bar smoothly to your upper collarbone.',
        'Control the bar all the way back up to a gentle overhead stretch.',
      ],
      commonMistakes: [
        'Leaning far back to swing the weight down.',
        'Pulling the bar behind the neck (keep it in front to protect shoulders).',
      ],
      easierVariation: 'Resistance band overhead pulldown',
      harderVariation: 'Assisted or Bodyweight Pull-Ups',
      alternativeExerciseId: 'ex_pullups',
      alternativeExerciseName: 'Pull-Ups (or Band-Assisted Pull-Ups)',
      restSeconds: 75,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '10–12', targetWeightKg: 45),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '10–12', targetWeightKg: 45),
      ],
    ),
    'ex_pullups': const ExerciseDetail(
      id: 'ex_pullups',
      name: 'Pull-Ups (or Assisted Pull-Ups)',
      targetMuscles: 'Lats, Upper Back, Rear Delts & Biceps',
      equipment: 'Pull-up Bar',
      difficulty: 'Intermediate',
      category: 'Compound',
      instructions: [
        'Grip bar slightly outside shoulder-width with palms facing away.',
        'Initiate by pulling shoulder blades down and driving elbows toward your ribs.',
        'Pull chest toward bar until chin clears cleanly, then lower with full control.',
      ],
      commonMistakes: [
        'Kipping or swinging legs aggressively on strict sets.',
        'Stopping half-way down instead of full elbow extension.',
      ],
      easierVariation: 'Lat Pulldown or Band-Assisted Pull-Ups',
      harderVariation: 'Weighted Pull-Ups',
      alternativeExerciseId: 'ex_lat_pulldown',
      alternativeExerciseName: 'Lat Pulldown',
      restSeconds: 90,
      sets: [
        SetSpec(setNumber: 1, targetReps: 9, repRangeLabel: '8–10'),
        SetSpec(setNumber: 2, targetReps: 9, repRangeLabel: '8–10'),
        SetSpec(setNumber: 3, targetReps: 9, repRangeLabel: '8–10'),
      ],
    ),
    'ex_seated_row': const ExerciseDetail(
      id: 'ex_seated_row',
      name: 'Seated Cable Row',
      targetMuscles: 'Mid Back, Rhomboids, Lats & Biceps',
      equipment: 'Cables',
      difficulty: 'Beginner',
      category: 'Machine',
      instructions: [
        'Sit tall with knees slightly bent and feet braced against the footplates.',
        'Pull handles toward your lower ribs while squeezing shoulder blades together.',
        'Extend arms forward smoothly without rounding shoulders into a slump.',
      ],
      commonMistakes: [
        'Rocking torso excessively backward and forward.',
        'Shrugging shoulders up toward ears.',
      ],
      easierVariation: 'Light resistance band seated row',
      harderVariation: 'Chest-Supported Dumbbell Row or Barbell Row',
      alternativeExerciseId: 'ex_db_row',
      alternativeExerciseName: 'One-Arm Dumbbell Row',
      restSeconds: 75,
      sets: [
        SetSpec(setNumber: 1, targetReps: 11, repRangeLabel: '10–12', targetWeightKg: 45),
        SetSpec(setNumber: 2, targetReps: 11, repRangeLabel: '10–12', targetWeightKg: 45),
      ],
    ),
    'ex_db_row': const ExerciseDetail(
      id: 'ex_db_row',
      name: 'One-Arm Dumbbell Row',
      targetMuscles: 'Lats, Rhomboids & Rear Shoulders',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      category: 'Compound',
      instructions: [
        'Brace one hand and knee on a sturdy bench (or split stance) with a flat back.',
        'Pull dumbbell smoothly toward your hip pocket, keeping elbow close to torso.',
        'Lower slowly to full arm extension before next rep.',
      ],
      commonMistakes: [
        'Twisting torso upward aggressively to heave heavy weights.',
        'Pulling dumbbell straight toward shoulder instead of back toward hip.',
      ],
      easierVariation: 'Resistance Band Row',
      harderVariation: 'Pendlay Barbell Row',
      alternativeExerciseId: 'ex_band_row',
      alternativeExerciseName: 'Seated Resistance Band Row',
      restSeconds: 75,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '8–12', targetWeightKg: 22),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '8–12', targetWeightKg: 22),
        SetSpec(setNumber: 3, targetReps: 10, repRangeLabel: '8–12', targetWeightKg: 22),
      ],
    ),
    'ex_band_row': const ExerciseDetail(
      id: 'ex_band_row',
      name: 'Seated Resistance Band Row',
      targetMuscles: 'Mid Back, Lats & Rear Delts',
      equipment: 'Resistance Bands',
      difficulty: 'Beginner',
      category: 'Bodyweight',
      instructions: [
        'Sit on the floor with legs extended and loop resistance band securely around midfoot.',
        'Sit upright and pull band handles back to lower ribs, squeezing shoulder blades.',
        'Return slowly to starting tension.',
      ],
      commonMistakes: [
        'Allowing the band to slip off shoes/feet—wrap cleanly around arches.',
        'Slouching the lower back.',
      ],
      easierVariation: 'Lighter resistance band',
      harderVariation: 'One-Arm Dumbbell Row',
      alternativeExerciseId: 'ex_seated_row',
      alternativeExerciseName: 'Seated Cable Row',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–12'),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–12'),
      ],
    ),
    'ex_db_curl': const ExerciseDetail(
      id: 'ex_db_curl',
      name: 'Dumbbell Biceps Curls',
      targetMuscles: 'Biceps & Forearms',
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
      category: 'Isolation',
      instructions: [
        'Stand tall holding dumbbells at your sides with elbows tucked comfortably.',
        'Curl weights upward by flexing elbows without swinging your torso.',
        'Lower slowly over 2 seconds to full control.',
      ],
      commonMistakes: [
        'Swinging hips forward to launch the dumbbells.',
        'Letting elbows drift behind torso.',
      ],
      easierVariation: 'Alternating curls with lighter dumbbells',
      harderVariation: 'Incline Bench Dumbbell Curls',
      alternativeExerciseId: 'ex_band_row',
      alternativeExerciseName: 'Resistance Band Biceps Curl',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 12, repRangeLabel: '10–15', targetWeightKg: 12),
        SetSpec(setNumber: 2, targetReps: 12, repRangeLabel: '10–15', targetWeightKg: 12),
      ],
    ),

    // --- CORE ---
    'ex_plank': const ExerciseDetail(
      id: 'ex_plank',
      name: 'Forearm Plank',
      targetMuscles: 'Deep Core, Abdominals & Shoulders',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Core',
      instructions: [
        'Rest on forearms with elbows directly under shoulders and toes planted.',
        'Squeeze glutes and draw ribs toward hips to create a straight line from head to heels.',
        'Breathe steadily for the target hold duration without holding breath.',
      ],
      commonMistakes: [
        'Hips sagging toward the floor or piking high into the air.',
        'Looking straight ahead instead of keeping neck neutral.',
      ],
      easierVariation: 'Incline Plank with forearms on a sturdy bench',
      harderVariation: 'Plank with alternating shoulder taps or RKC Plank',
      alternativeExerciseId: 'ex_dead_bug',
      alternativeExerciseName: 'Dead Bug Core Hold',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '15–30 sec', durationSeconds: 25),
        SetSpec(setNumber: 2, targetReps: 0, repRangeLabel: '15–30 sec', durationSeconds: 25),
      ],
    ),
    'ex_dead_bug': const ExerciseDetail(
      id: 'ex_dead_bug',
      name: 'Dead Bug Core Control',
      targetMuscles: 'Deep Core & Pelvic Stability',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Core',
      instructions: [
        'Lie on your back with arms pointing straight up and knees bent at 90 degrees.',
        'Gently press lower back flat against the mat.',
        'Slowly extend opposite arm and leg out without letting lower back arch, then return.',
      ],
      commonMistakes: [
        'Moving too fast and losing lower-back contact with the floor.',
        'Holding your breath.',
      ],
      easierVariation: 'Bent-knee heel taps only',
      harderVariation: 'Straight-leg Dead Bug with light medicine ball press',
      alternativeExerciseId: 'ex_plank',
      alternativeExerciseName: 'Forearm Plank',
      restSeconds: 45,
      sets: [
        SetSpec(setNumber: 1, targetReps: 10, repRangeLabel: '8–10 each side'),
        SetSpec(setNumber: 2, targetReps: 10, repRangeLabel: '8–10 each side'),
      ],
    ),

    // --- POWER / CONDITIONING (HIGH PERFORMANCE & ENDURANCE / FAT LOSS) ---
    'ex_kb_swing': const ExerciseDetail(
      id: 'ex_kb_swing',
      name: 'Kettlebell Hip Swing (Speed & Form)',
      targetMuscles: 'Glutes, Hamstrings, Posterior Power & Core',
      equipment: 'Kettlebells',
      difficulty: 'Intermediate',
      category: 'Power',
      requiresSupervisionNote: true,
      instructions: [
        'Stand slightly wider than shoulder-width with bell about 30cm ahead of feet.',
        'Hike bell back high between thighs like a football snap, keeping spine flat.',
        'Snap hips forward crisply to float bell to chest height; let arms stay relaxed.',
        'Stop the set immediately if crisp hip speed or lumbar posture drops.',
      ],
      commonMistakes: [
        'Squatting the swing instead of hinging at the hips.',
        'Lifting the bell with shoulder muscles rather than hip snap.',
      ],
      easierVariation: 'Dumbbell Romanian Deadlift or Glute Bridge',
      harderVariation: 'Single-Arm Kettlebell Swing',
      alternativeExerciseId: 'ex_db_rdl',
      alternativeExerciseName: 'Dumbbell Romanian Deadlift',
      restSeconds: 90,
      coachingCue: 'Power focus: stop set immediately if speed or crisp form drops.',
      sets: [
        SetSpec(setNumber: 1, targetReps: 8, repRangeLabel: '6–8 crisp reps', targetWeightKg: 16),
        SetSpec(setNumber: 2, targetReps: 8, repRangeLabel: '6–8 crisp reps', targetWeightKg: 16),
        SetSpec(setNumber: 3, targetReps: 8, repRangeLabel: '6–8 crisp reps', targetWeightKg: 16),
      ],
    ),
    'ex_box_jump': const ExerciseDetail(
      id: 'ex_box_jump',
      name: 'Low-Rep Box Jumps (Soft Landing)',
      targetMuscles: 'Lower Body Explosive Power & Coordination',
      equipment: 'Bodyweight',
      difficulty: 'Advanced',
      category: 'Power',
      requiresSupervisionNote: true,
      instructions: [
        'Choose a conservative, stable plyo box height that allows clean, quiet landings.',
        'Swing arms back in a quarter-squat, jump explosively onto box, and land softly with knees bent.',
        'Stand tall cleanly and step down one foot at a time—never jump backwards down.',
      ],
      commonMistakes: [
        'High-rep fatigue jumping, which increases ankle/shin strain.',
        'Jumping off the box backwards instead of stepping down.',
      ],
      easierVariation: 'Broad jump to soft landing or Squat Jump onto flat ground',
      harderVariation: 'Seated-start Box Jump (no countermovement)',
      alternativeExerciseId: 'ex_bw_squat',
      alternativeExerciseName: 'Fast-Concentric Bodyweight Squat',
      restSeconds: 120,
      coachingCue: 'Keep reps low (3–5); terminate set early if landing becomes heavy or sloppy.',
      sets: [
        SetSpec(setNumber: 1, targetReps: 4, repRangeLabel: '3–5 crisp reps'),
        SetSpec(setNumber: 2, targetReps: 4, repRangeLabel: '3–5 crisp reps'),
        SetSpec(setNumber: 3, targetReps: 4, repRangeLabel: '3–5 crisp reps'),
      ],
    ),
    'ex_conditioning_intervals': const ExerciseDetail(
      id: 'ex_conditioning_intervals',
      name: 'Zone 2–4 Cardio Conditioning Intervals',
      targetMuscles: 'Aerobic Capacity, Work Recovery & Heart Health',
      equipment: 'Cardio Machines',
      difficulty: 'Beginner',
      category: 'Cardio',
      instructions: [
        'Complete 4 minutes of steady easy pace on rower, bike, or treadmill.',
        'Perform alternating 60 seconds brisk effort (RPE 7/10) with 90 seconds easy recovery.',
        'Maintain smooth cadence and avoid all-out exhaustion.',
      ],
      commonMistakes: [
        'Going at maximum sprint intensity on every interval and burning out early.',
        'Skipping the 90-second easy recovery intervals.',
      ],
      easierVariation: 'Steady Zone 2 continuous brisk walk or spin (15–20 min)',
      harderVariation: 'Gradually add 1–2 extra work intervals over several weeks',
      alternativeExerciseId: 'ex_steady_walk',
      alternativeExerciseName: 'Outdoor Brisk Walk / Jog Intervals',
      restSeconds: 60,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '15–20 min', durationSeconds: 1080),
      ],
    ),
    'ex_steady_walk': const ExerciseDetail(
      id: 'ex_steady_walk',
      name: 'Steady Aerobic Walk or Bodyweight Flow',
      targetMuscles: 'Aerobic Base & Active Recovery',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
      category: 'Cardio',
      instructions: [
        'Walk briskly outdoors or cycle at a conversational pace (can speak in short sentences).',
        'Focus on rhythmic breathing and relaxed posture.',
      ],
      commonMistakes: [
        'Turning easy recovery cardio into a maximal sprint.',
      ],
      easierVariation: '12–15 minutes gentle stroll',
      harderVariation: '25–35 minutes steady Zone 2 pace',
      alternativeExerciseId: 'ex_conditioning_intervals',
      alternativeExerciseName: 'Zone 2–4 Cardio Conditioning Intervals',
      restSeconds: 0,
      sets: [
        SetSpec(setNumber: 1, targetReps: 0, repRangeLabel: '20 min', durationSeconds: 1200),
      ],
    ),
  };

  /// Retrieve an exercise by ID safely.
  static ExerciseDetail? getExerciseById(String id) => exerciseLibrary[id];

  /// List all exercises in library sorted alphabetically.
  static List<ExerciseDetail> get allExercises {
    final list = exerciseLibrary.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Find compatible alternative exercises for an exercise given profile equipment & avoided items.
  static List<ExerciseDetail> findAlternatives(
    ExerciseDetail exercise, {
    FitnessProfile? profile,
  }) {
    bool isCompatible(ExerciseDetail candidate) {
      if (candidate.id == exercise.id) return false;
      if (profile != null) {
        final avoided = profile.avoidExercises.any(
          (a) => candidate.name.toLowerCase().contains(a.toLowerCase()),
        );
        if (avoided) return false;
        if (!_hasEquipment(candidate, profile)) return false;
      }
      return true;
    }

    final results = <ExerciseDetail>[];
    if (exercise.alternativeExerciseId != null &&
        exerciseLibrary.containsKey(exercise.alternativeExerciseId)) {
      final primaryAlt = exerciseLibrary[exercise.alternativeExerciseId!]!;
      if (isCompatible(primaryAlt)) {
        results.add(primaryAlt);
      }
    }
    for (final candidate in exerciseLibrary.values) {
      if (results.any((r) => r.id == candidate.id)) continue;
      if (!isCompatible(candidate)) continue;
      final sameCategory = candidate.category == exercise.category ||
          candidate.targetMuscles.split(',').first.trim().toLowerCase() ==
              exercise.targetMuscles.split(',').first.trim().toLowerCase();
      if (!sameCategory) continue;
      results.add(candidate);
      if (results.length >= 4) break;
    }
    // Second pass: if category match yielded nothing compatible with home equipment,
    // allow any compatible strength/bodyweight exercise.
    if (results.isEmpty && profile != null) {
      for (final candidate in exerciseLibrary.values) {
        if (!isCompatible(candidate)) continue;
        if (candidate.category == 'Mobility') continue;
        results.add(candidate);
        if (results.length >= 3) break;
      }
    }
    return results;
  }

  /// Pick the best exercise matching equipment, location, and avoided preferences.
  static ExerciseDetail _pickExercise(
    String preferredId,
    FitnessProfile profile, {
    int? customSets,
    String? customRepRange,
    int? customReps,
    int? customRestSeconds,
    int? customDurationSeconds,
  }) {
    var chosen = exerciseLibrary[preferredId]!;

    final avoidsPreferred = profile.avoidExercises.any(
      (avoid) => chosen.name.toLowerCase().contains(avoid.toLowerCase()),
    );
    final equipmentAvailable = _hasEquipment(chosen, profile);

    if (avoidsPreferred || !equipmentAvailable) {
      // Try explicit alternative first
      if (chosen.alternativeExerciseId != null &&
          exerciseLibrary.containsKey(chosen.alternativeExerciseId)) {
        final alt = exerciseLibrary[chosen.alternativeExerciseId!]!;
        final avoidsAlt = profile.avoidExercises.any(
          (a) => alt.name.toLowerCase().contains(a.toLowerCase()),
        );
        if (!avoidsAlt && _hasEquipment(alt, profile)) {
          chosen = alt;
        } else {
          final fallback = findAlternatives(chosen, profile: profile);
          if (fallback.isNotEmpty) {
            chosen = fallback.first;
          }
        }
      } else {
        final fallback = findAlternatives(chosen, profile: profile);
        if (fallback.isNotEmpty) {
          chosen = fallback.first;
        }
      }
    }

    // Adapt sets/reps/rest to requested specification or goal
    final baseSets = chosen.sets;
    final count = customSets ?? baseSets.length;
    final adaptedSets = List<SetSpec>.generate(count, (i) {
      final template = i < baseSets.length ? baseSets[i] : baseSets.last;
      return template.copyWith(
        setNumber: i + 1,
        targetReps: customReps ?? template.targetReps,
        repRangeLabel: customRepRange ?? template.repRangeLabel,
        durationSeconds: customDurationSeconds ?? template.durationSeconds,
      );
    });

    return chosen.copyWith(
      sets: adaptedSets,
      restSeconds: customRestSeconds ?? chosen.restSeconds,
    );
  }

  static bool _hasEquipment(ExerciseDetail ex, FitnessProfile profile) {
    if (ex.equipment == 'Bodyweight') return true;
    if (profile.availableEquipment.contains(ex.equipment)) return true;
    // Gym members generally have gym equipment unless explicitly deselected
    if (profile.workoutLocation == 'Gym' && profile.availableEquipment.isEmpty) {
      return true;
    }
    return false;
  }

  /// Generates a complete personalized 7-day [WorkoutPlan] tailored to level,
  /// primary goal, training days/week, duration, equipment, and safety notes.
  static WorkoutPlan generatePlan(FitnessProfile profile) {
    final level = profile.fitnessLevel;
    final goal = profile.primaryGoal;
    final days = profile.trainingDaysPerWeek.clamp(2, 6);

    if (level == 'Beginner') {
      return _buildBeginnerPlan(profile, goal, days);
    } else if (level == 'High-Performance') {
      return _buildHighPerformancePlan(profile, goal, days);
    } else {
      return _buildAdvancedPlan(profile, goal, days);
    }
  }

  static WorkoutPlan _buildBeginnerPlan(
    FitnessProfile profile,
    String goal,
    int requestedDays,
  ) {
    // Beginners safely train 2–3 full-body days with rest days between sessions
    final trainingDays = requestedDays > 3 ? 3 : requestedDays;
    final restSec = goal == 'Strength' ? 90 : 75;
    final warmup = _pickExercise(
      profile.workoutLocation == 'Home' ? 'wu_marching' : 'wu_treadmill',
      profile,
    );
    final cooldown = _pickExercise('cd_stretch', profile);

    final fullBodyA = WorkoutSession(
      id: 'SES-BEG-A',
      title: 'Full-Body Foundation A',
      focus: 'Full Body Technique & Consistency',
      estimatedMinutes: profile.workoutDurationMinutes.clamp(30, 60),
      level: 'Beginner',
      goal: goal,
      warmUp: [warmup],
      mainExercises: [
        _pickExercise(
          profile.workoutLocation == 'Home' ? 'ex_bw_squat' : 'ex_leg_press',
          profile,
          customSets: 2,
          customReps: 12,
          customRepRange: '10–12',
          customRestSeconds: restSec,
        ),
        _pickExercise(
          'ex_chest_press_machine',
          profile,
          customSets: 2,
          customReps: 12,
          customRepRange: '10–12',
          customRestSeconds: restSec,
        ),
        _pickExercise(
          'ex_lat_pulldown',
          profile,
          customSets: 2,
          customReps: 12,
          customRepRange: '10–12',
          customRestSeconds: restSec,
        ),
        _pickExercise(
          'ex_seated_row',
          profile,
          customSets: 2,
          customReps: 12,
          customRepRange: '10–12',
          customRestSeconds: restSec,
        ),
        _pickExercise(
          'ex_glute_bridge',
          profile,
          customSets: 2,
          customReps: 12,
          customRepRange: '12',
          customRestSeconds: 60,
        ),
        _pickExercise(
          'ex_plank',
          profile,
          customSets: 2,
          customRepRange: '15–30 sec',
          customDurationSeconds: 25,
          customRestSeconds: 60,
        ),
      ],
      coolDown: [cooldown],
      coachingNotes:
          'Focus on smooth form and controlled tempo. Stop 2–3 reps before failure—do not push heavy weights while learning movement patterns.',
      recoveryGuidance:
          'Take at least 1 rest day between full-body sessions. Prioritize hydration and 7–9 hours of sleep.',
    );

    final fullBodyB = WorkoutSession(
      id: 'SES-BEG-B',
      title: goal == 'Endurance' || goal == 'Fat Loss'
          ? 'Full-Body & Aerobic Conditioning B'
          : 'Full-Body Foundation B',
      focus: goal == 'Endurance' ? 'Strength & Aerobic Base' : 'Full Body Balanced Movement',
      estimatedMinutes: profile.workoutDurationMinutes.clamp(30, 60),
      level: 'Beginner',
      goal: goal,
      warmUp: [warmup],
      mainExercises: [
        _pickExercise(
          'ex_bw_squat',
          profile,
          customSets: 2,
          customReps: 12,
          customRepRange: '10–12',
          customRestSeconds: restSec,
        ),
        _pickExercise(
          'ex_pushup',
          profile,
          customSets: 2,
          customReps: 10,
          customRepRange: '8–12',
          customRestSeconds: restSec,
        ),
        _pickExercise(
          'ex_db_row',
          profile,
          customSets: 2,
          customReps: 12,
          customRepRange: '10–12',
          customRestSeconds: restSec,
        ),
        _pickExercise(
          'ex_db_rdl',
          profile,
          customSets: 2,
          customReps: 10,
          customRepRange: '10',
          customRestSeconds: restSec,
        ),
        if (goal == 'Fat Loss' || goal == 'Endurance')
          _pickExercise('ex_steady_walk', profile)
        else
          _pickExercise('ex_dead_bug', profile),
      ],
      coolDown: [cooldown],
      coachingNotes:
          'Use manageable resistance that lets you complete every rep cleanly. Machine and bodyweight options are equally effective here.',
      recoveryGuidance:
          'Rest days help connective tissues adapt. Light walking or gentle stretching on off days is encouraged.',
    );

    final activeDaysMap = trainingDays == 2 ? {1: fullBodyA, 4: fullBodyB} : {1: fullBodyA, 3: fullBodyB, 5: fullBodyA.copyWith(id: 'SES-BEG-C', title: 'Full-Body Consistency C')};
    final sessions = activeDaysMap.values.toList();

    final weekSchedule = _mapWeekDays(activeDaysMap);

    return WorkoutPlan(
      id: 'PLAN-BEG-${profile.memberId}',
      memberId: profile.memberId,
      title: 'Beginner $goal Foundation ($trainingDays-Day Full Body)',
      splitSummary: '$trainingDays Full-Body Sessions / Week • Form & Consistency Focus',
      goal: goal,
      level: 'Beginner',
      location: profile.workoutLocation,
      trainingDaysPerWeek: trainingDays,
      createdAt: DateTime.now(),
      weekSchedule: weekSchedule,
      sessions: sessions,
      progressionGuidance:
          'Master smooth technique for 2+ sessions at the top of your rep range before adding 1–2 reps or a small load step.',
      recoveryGuidance:
          'Never train through sharp pain. Include 60–90 seconds rest between sets and at least one full rest day between sessions.',
      isSampleData: profile.isSampleData,
    );
  }

  static WorkoutPlan _buildAdvancedPlan(
    FitnessProfile profile,
    String goal,
    int requestedDays,
  ) {
    final trainingDays = requestedDays.clamp(3, 5);
    final compoundRest = goal == 'Strength' ? 150 : 105;
    final accessoryRest = 60;
    final compoundRepRange = goal == 'Strength' ? '4–6' : (goal == 'Endurance' ? '10–12' : '6–8');
    final compoundReps = goal == 'Strength' ? 5 : (goal == 'Endurance' ? 12 : 8);

    final wuUpper = _pickExercise('wu_mobility_upper', profile);
    final wuLower = _pickExercise('wu_mobility_lower', profile);
    final cdStretch = _pickExercise('cd_stretch', profile);

    final upperA = WorkoutSession(
      id: 'SES-ADV-U1',
      title: 'Upper Body Strength & Hypertrophy',
      focus: 'Chest, Back, Shoulders & Arms',
      estimatedMinutes: profile.workoutDurationMinutes,
      level: 'Advanced',
      goal: goal,
      warmUp: [wuUpper],
      mainExercises: [
        _pickExercise('ex_bench_press', profile, customSets: 3, customReps: compoundReps, customRepRange: compoundRepRange, customRestSeconds: compoundRest),
        _pickExercise('ex_pullups', profile, customSets: 3, customReps: 9, customRepRange: '8–10', customRestSeconds: 90),
        _pickExercise('ex_db_incline', profile, customSets: 3, customReps: 9, customRepRange: '8–10', customRestSeconds: 90),
        _pickExercise('ex_seated_row', profile, customSets: 3, customReps: 10, customRepRange: '8–12', customRestSeconds: 75),
        _pickExercise('ex_lateral_raise', profile, customSets: 3, customReps: 14, customRepRange: '12–15', customRestSeconds: accessoryRest),
        _pickExercise('ex_triceps_pushdown', profile, customSets: 2, customReps: 12, customRepRange: '10–15', customRestSeconds: accessoryRest),
        _pickExercise('ex_db_curl', profile, customSets: 2, customReps: 12, customRepRange: '10–15', customRestSeconds: accessoryRest),
      ],
      coolDown: [cdStretch],
      coachingNotes:
          'Longer rest (90–150s) on barbell/compound lifts; shorter rest (60s) on isolation work. Track weights and reps each set.',
      recoveryGuidance: 'Aim for 1–2 reps in reserve on compound sets to manage systemic fatigue.',
    );

    final lowerA = WorkoutSession(
      id: 'SES-ADV-L1',
      title: 'Lower Body Power & Posterior Chain',
      focus: 'Quads, Hamstrings, Glutes & Core',
      estimatedMinutes: profile.workoutDurationMinutes,
      level: 'Advanced',
      goal: goal,
      warmUp: [wuLower],
      mainExercises: [
        _pickExercise('ex_barbell_squat', profile, customSets: 3, customReps: compoundReps, customRepRange: goal == 'Strength' ? '4–6' : '6–10', customRestSeconds: compoundRest),
        _pickExercise('ex_rdl', profile, customSets: 3, customReps: 9, customRepRange: '8–10', customRestSeconds: 105),
        _pickExercise('ex_lunges', profile, customSets: 3, customReps: 10, customRepRange: '10 each leg', customRestSeconds: 75),
        _pickExercise('ex_leg_curl', profile, customSets: 3, customReps: 11, customRepRange: '10–12', customRestSeconds: accessoryRest),
        _pickExercise('ex_calf_raise', profile, customSets: 3, customReps: 14, customRepRange: '12–15', customRestSeconds: 45),
        _pickExercise('ex_plank', profile, customSets: 3, customRepRange: '30–45 sec', customDurationSeconds: 40, customRestSeconds: 60),
      ],
      coolDown: [cdStretch],
      coachingNotes: 'Prioritize bracing and full depth on squats and hip hinge control on Romanian deadlifts.',
      recoveryGuidance: 'Follow lower-body training with a recovery or rest day when scheduled.',
    );

    final upperB = WorkoutSession(
      id: 'SES-ADV-U2',
      title: 'Upper Body Volume & Variations',
      focus: 'Incline Press, Rows, Overhead & Arms',
      estimatedMinutes: profile.workoutDurationMinutes,
      level: 'Advanced',
      goal: goal,
      warmUp: [wuUpper],
      mainExercises: [
        _pickExercise('ex_db_incline', profile, customSets: 3, customReps: 9, customRepRange: '8–10', customRestSeconds: 90),
        _pickExercise('ex_db_row', profile, customSets: 3, customReps: 10, customRepRange: '8–12', customRestSeconds: 90),
        _pickExercise('ex_ohp', profile, customSets: 3, customReps: 8, customRepRange: '6–10', customRestSeconds: 105),
        _pickExercise('ex_lat_pulldown', profile, customSets: 3, customReps: 10, customRepRange: '8–12', customRestSeconds: 75),
        _pickExercise('ex_lateral_raise', profile, customSets: 3, customReps: 14, customRepRange: '12–15', customRestSeconds: accessoryRest),
        _pickExercise('ex_db_triceps', profile, customSets: 2, customReps: 12, customRepRange: '10–15', customRestSeconds: accessoryRest),
        _pickExercise('ex_db_curl', profile, customSets: 2, customReps: 12, customRepRange: '10–15', customRestSeconds: accessoryRest),
      ],
      coolDown: [cdStretch],
      coachingNotes: 'Upper variation day balances pressing angles and unilateral back stability.',
    );

    final lowerB = WorkoutSession(
      id: 'SES-ADV-L2',
      title: goal == 'Fat Loss' || goal == 'Endurance'
          ? 'Lower Body & Conditioning Mix'
          : 'Lower Body Variations & Core',
      focus: 'Single-Leg Strength, Hamstrings & Conditioning',
      estimatedMinutes: profile.workoutDurationMinutes,
      level: 'Advanced',
      goal: goal,
      warmUp: [wuLower],
      mainExercises: [
        _pickExercise('ex_goblet_squat', profile, customSets: 3, customReps: 10, customRepRange: '8–12', customRestSeconds: 90),
        _pickExercise('ex_db_rdl', profile, customSets: 3, customReps: 10, customRepRange: '8–10', customRestSeconds: 90),
        _pickExercise('ex_split_squat', profile, customSets: 3, customReps: 10, customRepRange: '10 each leg', customRestSeconds: 75),
        _pickExercise('ex_glute_bridge', profile, customSets: 3, customReps: 12, customRepRange: '12–15', customRestSeconds: 60),
        if (goal == 'Fat Loss' || goal == 'Endurance')
          _pickExercise('ex_conditioning_intervals', profile)
        else
          _pickExercise('ex_dead_bug', profile, customSets: 3),
      ],
      coolDown: [cdStretch],
      coachingNotes: goal == 'Fat Loss'
          ? 'Preserves leg strength while adding sustainable cardio intervals without excessive daily fatigue.'
          : 'Unilateral leg work evens out left-right imbalances.',
    );

    final Map<int, WorkoutSession> activeDaysMap;
    if (trainingDays <= 3) {
      activeDaysMap = {1: upperA, 3: lowerA, 5: upperB};
    } else if (trainingDays == 4) {
      activeDaysMap = {1: upperA, 2: lowerA, 4: upperB, 5: lowerB};
    } else {
      final conditioningDay = WorkoutSession(
        id: 'SES-ADV-C5',
        title: goal == 'Endurance' ? 'Aerobic Tempo & Core' : 'Conditioning, Mobility & Weak Points',
        focus: 'Cardiovascular Endurance & Core Stability',
        estimatedMinutes: profile.workoutDurationMinutes.clamp(30, 55),
        level: 'Advanced',
        goal: goal,
        warmUp: [_pickExercise('wu_marching', profile)],
        mainExercises: [
          _pickExercise('ex_conditioning_intervals', profile),
          _pickExercise('ex_plank', profile, customSets: 3, customDurationSeconds: 40, customRepRange: '30–45 sec'),
          _pickExercise('ex_dead_bug', profile),
        ],
        coolDown: [cdStretch],
        coachingNotes: 'Keep conditioning sustainable—avoid excessive exhaustion so primary lifting days stay sharp.',
      );
      activeDaysMap = {1: upperA, 2: lowerA, 3: conditioningDay, 4: upperB, 5: lowerB};
    }

    return WorkoutPlan(
      id: 'PLAN-ADV-${profile.memberId}',
      memberId: profile.memberId,
      title: 'Advanced $goal ($trainingDays-Day Upper/Lower Split)',
      splitSummary: '$trainingDays Structured Days / Week • Volume & Progressive Overload',
      goal: goal,
      level: 'Advanced',
      location: profile.workoutLocation,
      trainingDaysPerWeek: trainingDays,
      createdAt: DateTime.now(),
      weekSchedule: _mapWeekDays(activeDaysMap),
      sessions: activeDaysMap.values.toList(),
      progressionGuidance:
          'Increase load by ~2.5 kg or add 1–2 reps only after hitting top rep targets cleanly across 2 consecutive sessions.',
      recoveryGuidance:
          'Schedule rest or light recovery activity on off days (e.g. Wednesday & weekend). Consider a lighter deload week every 4–6 weeks.',
      isSampleData: profile.isSampleData,
    );
  }

  static WorkoutPlan _buildHighPerformancePlan(
    FitnessProfile profile,
    String goal,
    int requestedDays,
  ) {
    final trainingDays = requestedDays.clamp(4, 5);
    final wuLower = _pickExercise('wu_mobility_lower', profile);
    final wuUpper = _pickExercise('wu_mobility_upper', profile);
    final cdBreath = _pickExercise('cd_breathing', profile);

    final day1Lower = WorkoutSession(
      id: 'SES-HP-D1',
      title: 'Lower-Body Strength Block',
      focus: 'Maximal Controlled Strength & Posterior Chain',
      estimatedMinutes: profile.workoutDurationMinutes,
      level: 'High-Performance',
      goal: goal,
      warmUp: [wuLower],
      mainExercises: [
        _pickExercise('ex_barbell_squat', profile, customSets: 4, customReps: 5, customRepRange: '4–6', customRestSeconds: 150),
        _pickExercise('ex_rdl', profile, customSets: 3, customReps: 6, customRepRange: '6–8', customRestSeconds: 120),
        _pickExercise('ex_lunges', profile, customSets: 3, customReps: 8, customRepRange: '8 each leg', customRestSeconds: 90),
        _pickExercise('ex_leg_curl', profile, customSets: 3, customReps: 10, customRepRange: '8–12', customRestSeconds: 75),
        _pickExercise('ex_plank', profile, customSets: 3, customDurationSeconds: 45, customRepRange: '40–45 sec'),
      ],
      coolDown: [cdBreath],
      coachingNotes: 'Heavy compound lifts benefit from spotters/safety arms and disciplined bar speed—avoid grinding through poor technique.',
    );

    final day2Upper = WorkoutSession(
      id: 'SES-HP-D2',
      title: 'Upper-Body Strength Block',
      focus: 'Horizontal & Vertical Push/Pull Strength',
      estimatedMinutes: profile.workoutDurationMinutes,
      level: 'High-Performance',
      goal: goal,
      warmUp: [wuUpper],
      mainExercises: [
        _pickExercise('ex_bench_press', profile, customSets: 4, customReps: 6, customRepRange: '5–6', customRestSeconds: 150),
        _pickExercise('ex_pullups', profile, customSets: 4, customReps: 8, customRepRange: '6–10', customRestSeconds: 120),
        _pickExercise('ex_ohp', profile, customSets: 3, customReps: 6, customRepRange: '6–8', customRestSeconds: 120),
        _pickExercise('ex_seated_row', profile, customSets: 3, customReps: 10, customRepRange: '8–10', customRestSeconds: 90),
        _pickExercise('ex_lateral_raise', profile, customSets: 3, customReps: 12, customRepRange: '12–15', customRestSeconds: 60),
      ],
      coolDown: [cdBreath],
      coachingNotes: 'Keep 1–2 reps in reserve on primary sets. Supervision recommended for near-maximal barbell lifts.',
    );

    final day3CondMob = WorkoutSession(
      id: 'SES-HP-D3',
      title: 'Conditioning & Mobility Block',
      focus: 'Aerobic Output, Joint Range & Tissue Recovery',
      estimatedMinutes: profile.workoutDurationMinutes.clamp(35, 60),
      level: 'High-Performance',
      goal: goal,
      warmUp: [_pickExercise('wu_marching', profile)],
      mainExercises: [
        _pickExercise('ex_conditioning_intervals', profile),
        _pickExercise('ex_dead_bug', profile, customSets: 3),
        _pickExercise('wu_mobility_lower', profile),
      ],
      coolDown: [cdBreath],
      coachingNotes: 'Supports work capacity between heavy training days without turning into max-effort exhaustion.',
    );

    final day4Power = WorkoutSession(
      id: 'SES-HP-D4',
      title: 'Power & Athletic Training',
      focus: 'Low-Rep Speed, Hip Power & Crisp Technique',
      estimatedMinutes: profile.workoutDurationMinutes.clamp(40, 65),
      level: 'High-Performance',
      goal: goal,
      warmUp: [wuLower],
      mainExercises: [
        _pickExercise('ex_box_jump', profile),
        _pickExercise('ex_kb_swing', profile),
        _pickExercise('ex_db_incline', profile, customSets: 3, customReps: 6, customRepRange: '6–8', customRestSeconds: 90),
        _pickExercise('ex_db_row', profile, customSets: 3, customReps: 8, customRepRange: '8–10', customRestSeconds: 90),
      ],
      coolDown: [cdBreath],
      coachingNotes: 'Power rule: Keep reps low with full rest (90–120s). Stop explosive exercises immediately if speed or landing form decreases.',
    );

    final day5Full = WorkoutSession(
      id: 'SES-HP-D5',
      title: 'Full-Body Athletic Strength',
      focus: 'Integrated Full-Body Stability & Hypertrophy',
      estimatedMinutes: profile.workoutDurationMinutes,
      level: 'High-Performance',
      goal: goal,
      warmUp: [wuUpper],
      mainExercises: [
        _pickExercise('ex_goblet_squat', profile, customSets: 3, customReps: 8, customRepRange: '8–10', customRestSeconds: 90),
        _pickExercise('ex_db_rdl', profile, customSets: 3, customReps: 8, customRepRange: '8–10', customRestSeconds: 90),
        _pickExercise('ex_pushup', profile, customSets: 3, customReps: 12, customRepRange: '10–15', customRestSeconds: 60),
        _pickExercise('ex_lat_pulldown', profile, customSets: 3, customReps: 10, customRepRange: '8–12', customRestSeconds: 75),
        _pickExercise('ex_calf_raise', profile, customSets: 3),
      ],
      coolDown: [cdBreath],
      coachingNotes: 'Finish the week with clean movement quality—never push into joint pain or cumulative exhaustion.',
    );

    final Map<int, WorkoutSession> activeDaysMap = trainingDays == 4
        ? {1: day1Lower, 2: day2Upper, 3: day3CondMob, 5: day4Power}
        : {1: day1Lower, 2: day2Upper, 3: day3CondMob, 4: day4Power, 5: day5Full};

    return WorkoutPlan(
      id: 'PLAN-HP-${profile.memberId}',
      memberId: profile.memberId,
      title: 'High-Performance $goal ($trainingDays-Day Structured Block)',
      splitSummary: 'Strength, Power, Conditioning & Mobility • Planned Deloads',
      goal: goal,
      level: 'High-Performance',
      location: profile.workoutLocation,
      trainingDaysPerWeek: trainingDays,
      createdAt: DateTime.now(),
      weekSchedule: _mapWeekDays(activeDaysMap),
      sessions: activeDaysMap.values.toList(),
      progressionGuidance:
          'Progress gradually across 4-week training blocks. Stop explosive power sets when velocity drops; schedule lighter recovery weeks periodically.',
      recoveryGuidance:
          'Avoid repeated max-effort sessions or training through pain. Days 6–7 are reserved for full rest or light recovery activity.',
      isSampleData: profile.isSampleData,
    );
  }

  static List<WorkoutPlanDay> _mapWeekDays(Map<int, WorkoutSession> activeDays) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return List.generate(7, (index) {
      final weekday = index + 1;
      final session = activeDays[weekday];
      if (session == null) {
        return WorkoutPlanDay(
          weekdayIndex: weekday,
          dayName: names[index],
          isRestDay: true,
          sessionLabel: weekday == 7 ? 'Full Rest & Recovery' : 'Rest or Light Activity',
          focusSummary: 'Gentle walking, mobility, sleep & hydration',
          estimatedMinutes: 0,
        );
      }
      return WorkoutPlanDay(
        weekdayIndex: weekday,
        dayName: names[index],
        isRestDay: false,
        sessionLabel: session.title,
        focusSummary: session.focus,
        sessionId: session.id,
        estimatedMinutes: session.estimatedMinutes,
      );
    });
  }

  /// Safe progression system:
  /// - NEVER increases load based on only one completed workout.
  /// - Requires >= 2 logged sessions for an exercise where prescribed sets were completed
  ///   and the member did not stop due to pain or excessive RPE (>= 9).
  static List<ProgressionSuggestion> evaluateProgressions(
    List<WorkoutLog> logs,
    WorkoutPlan? plan,
  ) {
    if (logs.isEmpty) return const [];

    final completedLogs = logs.where((l) => l.isCompleted && !l.stoppedDueToDiscomfort).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    // Group exercise logs chronologically (newest first) by exerciseId
    final Map<String, List<_ExerciseSessionRecord>> historyByEx = {};
    for (final wLog in completedLogs) {
      for (final exLog in wLog.exerciseLogs) {
        if (exLog.skipped || exLog.completedSetsCount == 0) continue;
        historyByEx.putIfAbsent(exLog.exerciseId, () => []).add(
              _ExerciseSessionRecord(
                exerciseLog: exLog,
                rpe: wLog.perceivedDifficulty,
              ),
            );
      }
    }

    final suggestions = <ProgressionSuggestion>[];
    for (final entry in historyByEx.entries) {
      final records = entry.value;
      final latest = records.first.exerciseLog;
      final topWeight = latest.topWeightKg;

      // Require at least 2 clean sessions before suggesting a load bump
      if (records.length < 2) {
        suggestions.add(
          ProgressionSuggestion(
            exerciseId: entry.key,
            exerciseName: latest.exerciseName,
            currentWeightKg: topWeight,
            suggestedWeightKg: topWeight,
            readyToProgress: false,
            recommendation: 'Maintain current load & build consistency',
            rationale:
                'Completed 1 logged session. Complete at least 2 clean sessions with solid form before increasing load.',
          ),
        );
        continue;
      }

      final recentTwo = records.take(2).toList();
      final bothFullyCompleted = recentTwo.every((r) => r.exerciseLog.isFullyCompleted);
      final manageableEffort = recentTwo.every((r) => r.rpe <= 8);

      if (bothFullyCompleted && manageableEffort) {
        if (topWeight != null && topWeight > 0) {
          final increment = topWeight >= 60 ? 2.5 : 2.0;
          final nextWeight = topWeight + increment;
          suggestions.add(
            ProgressionSuggestion(
              exerciseId: entry.key,
              exerciseName: latest.exerciseName,
              currentWeightKg: topWeight,
              suggestedWeightKg: nextWeight,
              readyToProgress: true,
              recommendation:
                  'Try +$increment kg (${nextWeight.toStringAsFixed(1)} kg) if form stays crisp',
              rationale:
                  'Completed all prescribed sets across ${records.length} sessions at controlled effort (RPE ≤ 8).',
            ),
          );
        } else {
          suggestions.add(
            ProgressionSuggestion(
              exerciseId: entry.key,
              exerciseName: latest.exerciseName,
              readyToProgress: true,
              recommendation: 'Add 1–2 reps per set or slow eccentric tempo',
              rationale:
                  'Completed bodyweight/timed sets cleanly across your last 2 sessions.',
            ),
          );
        }
      } else {
        suggestions.add(
          ProgressionSuggestion(
            exerciseId: entry.key,
            exerciseName: latest.exerciseName,
            currentWeightKg: topWeight,
            suggestedWeightKg: topWeight,
            readyToProgress: false,
            recommendation: 'Keep current weight and focus on rep quality',
            rationale:
                'Recent effort was high or partial sets were completed—stabilize current load before progressing.',
          ),
        );
      }
    }

    return suggestions;
  }
}

class _ExerciseSessionRecord {
  final ExerciseLog exerciseLog;
  final int rpe;
  const _ExerciseSessionRecord({required this.exerciseLog, required this.rpe});
}
