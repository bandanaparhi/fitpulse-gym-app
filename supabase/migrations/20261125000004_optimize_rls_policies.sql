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
