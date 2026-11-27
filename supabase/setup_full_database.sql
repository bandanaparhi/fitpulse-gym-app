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
-- FitPulse Gym Management — Explicit Data API Grants & Row Level Security (RLS) Policies
-- Follows Supabase 2026 Security Checklist:
--   - Explicit GRANTs on public schema & tables (required after Oct 2026 Data API change)
--   - RLS enabled on every public table
--   - Target roles explicitly declared with TO authenticated / TO anon
--   - (select auth.uid()) wrapped in scalar subqueries for cached RLS performance
--   - UPDATE policies enforce both USING and WITH CHECK
--   - Role checks rely on trusted profiles.role / app_metadata (never user_metadata)

-- ============================================================================
-- 1. Schema & Table Grants
-- ============================================================================
grant usage on schema public to anon, authenticated;
grant usage on schema private to authenticated;

-- Revoke broad defaults from anon on all private member tables
revoke all on all tables in schema public from anon;

-- Catalog / public-read tables (still protected by RLS)
grant select on public.membership_plans to anon, authenticated;
grant select on public.exercises to authenticated;
grant select on public.trainers to authenticated;
grant select on public.gym_classes to authenticated;
grant select on public.notifications to authenticated;

-- Authenticated user-scoped tables
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.memberships to authenticated;
grant select, insert, update on public.attendance to authenticated;
grant select, insert, update, delete on public.fitness_profiles to authenticated;
grant select, insert, update, delete on public.workout_plans to authenticated;
grant select, insert, update, delete on public.workout_logs to authenticated;
grant select, insert, update, delete on public.personal_records to authenticated;
grant select, insert, update, delete on public.diet_plans to authenticated;
grant select, insert, update, delete on public.meals to authenticated;
grant select, insert, update, delete on public.food_logs to authenticated;
grant select, insert, update, delete on public.water_logs to authenticated;
grant select on public.payments to authenticated;
grant update on public.notifications to authenticated;
grant select, insert, update, delete on public.fitness_measurements to authenticated;
grant select, insert, update, delete on public.fitness_goals to authenticated;
grant select, insert, update on public.class_bookings to authenticated;
grant select, insert, update on public.training_sessions to authenticated;
grant select, insert on public.trainer_messages to authenticated;
grant select, insert, update on public.notification_preferences to authenticated;
grant select, insert on public.support_feedback to authenticated;
grant select on public.trainer_assignments to authenticated;

-- ============================================================================
-- 2. Private RLS Helper Functions
-- ============================================================================
create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.role = 'admin'
  );
$$;

create or replace function private.is_trainer_for_member(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.trainer_assignments ta
    join public.trainers t on t.id = ta.trainer_id
    where t.user_id = (select auth.uid())
      and ta.member_id = target_user_id
      and ta.is_active = true
  );
$$;

create or replace function private.owns_diet_plan(target_diet_plan_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.diet_plans dp
    where dp.id = target_diet_plan_id
      and dp.user_id = (select auth.uid())
  );
$$;

revoke execute on function private.is_admin() from public, anon;
revoke execute on function private.is_trainer_for_member(uuid) from public, anon;
revoke execute on function private.owns_diet_plan(uuid) from public, anon;
grant execute on function private.is_admin() to authenticated;
grant execute on function private.is_trainer_for_member(uuid) to authenticated;
grant execute on function private.owns_diet_plan(uuid) to authenticated;

-- ============================================================================
-- 3. Enable RLS on Every Table
-- ============================================================================
alter table public.profiles enable row level security;
alter table public.membership_plans enable row level security;
alter table public.memberships enable row level security;
alter table public.attendance enable row level security;
alter table public.trainers enable row level security;
alter table public.trainer_assignments enable row level security;
alter table public.exercises enable row level security;
alter table public.fitness_profiles enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_logs enable row level security;
alter table public.personal_records enable row level security;
alter table public.diet_plans enable row level security;
alter table public.meals enable row level security;
alter table public.food_logs enable row level security;
alter table public.water_logs enable row level security;
alter table public.payments enable row level security;
alter table public.notifications enable row level security;
alter table public.fitness_measurements enable row level security;
alter table public.fitness_goals enable row level security;
alter table public.gym_classes enable row level security;
alter table public.class_bookings enable row level security;
alter table public.training_sessions enable row level security;
alter table public.trainer_messages enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.support_feedback enable row level security;

-- ============================================================================
-- 4. RLS Policies
-- ============================================================================

-- PROFILES: Members read/update own profile; assigned trainers read assigned members; admins full access.
drop policy if exists "profiles_select_own_trainer_admin" on public.profiles;
create policy "profiles_select_own_trainer_admin" on public.profiles
  for select to authenticated
  using (
    id = (select auth.uid())
    or (select private.is_trainer_for_member(id))
    or (select private.is_admin())
  );

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check (id = (select auth.uid()) and role = 'member');

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()) or (select private.is_admin()))
  with check (id = (select auth.uid()) or (select private.is_admin()));

-- MEMBERSHIP PLANS: Active catalog readable by authenticated users & anon preview; admins manage.
drop policy if exists "membership_plans_select_active" on public.membership_plans;
create policy "membership_plans_select_active" on public.membership_plans
  for select to anon, authenticated
  using (active_status = true or (select private.is_admin()));

drop policy if exists "membership_plans_admin_all" on public.membership_plans;
create policy "membership_plans_admin_all" on public.membership_plans
  for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- MEMBERSHIPS: Own read (+ pending/renew request insert only by owner or admin), admin full access.
drop policy if exists "memberships_select_own_or_admin" on public.memberships;
create policy "memberships_select_own_or_admin" on public.memberships
  for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "memberships_insert_own_or_admin" on public.memberships;
create policy "memberships_insert_own_or_admin" on public.memberships
  for insert to authenticated
  with check (
    (user_id = (select auth.uid()) and payment_status = 'Pending')
    or (select private.is_admin())
  );

drop policy if exists "memberships_admin_update" on public.memberships;
create policy "memberships_admin_update" on public.memberships
  for update to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- ATTENDANCE: Own read/check-in/check-out; admin full access.
drop policy if exists "attendance_select_own_or_admin" on public.attendance;
create policy "attendance_select_own_or_admin" on public.attendance
  for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "attendance_insert_own_or_admin" on public.attendance;
create policy "attendance_insert_own_or_admin" on public.attendance
  for insert to authenticated
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "attendance_update_own_or_admin" on public.attendance;
create policy "attendance_update_own_or_admin" on public.attendance
  for update to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

-- TRAINERS & TRAINER ASSIGNMENTS
drop policy if exists "trainers_select_authenticated" on public.trainers;
create policy "trainers_select_authenticated" on public.trainers
  for select to authenticated
  using (is_active = true or user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "trainers_admin_all" on public.trainers;
create policy "trainers_admin_all" on public.trainers
  for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

drop policy if exists "trainer_assignments_select" on public.trainer_assignments;
create policy "trainer_assignments_select" on public.trainer_assignments
  for select to authenticated
  using (
    member_id = (select auth.uid())
    or exists (select 1 from public.trainers t where t.id = trainer_id and t.user_id = (select auth.uid()))
    or (select private.is_admin())
  );

drop policy if exists "trainer_assignments_admin_all" on public.trainer_assignments;
create policy "trainer_assignments_admin_all" on public.trainer_assignments
  for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- EXERCISES: Read-only catalog for authenticated members; admins/trainers manage.
drop policy if exists "exercises_select_authenticated" on public.exercises;
create policy "exercises_select_authenticated" on public.exercises
  for select to authenticated
  using (true);

drop policy if exists "exercises_admin_all" on public.exercises;
create policy "exercises_admin_all" on public.exercises
  for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- FITNESS PROFILES: Own full access; assigned trainer read; admin read.
drop policy if exists "fitness_profiles_select" on public.fitness_profiles;
create policy "fitness_profiles_select" on public.fitness_profiles
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "fitness_profiles_write_own" on public.fitness_profiles;
create policy "fitness_profiles_write_own" on public.fitness_profiles
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "fitness_profiles_update_own" on public.fitness_profiles;
create policy "fitness_profiles_update_own" on public.fitness_profiles
  for update to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

-- WORKOUT PLANS: Member own + assigned trainer + admin.
drop policy if exists "workout_plans_select" on public.workout_plans;
create policy "workout_plans_select" on public.workout_plans
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "workout_plans_insert" on public.workout_plans;
create policy "workout_plans_insert" on public.workout_plans
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "workout_plans_update" on public.workout_plans;
create policy "workout_plans_update" on public.workout_plans
  for update to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  )
  with check (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "workout_plans_delete_own" on public.workout_plans;
create policy "workout_plans_delete_own" on public.workout_plans
  for delete to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

-- WORKOUT LOGS & PERSONAL RECORDS: Strictly member own write/read (assigned trainer read-only).
drop policy if exists "workout_logs_select" on public.workout_logs;
create policy "workout_logs_select" on public.workout_logs
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "workout_logs_insert_own" on public.workout_logs;
create policy "workout_logs_insert_own" on public.workout_logs
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "workout_logs_update_own" on public.workout_logs;
create policy "workout_logs_update_own" on public.workout_logs
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "workout_logs_delete_own" on public.workout_logs;
create policy "workout_logs_delete_own" on public.workout_logs
  for delete to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "personal_records_select" on public.personal_records;
create policy "personal_records_select" on public.personal_records
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "personal_records_insert_own" on public.personal_records;
create policy "personal_records_insert_own" on public.personal_records
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "personal_records_update_own" on public.personal_records;
create policy "personal_records_update_own" on public.personal_records
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "personal_records_delete_own" on public.personal_records;
create policy "personal_records_delete_own" on public.personal_records
  for delete to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

-- DIET PLANS & MEALS
drop policy if exists "diet_plans_select" on public.diet_plans;
create policy "diet_plans_select" on public.diet_plans
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "diet_plans_insert" on public.diet_plans;
create policy "diet_plans_insert" on public.diet_plans
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "diet_plans_update" on public.diet_plans;
create policy "diet_plans_update" on public.diet_plans
  for update to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  )
  with check (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "meals_select" on public.meals;
create policy "meals_select" on public.meals
  for select to authenticated
  using (
    (select private.owns_diet_plan(diet_plan_id))
    or exists (
      select 1 from public.diet_plans dp
      where dp.id = diet_plan_id and (select private.is_trainer_for_member(dp.user_id))
    )
    or (select private.is_admin())
  );

drop policy if exists "meals_write" on public.meals;
create policy "meals_write" on public.meals
  for all to authenticated
  using ((select private.owns_diet_plan(diet_plan_id)) or (select private.is_admin()))
  with check ((select private.owns_diet_plan(diet_plan_id)) or (select private.is_admin()));

-- FOOD LOGS & WATER LOGS: Strictly private to member.
drop policy if exists "food_logs_own" on public.food_logs;
create policy "food_logs_own" on public.food_logs
  for all to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "water_logs_own" on public.water_logs;
create policy "water_logs_own" on public.water_logs
  for all to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

-- PAYMENTS: Read-only for member (verified records); writes strictly admin/backend.
drop policy if exists "payments_select_own_or_admin" on public.payments;
create policy "payments_select_own_or_admin" on public.payments
  for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "payments_admin_all" on public.payments;
create policy "payments_admin_all" on public.payments
  for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- NOTIFICATIONS: Own private notifications + published public announcements (user_id IS NULL).
drop policy if exists "notifications_select_own_or_public" on public.notifications;
create policy "notifications_select_own_or_public" on public.notifications
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (user_id is null and is_published = true)
    or (select private.is_admin())
  );

drop policy if exists "notifications_update_own_read" on public.notifications;
create policy "notifications_update_own_read" on public.notifications
  for update to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "notifications_admin_insert_delete" on public.notifications;
create policy "notifications_admin_insert_delete" on public.notifications
  for insert to authenticated
  with check ((select private.is_admin()));

-- PROGRESS MEASUREMENTS & GOALS: Strictly member own (assigned trainer read).
drop policy if exists "fitness_measurements_select" on public.fitness_measurements;
create policy "fitness_measurements_select" on public.fitness_measurements
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select private.is_trainer_for_member(user_id))
    or (select private.is_admin())
  );

drop policy if exists "fitness_measurements_write_own" on public.fitness_measurements;
create policy "fitness_measurements_write_own" on public.fitness_measurements
  for all to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "fitness_goals_own" on public.fitness_goals;
create policy "fitness_goals_own" on public.fitness_goals
  for all to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

-- CLASSES & BOOKINGS
drop policy if exists "gym_classes_select_active" on public.gym_classes;
create policy "gym_classes_select_active" on public.gym_classes
  for select to authenticated
  using (is_active = true or (select private.is_admin()));

drop policy if exists "gym_classes_admin_all" on public.gym_classes;
create policy "gym_classes_admin_all" on public.gym_classes
  for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

drop policy if exists "class_bookings_own" on public.class_bookings;
create policy "class_bookings_own" on public.class_bookings
  for all to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));

-- TRAINING SESSIONS & MESSAGES
drop policy if exists "training_sessions_select" on public.training_sessions;
create policy "training_sessions_select" on public.training_sessions
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (select 1 from public.trainers t where t.id = trainer_id and t.user_id = (select auth.uid()))
    or (select private.is_admin())
  );

drop policy if exists "training_sessions_update" on public.training_sessions;
create policy "training_sessions_update" on public.training_sessions
  for update to authenticated
  using (
    user_id = (select auth.uid())
    or exists (select 1 from public.trainers t where t.id = trainer_id and t.user_id = (select auth.uid()))
    or (select private.is_admin())
  )
  with check (
    user_id = (select auth.uid())
    or exists (select 1 from public.trainers t where t.id = trainer_id and t.user_id = (select auth.uid()))
    or (select private.is_admin())
  );

drop policy if exists "trainer_messages_participants" on public.trainer_messages;
create policy "trainer_messages_participants" on public.trainer_messages
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (select 1 from public.trainers t where t.id = trainer_id and t.user_id = (select auth.uid()))
    or (select private.is_admin())
  );

drop policy if exists "trainer_messages_insert" on public.trainer_messages;
create policy "trainer_messages_insert" on public.trainer_messages
  for insert to authenticated
  with check (
    (user_id = (select auth.uid()) and sender_role = 'member')
    or (exists (select 1 from public.trainers t where t.id = trainer_id and t.user_id = (select auth.uid())) and sender_role = 'trainer')
    or (select private.is_admin())
  );

-- SETTINGS & SUPPORT
drop policy if exists "notification_preferences_own" on public.notification_preferences;
create policy "notification_preferences_own" on public.notification_preferences
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "support_feedback_own" on public.support_feedback;
create policy "support_feedback_own" on public.support_feedback
  for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

drop policy if exists "support_feedback_insert_own" on public.support_feedback;
create policy "support_feedback_insert_own" on public.support_feedback
  for insert to authenticated
  with check (user_id = (select auth.uid()));
-- FitPulse Gym Management — Storage Buckets, Storage RLS Policies & Realtime Publication

-- ============================================================================
-- 1. Storage Buckets
-- ============================================================================
-- profile-images: Authenticated member profile avatars (scoped to <uid>/...)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-images',
  'profile-images',
  false,
  5242880, -- 5 MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- progress-images: Strictly private member body-progress photos (<uid>/...)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'progress-images',
  'progress-images',
  false,
  10485760, -- 10 MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

-- exercise-media: Authenticated read for gym exercise reference media; admin write
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'exercise-media',
  'exercise-media',
  false,
  20971520, -- 20 MB
  array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']
)
on conflict (id) do update
set public = false,
    file_size_limit = 20971520,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'video/mp4'];

-- ============================================================================
-- 2. Storage Object RLS Policies
-- Note: Upsert requires INSERT + SELECT + UPDATE permissions.
-- Folder convention: <bucket>/<auth.uid()>/<filename>
-- ============================================================================

-- profile-images policies (owner folder)
drop policy if exists "profile_images_select_own" on storage.objects;
create policy "profile_images_select_own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'profile-images'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select private.is_admin())
    )
  );

drop policy if exists "profile_images_insert_own" on storage.objects;
create policy "profile_images_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "profile_images_update_own" on storage.objects;
create policy "profile_images_update_own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'profile-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "profile_images_delete_own" on storage.objects;
create policy "profile_images_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'profile-images'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select private.is_admin())
    )
  );

-- progress-images policies (strictly private to owner; never public)
drop policy if exists "progress_images_select_own" on storage.objects;
create policy "progress_images_select_own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'progress-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "progress_images_insert_own" on storage.objects;
create policy "progress_images_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'progress-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "progress_images_update_own" on storage.objects;
create policy "progress_images_update_own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'progress-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'progress-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "progress_images_delete_own" on storage.objects;
create policy "progress_images_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'progress-images'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- exercise-media policies (authenticated read; admin write)
drop policy if exists "exercise_media_select_auth" on storage.objects;
create policy "exercise_media_select_auth" on storage.objects
  for select to authenticated
  using (bucket_id = 'exercise-media');

drop policy if exists "exercise_media_admin_write" on storage.objects;
create policy "exercise_media_admin_write" on storage.objects
  for all to authenticated
  using (bucket_id = 'exercise-media' and (select private.is_admin()))
  with check (bucket_id = 'exercise-media' and (select private.is_admin()));

-- ============================================================================
-- 3. Enable Supabase Realtime Publications (safe idempotent add)
-- ============================================================================
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
    ) then
      alter publication supabase_realtime add table public.notifications;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'memberships'
    ) then
      alter publication supabase_realtime add table public.memberships;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'attendance'
    ) then
      alter publication supabase_realtime add table public.attendance;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'trainer_messages'
    ) then
      alter publication supabase_realtime add table public.trainer_messages;
    end if;
  end if;
end $$;
-- Eliminate multiple permissive SELECT policies by scoping write policies to INSERT/UPDATE/DELETE

-- 1. membership_plans
drop policy if exists "membership_plans_admin_all" on public.membership_plans;
create policy "membership_plans_admin_insert" on public.membership_plans
  for insert to authenticated with check ((select private.is_admin()));
create policy "membership_plans_admin_update" on public.membership_plans
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "membership_plans_admin_delete" on public.membership_plans
  for delete to authenticated using ((select private.is_admin()));

-- 2. trainers
drop policy if exists "trainers_admin_all" on public.trainers;
create policy "trainers_admin_insert" on public.trainers
  for insert to authenticated with check ((select private.is_admin()));
create policy "trainers_admin_update" on public.trainers
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "trainers_admin_delete" on public.trainers
  for delete to authenticated using ((select private.is_admin()));

-- 3. trainer_assignments
drop policy if exists "trainer_assignments_admin_all" on public.trainer_assignments;
create policy "trainer_assignments_admin_insert" on public.trainer_assignments
  for insert to authenticated with check ((select private.is_admin()));
create policy "trainer_assignments_admin_update" on public.trainer_assignments
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "trainer_assignments_admin_delete" on public.trainer_assignments
  for delete to authenticated using ((select private.is_admin()));

-- 4. exercises
drop policy if exists "exercises_admin_all" on public.exercises;
create policy "exercises_admin_insert" on public.exercises
  for insert to authenticated with check ((select private.is_admin()));
create policy "exercises_admin_update" on public.exercises
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "exercises_admin_delete" on public.exercises
  for delete to authenticated using ((select private.is_admin()));

-- 5. meals
drop policy if exists "meals_write" on public.meals;
create policy "meals_insert" on public.meals
  for insert to authenticated
  with check ((select private.owns_diet_plan(diet_plan_id)) or (select private.is_admin()));
create policy "meals_update" on public.meals
  for update to authenticated
  using ((select private.owns_diet_plan(diet_plan_id)) or (select private.is_admin()))
  with check ((select private.owns_diet_plan(diet_plan_id)) or (select private.is_admin()));
create policy "meals_delete" on public.meals
  for delete to authenticated
  using ((select private.owns_diet_plan(diet_plan_id)) or (select private.is_admin()));

-- 6. payments
drop policy if exists "payments_admin_all" on public.payments;
create policy "payments_admin_insert" on public.payments
  for insert to authenticated with check ((select private.is_admin()));
create policy "payments_admin_update" on public.payments
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "payments_admin_delete" on public.payments
  for delete to authenticated using ((select private.is_admin()));

-- 7. fitness_measurements
drop policy if exists "fitness_measurements_write_own" on public.fitness_measurements;
create policy "fitness_measurements_insert_own" on public.fitness_measurements
  for insert to authenticated
  with check (user_id = (select auth.uid()) or (select private.is_admin()));
create policy "fitness_measurements_update_own" on public.fitness_measurements
  for update to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()))
  with check (user_id = (select auth.uid()) or (select private.is_admin()));
create policy "fitness_measurements_delete_own" on public.fitness_measurements
  for delete to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

-- 8. gym_classes
drop policy if exists "gym_classes_admin_all" on public.gym_classes;
create policy "gym_classes_admin_insert" on public.gym_classes
  for insert to authenticated with check ((select private.is_admin()));
create policy "gym_classes_admin_update" on public.gym_classes
  for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "gym_classes_admin_delete" on public.gym_classes
  for delete to authenticated using ((select private.is_admin()));
-- Scope anon SELECT on membership_plans strictly to active_status = true
-- without invoking private.is_admin(), keeping schema private inaccessible to anon.

drop policy if exists "membership_plans_select_active" on public.membership_plans;

create policy "membership_plans_select_anon" on public.membership_plans
  for select to anon
  using (active_status = true);

create policy "membership_plans_select_authenticated" on public.membership_plans
  for select to authenticated
  using (active_status = true or (select private.is_admin()));
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
