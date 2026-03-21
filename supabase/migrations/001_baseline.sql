-- Baseline: schools, profiles, school_members + RLS + get_my_school_id()
-- Owner: Supabase / DB agent — see docs/wave2_delegation.md

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.school_members (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null check (role in ('admin', 'teacher', 'parent')),
  created_at timestamptz not null default now(),
  unique (school_id, user_id)
);

create index if not exists school_members_user_id_idx on public.school_members (user_id);
create index if not exists school_members_school_id_idx on public.school_members (school_id);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.schools enable row level security;
alter table public.profiles enable row level security;
alter table public.school_members enable row level security;

-- ---------------------------------------------------------------------------
-- Helper: school_ids for the current user (membership-based)
-- SECURITY DEFINER: reads membership rows regardless of RLS recursion on policies.
-- ---------------------------------------------------------------------------

create or replace function public.user_school_ids ()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select school_id
  from public.school_members
  where user_id = auth.uid ();
$$;

grant execute on function public.user_school_ids () to authenticated;

-- ---------------------------------------------------------------------------
-- get_my_school_id — single active school for MVP (deterministic: oldest membership)
-- If multiple memberships exist, product should later add explicit "active school" context.
-- ---------------------------------------------------------------------------

create or replace function public.get_my_school_id ()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select school_id
  from public.school_members
  where user_id = auth.uid ()
  order by created_at asc
  limit 1;
$$;

grant execute on function public.get_my_school_id () to authenticated;

-- ---------------------------------------------------------------------------
-- Policies — tenant isolation via school_members
-- ---------------------------------------------------------------------------

-- Schools: visible if user is a member of that school
create policy schools_select_member
  on public.schools
  for select
  to authenticated
  using (id in (select public.user_school_ids ()));

-- School members: visible if same school as caller (any shared school)
create policy school_members_select_same_tenant
  on public.school_members
  for select
  to authenticated
  using (school_id in (select public.user_school_ids ()));

-- Profiles: own row + profiles of users who share at least one school
create policy profiles_select_tenant_peers
  on public.profiles
  for select
  to authenticated
  using (
    id = auth.uid ()
    or id in (
      select sm2.user_id
      from public.school_members sm1
      join public.school_members sm2 on sm1.school_id = sm2.school_id
      where sm1.user_id = auth.uid ()
    )
  );

-- Profiles: users manage their own row (typical Supabase pattern)
create policy profiles_insert_own
  on public.profiles
  for insert
  to authenticated
  with check (id = auth.uid ());

create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid ())
  with check (id = auth.uid ());

-- ---------------------------------------------------------------------------
-- Writes: no direct INSERT on schools / school_members from clients for bootstrap
-- (open policies allowed claiming arbitrary school_id). Use RPC below.
-- Admins may INSERT new members where they are admin of that school.
-- ---------------------------------------------------------------------------

create policy school_members_insert_admin_invite
  on public.school_members
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  );

create policy school_members_update_admin
  on public.school_members
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  );

-- Atomic first school + admin membership (caller must have profile row)
create or replace function public.create_school_with_admin (school_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  if school_name is null or length(trim(school_name)) = 0 then
    raise exception 'school_name required';
  end if;

  if not exists (select 1 from public.profiles p where p.id = auth.uid ()) then
    raise exception 'Profile required before creating a school';
  end if;

  if exists (select 1 from public.school_members where user_id = auth.uid ()) then
    raise exception 'User already belongs to a school';
  end if;

  insert into public.schools (name)
  values (trim(school_name))
  returning id into new_id;

  insert into public.school_members (school_id, user_id, role)
  values (new_id, auth.uid (), 'admin');

  return new_id;
end;
$$;

grant execute on function public.create_school_with_admin (text) to authenticated;
