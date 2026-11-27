-- FitPulse Gym Management — Initial Relational PostgreSQL Schema
-- Safe to run on an empty or existing database (uses IF NOT EXISTS and idempotent DO blocks).

-- Required extension for gen_random_uuid()
create extension if not exists pgcrypto with schema extensions;

-- Non-exposed schema for internal RLS security helpers
create schema if not exists private;
revoke all on schema private from public, anon;

-- Shared updated_at trigger function
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================================
-- A. profiles (linked 1:1 to auth.users)
-- ============================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  member_code text unique,
  full_name text not null,
  email text not null unique,
  phone text,
  profile_image text,
  date_of_birth date,
  gender text,
  height numeric(5, 2) check (height is null or (height >= 50 and height <= 280)),
  weight numeric(5, 2) check (weight is null or (weight >= 20 and weight <= 350)),
  emergency_contact text,
  role text not null default 'member' check (role in ('member', 'trainer', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_email on public.profiles (email);
create index if not exists idx_profiles_role on public.profiles (role);

-- Prevent non-admin users from escalating their own role via direct UPDATE
create or replace function private.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role then
    -- Allow service/postgres migrations or existing admin
    if (select auth.uid()) is not null and not exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.role = 'admin'
    ) then
      raise exception 'Only an administrator can modify account roles.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

drop trigger if exists trg_prevent_profile_role_escalation on public.profiles;
create trigger trg_prevent_profile_role_escalation
  before update on public.profiles
  for each row execute function private.prevent_profile_role_escalation();

-- Automatically create profile on new auth.users signup (never trusts client role)
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  generated_code text;
begin
  generated_code := 'GM-' || upper(substr(replace(new.id::text, '-', ''), 1, 6));
  insert into public.profiles (
    id,
    member_code,
    full_name,
    email,
    phone,
    role
  )
  values (
    new.id,
    generated_code,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(coalesce(new.email, 'member'), '@', 1)),
    coalesce(new.email, ''),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    'member'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- ============================================================================
-- C. membership_plans
-- ============================================================================
create table if not exists public.membership_plans (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  name text not null,
  description text,
  duration text not null,
  duration_months integer not null default 1 check (duration_months > 0),
  price numeric(10, 2) not null check (price >= 0),
  features text[] not null default '{}',
  active_status boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- B. memberships
-- ============================================================================
create table if not exists public.memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  membership_plan_id uuid not null references public.membership_plans(id) on delete restrict,
  start_date date not null,
  end_date date not null,
  status text not null default 'Active' check (status in ('Active', 'Expired', 'Pending', 'Cancelled')),
  amount numeric(10, 2) not null check (amount >= 0),
  payment_status text not null default 'Paid' check (payment_status in ('Paid', 'Pending', 'Failed', 'Refunded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_membership_dates check (end_date >= start_date)
);

create index if not exists idx_memberships_user_id on public.memberships (user_id);
create index if not exists idx_memberships_plan_id on public.memberships (membership_plan_id);
create index if not exists idx_memberships_status on public.memberships (status);

drop trigger if exists trg_memberships_updated_at on public.memberships;
create trigger trg_memberships_updated_at
  before update on public.memberships
  for each row execute function private.set_updated_at();

-- ============================================================================
-- D. attendance
-- ============================================================================
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  check_in_time timestamptz not null default now(),
  check_out_time timestamptz,
  attendance_date date not null default current_date,
  check_in_method text not null default 'QR Code' check (check_in_method in ('QR Code', 'Front Desk', 'Mobile Pass', 'Manual')),
  location text not null default 'Main Gym Floor',
  status text not null default 'Present' check (status in ('Present', 'Completed', 'Late')),
  created_at timestamptz not null default now()
);

create index if not exists idx_attendance_user_date on public.attendance (user_id, attendance_date desc);

-- ============================================================================
-- E. trainers & trainer_assignments
-- ============================================================================
create table if not exists public.trainers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references public.profiles(id) on delete set null,
  full_name text not null,
  specialization text not null,
  experience text not null,
  experience_years integer not null default 1 check (experience_years >= 0),
  rating numeric(2, 1) not null default 5.0 check (rating >= 0 and rating <= 5),
  availability text not null default 'Mon–Sat, 06:00 AM – 08:00 PM',
  bio text,
  certifications text[] not null default '{}',
  profile_image text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_trainers_user_id on public.trainers (user_id);

create table if not exists public.trainer_assignments (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references public.trainers(id) on delete cascade,
  member_id uuid not null references public.profiles(id) on delete cascade,
  is_active boolean not null default true,
  assigned_at timestamptz not null default now(),
  unique (trainer_id, member_id)
);

create index if not exists idx_trainer_assignments_member on public.trainer_assignments (member_id) where is_active = true;
create index if not exists idx_trainer_assignments_trainer on public.trainer_assignments (trainer_id) where is_active = true;

-- ============================================================================
-- G. exercises
-- ============================================================================
create table if not exists public.exercises (
  id uuid primary key default gen_random_uuid(),
  slug text unique,
  name text not null,
  description text,
  target_muscles text not null,
  equipment text not null default 'Bodyweight',
  difficulty text not null default 'Beginner' check (difficulty in ('Beginner', 'Intermediate', 'Advanced')),
  category text not null default 'Strength',
  instructions text[] not null default '{}',
  common_mistakes text[] not null default '{}',
  easier_variation text,
  harder_variation text,
  alternative_exercise_slug text,
  rest_seconds integer not null default 60 check (rest_seconds >= 0),
  image_url text,
  video_url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_exercises_slug on public.exercises (slug);
create index if not exists idx_exercises_difficulty on public.exercises (difficulty);

-- ============================================================================
-- F. workout_plans & fitness_profiles
-- ============================================================================
create table if not exists public.fitness_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  age integer not null check (age >= 14 and age <= 95),
  height_cm numeric(5, 2) not null check (height_cm >= 100 and height_cm <= 250),
  weight_kg numeric(5, 2) not null check (weight_kg >= 30 and weight_kg <= 250),
  target_weight_kg numeric(5, 2),
  fitness_level text not null check (fitness_level in ('Beginner', 'Advanced', 'High-Performance')),
  primary_goal text not null check (primary_goal in ('Muscle Gain', 'Fat Loss', 'Strength', 'Endurance', 'General Fitness')),
  training_experience text not null default '6–18 months',
  training_days_per_week integer not null check (training_days_per_week between 2 and 6),
  workout_duration_minutes integer not null check (workout_duration_minutes between 20 and 120),
  workout_location text not null check (workout_location in ('Gym', 'Home')),
  available_equipment text[] not null default '{Bodyweight}',
  preferred_exercises text[] not null default '{}',
  avoid_exercises text[] not null default '{}',
  injuries_or_concerns text,
  has_medical_clearance_notice boolean not null default false,
  disclaimer_accepted boolean not null default true,
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_fitness_profiles_updated_at on public.fitness_profiles;
create trigger trg_fitness_profiles_updated_at
  before update on public.fitness_profiles
  for each row execute function private.set_updated_at();

create table if not exists public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  trainer_id uuid references public.trainers(id) on delete set null,
  plan_name text not null,
  split_summary text,
  fitness_goal text not null,
  fitness_level text not null,
  workout_location text not null default 'Gym',
  duration_weeks integer not null default 4 check (duration_weeks > 0),
  training_days_per_week integer not null default 4 check (training_days_per_week between 1 and 7),
  schedule jsonb not null default '{}'::jsonb,
  progression_guidance text,
  recovery_guidance text,
  status text not null default 'active' check (status in ('active', 'archived', 'draft')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_workout_plans_user_id on public.workout_plans (user_id);
create index if not exists idx_workout_plans_trainer_id on public.workout_plans (trainer_id);

drop trigger if exists trg_workout_plans_updated_at on public.workout_plans;
create trigger trg_workout_plans_updated_at
  before update on public.workout_plans
  for each row execute function private.set_updated_at();

-- ============================================================================
-- H. workout_logs & personal_records
-- ============================================================================
create table if not exists public.workout_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  workout_plan_id uuid references public.workout_plans(id) on delete set null,
  exercise_id uuid references public.exercises(id) on delete set null,
  session_id text,
  session_title text,
  focus text,
  sets_completed integer not null default 0 check (sets_completed >= 0),
  repetitions integer not null default 0 check (repetitions >= 0),
  weight_used numeric(7, 2),
  duration integer not null default 0 check (duration >= 0),
  perceived_difficulty integer default 6 check (perceived_difficulty between 1 and 10),
  stopped_due_to_discomfort boolean not null default false,
  discomfort_note text,
  exercise_logs jsonb not null default '[]'::jsonb,
  completed_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_workout_logs_user_completed on public.workout_logs (user_id, completed_at desc);
create index if not exists idx_workout_logs_plan on public.workout_logs (workout_plan_id);
create index if not exists idx_workout_logs_exercise on public.workout_logs (exercise_id);

create table if not exists public.personal_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  exercise_id uuid references public.exercises(id) on delete set null,
  exercise_slug text not null,
  exercise_name text not null,
  record_type text not null check (record_type in ('Max Weight', 'Max Reps', 'Best Time')),
  value numeric(8, 2) not null check (value >= 0),
  unit text not null check (unit in ('kg', 'reps', 'sec')),
  achieved_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_personal_records_user on public.personal_records (user_id, achieved_at desc);

-- ============================================================================
-- I. diet_plans & J. meals & K. food_logs & L. water_logs
-- ============================================================================
create table if not exists public.diet_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  trainer_id uuid references public.trainers(id) on delete set null,
  plan_name text not null,
  fitness_goal text not null,
  daily_calories integer not null check (daily_calories >= 1000),
  protein_target integer not null check (protein_target >= 0),
  carbohydrate_target integer not null check (carbohydrate_target >= 0),
  fat_target integer not null check (fat_target >= 0),
  fiber_target integer not null default 30 check (fiber_target >= 0),
  water_target integer not null default 3500 check (water_target >= 500),
  trainer_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_diet_plans_user on public.diet_plans (user_id);

drop trigger if exists trg_diet_plans_updated_at on public.diet_plans;
create trigger trg_diet_plans_updated_at
  before update on public.diet_plans
  for each row execute function private.set_updated_at();

create table if not exists public.meals (
  id uuid primary key default gen_random_uuid(),
  diet_plan_id uuid not null references public.diet_plans(id) on delete cascade,
  day_label text not null default 'Training Day',
  meal_name text not null,
  meal_time text not null,
  food_items jsonb not null default '[]'::jsonb,
  calories integer not null default 0 check (calories >= 0),
  protein integer not null default 0 check (protein >= 0),
  carbohydrates integer not null default 0 check (carbohydrates >= 0),
  fat integer not null default 0 check (fat >= 0),
  instructions text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_meals_diet_plan on public.meals (diet_plan_id);

create table if not exists public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  meal_id uuid references public.meals(id) on delete set null,
  food_name text not null,
  quantity text not null default '1 serving',
  calories integer not null default 0 check (calories >= 0),
  protein numeric(6, 2) not null default 0 check (protein >= 0),
  carbohydrates numeric(6, 2) not null default 0 check (carbohydrates >= 0),
  fat numeric(6, 2) not null default 0 check (fat >= 0),
  consumed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_food_logs_user_consumed on public.food_logs (user_id, consumed_at desc);

create table if not exists public.water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  quantity_ml integer not null check (quantity_ml > 0 and quantity_ml <= 5000),
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_water_logs_user_logged on public.water_logs (user_id, logged_at desc);

-- ============================================================================
-- M. payments (strictly verified transaction ledger; never stores card/CVV/bank secrets)
-- ============================================================================
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  membership_id uuid references public.memberships(id) on delete set null,
  amount numeric(10, 2) not null check (amount >= 0),
  payment_method text not null,
  transaction_reference text unique not null,
  invoice_number text unique,
  service_name text,
  description text,
  subtotal numeric(10, 2),
  tax_amount numeric(10, 2),
  payment_status text not null default 'Paid' check (payment_status in ('Paid', 'Pending', 'Failed', 'Refunded')),
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_payments_user_created on public.payments (user_id, created_at desc);
create index if not exists idx_payments_membership on public.payments (membership_id);

-- ============================================================================
-- N. notifications (user_id NULL = general gym announcement)
-- ============================================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  notification_type text not null default 'announcement'
    check (notification_type in ('membership', 'class', 'payment', 'workout', 'diet', 'trainer', 'announcement', 'progress')),
  action_route text,
  action_label text,
  is_read boolean not null default false,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_created on public.notifications (user_id, created_at desc);
create index if not exists idx_notifications_public_announcements on public.notifications (created_at desc) where user_id is null and is_published = true;

-- ============================================================================
-- Additional Domain Tables Matching Existing App Screens
-- ============================================================================
create table if not exists public.fitness_measurements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  recorded_at timestamptz not null default now(),
  weight_kg numeric(5, 2) not null check (weight_kg >= 20 and weight_kg <= 350),
  body_fat_pct numeric(4, 1),
  muscle_mass_kg numeric(5, 2),
  chest_cm numeric(5, 1),
  waist_cm numeric(5, 1),
  hips_cm numeric(5, 1),
  bmi numeric(4, 1),
  progress_image_path text,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_fitness_measurements_user_date on public.fitness_measurements (user_id, recorded_at desc);

create table if not exists public.fitness_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  category text not null,
  start_value numeric(8, 2) not null default 0,
  target_value numeric(8, 2) not null,
  current_value numeric(8, 2) not null default 0,
  unit text not null,
  start_date date not null default current_date,
  target_date date not null,
  is_completed boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_fitness_goals_user on public.fitness_goals (user_id);

create table if not exists public.gym_classes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  trainer_id uuid references public.trainers(id) on delete set null,
  trainer_name text not null,
  room text not null,
  start_time timestamptz not null,
  duration_minutes integer not null default 45 check (duration_minutes > 0),
  capacity integer not null default 20 check (capacity > 0),
  booked_count integer not null default 0 check (booked_count >= 0),
  category text not null default 'Fitness',
  level text not null default 'All Levels',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists idx_gym_classes_start on public.gym_classes (start_time) where is_active = true;

create table if not exists public.class_bookings (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.gym_classes(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'Confirmed' check (status in ('Confirmed', 'Cancelled', 'Attended')),
  booked_at timestamptz not null default now()
);

create index if not exists idx_class_bookings_user on public.class_bookings (user_id, booked_at desc);
create index if not exists idx_class_bookings_class on public.class_bookings (class_id);

create table if not exists public.training_sessions (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references public.trainers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  scheduled_at timestamptz not null,
  duration_minutes integer not null default 60,
  location text not null default 'Main Gym Floor',
  status text not null default 'Scheduled' check (status in ('Scheduled', 'Completed', 'Cancelled')),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_training_sessions_user on public.training_sessions (user_id, scheduled_at desc);
create index if not exists idx_training_sessions_trainer on public.training_sessions (trainer_id);

create table if not exists public.trainer_messages (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references public.trainers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  sender_role text not null check (sender_role in ('member', 'trainer')),
  message text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_trainer_messages_user_trainer on public.trainer_messages (user_id, trainer_id, created_at desc);

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  membership_reminders boolean not null default true,
  payment_reminders boolean not null default true,
  workout_reminders boolean not null default true,
  class_reminders boolean not null default true,
  gym_announcements boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.support_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category text not null,
  subject text not null,
  message text not null,
  is_issue_report boolean not null default false,
  status text not null default 'Open' check (status in ('Open', 'In Review', 'Resolved')),
  created_at timestamptz not null default now()
);

create index if not exists idx_support_feedback_user on public.support_feedback (user_id, created_at desc);
