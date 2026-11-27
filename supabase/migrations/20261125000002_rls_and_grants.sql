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
