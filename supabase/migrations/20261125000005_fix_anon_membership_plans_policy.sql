-- Scope anon SELECT on membership_plans strictly to active_status = true
-- without invoking private.is_admin(), keeping schema private inaccessible to anon.

drop policy if exists "membership_plans_select_active" on public.membership_plans;

create policy "membership_plans_select_anon" on public.membership_plans
  for select to anon
  using (active_status = true);

create policy "membership_plans_select_authenticated" on public.membership_plans
  for select to authenticated
  using (active_status = true or (select private.is_admin()));
