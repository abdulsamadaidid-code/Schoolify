-- Admin user management RPCs

-- profiles.email may be missing in baseline; add for lookup RPC support.
alter table public.profiles
  add column if not exists email text;

create index if not exists profiles_email_lower_idx
  on public.profiles (lower(email))
  where email is not null;

-- ---------------------------------------------------------------------------
-- RPC: list school members (admin only)
-- ---------------------------------------------------------------------------

create or replace function public.list_school_members (
  school_id uuid
)
returns table (
  user_id uuid,
  display_name text,
  email text,
  role text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if school_id is null then
    raise exception 'school_id is required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = list_school_members.school_id
      and sm.user_id = auth.uid ()
      and sm.role = 'admin'
  ) then
    raise exception 'Not authorized to list members for this school';
  end if;

  return query
  select
    sm.user_id,
    p.display_name,
    p.email,
    sm.role
  from public.school_members sm
  left join public.profiles p on p.id = sm.user_id
  where sm.school_id = list_school_members.school_id
  order by sm.created_at asc;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: add school member (admin only)
-- ---------------------------------------------------------------------------

create or replace function public.add_school_member (
  school_id uuid,
  profile_id uuid,
  role text
)
returns public.school_members
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.school_members;
begin
  if school_id is null or profile_id is null or role is null then
    raise exception 'school_id, profile_id, and role are required';
  end if;

  if role not in ('admin', 'teacher', 'parent') then
    raise exception 'role must be one of: admin, teacher, parent';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = add_school_member.school_id
      and sm.user_id = auth.uid ()
      and sm.role = 'admin'
  ) then
    raise exception 'Not authorized to add members for this school';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = add_school_member.profile_id
  ) then
    raise exception 'profile_id must reference an existing profile';
  end if;

  insert into public.school_members (school_id, user_id, role)
  values (add_school_member.school_id, add_school_member.profile_id, add_school_member.role)
  returning * into result;

  return result;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: remove school member (admin only, cannot remove self)
-- ---------------------------------------------------------------------------

create or replace function public.remove_school_member (
  school_id uuid,
  profile_id uuid
)
returns public.school_members
language plpgsql
security definer
set search_path = public
as $$
declare
  removed public.school_members;
begin
  if school_id is null or profile_id is null then
    raise exception 'school_id and profile_id are required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = remove_school_member.school_id
      and sm.user_id = auth.uid ()
      and sm.role = 'admin'
  ) then
    raise exception 'Not authorized to remove members for this school';
  end if;

  if profile_id = auth.uid () then
    raise exception 'Admin cannot remove self from school';
  end if;

  delete from public.school_members sm
  where sm.school_id = remove_school_member.school_id
    and sm.user_id = remove_school_member.profile_id
  returning * into removed;

  if removed.id is null then
    raise exception 'Member not found for this school';
  end if;

  return removed;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: lookup profile by email (no role check)
-- ---------------------------------------------------------------------------

create or replace function public.lookup_profile_by_email (
  email text
)
returns table (
  id uuid,
  display_name text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Caller must be an admin of at least one school to prevent profile enumeration.
  if not exists (
    select 1
    from public.school_members sm
    where sm.user_id = auth.uid ()
      and sm.role = 'admin'
  ) then
    raise exception 'Not authorized to look up profiles by email';
  end if;

  return query
  select p.id, p.display_name
  from public.profiles p
  where p.email is not null
    and lower(p.email) = lower(trim(lookup_profile_by_email.email))
  limit 1;
end;
$$;

grant execute on function public.list_school_members (uuid) to authenticated;
grant execute on function public.add_school_member (uuid, uuid, text) to authenticated;
grant execute on function public.remove_school_member (uuid, uuid) to authenticated;
grant execute on function public.lookup_profile_by_email (text) to authenticated;
