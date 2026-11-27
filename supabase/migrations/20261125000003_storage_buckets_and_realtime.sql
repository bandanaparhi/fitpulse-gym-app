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
