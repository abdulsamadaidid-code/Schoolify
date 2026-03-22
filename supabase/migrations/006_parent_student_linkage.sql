-- Parent–student linkage (student_parents) + staff vs parent-scoped reads on students/attendance

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table public.student_parents (
  school_id uuid not null references public.schools (id) on delete cascade,
  student_id uuid not null references public.students (id) on delete cascade,
  parent_user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (student_id, parent_user_id)
);

create index student_parents_parent_user_school_idx
  on public.student_parents (parent_user_id, school_id);

-- ---------------------------------------------------------------------------
-- Row Level Security — student_parents
-- ---------------------------------------------------------------------------

alter table public.student_parents enable row level security;

create policy student_parents_select_own_or_staff
  on public.student_parents
  for select
  to authenticated
  using (
    parent_user_id = auth.uid ()
    or exists (
      select 1
      from public.school_members sm
      where sm.school_id = student_parents.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('admin', 'teacher')
    )
  );

-- ---------------------------------------------------------------------------
-- Replace students / attendance SELECT — staff see school; parents see linked students only
-- ---------------------------------------------------------------------------

drop policy if exists students_select_same_tenant on public.students;

create policy students_select_staff_or_parent_link
  on public.students
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = students.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('admin', 'teacher')
    )
    or exists (
      select 1
      from public.student_parents sp
      where sp.student_id = students.id
        and sp.parent_user_id = auth.uid ()
    )
  );

drop policy if exists attendance_select_same_tenant on public.attendance;

create policy attendance_select_staff_or_parent_link
  on public.attendance
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = attendance.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('admin', 'teacher')
    )
    or exists (
      select 1
      from public.student_parents sp
      where sp.student_id = attendance.student_id
        and sp.parent_user_id = auth.uid ()
    )
  );

-- ---------------------------------------------------------------------------
-- Admin-only link creation (SECURITY DEFINER) — no direct INSERT for parents
-- ---------------------------------------------------------------------------

create or replace function public.add_parent_link (
  school_id uuid,
  student_id uuid,
  parent_user_id uuid
)
returns public.student_parents
language plpgsql
security definer
set search_path = public
as $$
declare
  new_row public.student_parents;
begin
  if school_id is null or student_id is null or parent_user_id is null then
    raise exception 'school_id, student_id, and parent_user_id are required';
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.id = add_parent_link.parent_user_id
  ) then
    raise exception 'parent_user_id must reference an existing profile';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = add_parent_link.school_id
      and sm.user_id = auth.uid ()
      and sm.role = 'admin'
  ) then
    raise exception 'Not authorized to add parent links for this school';
  end if;

  if not exists (
    select 1
    from public.students s
    where s.id = add_parent_link.student_id
      and s.school_id = add_parent_link.school_id
  ) then
    raise exception 'Student does not belong to this school';
  end if;

  insert into public.student_parents (school_id, student_id, parent_user_id)
  values (add_parent_link.school_id, add_parent_link.student_id, add_parent_link.parent_user_id)
  returning * into new_row;

  return new_row;
end;
$$;

grant execute on function public.add_parent_link (uuid, uuid, uuid) to authenticated;

-- Dev seed (manual testing): call as a user who is school admin, or insert with elevated role.
--   select public.add_parent_link(
--     '<school_id>'::uuid,
--     '<student_id>'::uuid,
--     '<parent_profiles.id>'::uuid
--   );
-- Superuser / migration session (bypasses RLS):
--   insert into public.student_parents (school_id, student_id, parent_user_id)
--   values ('<school_id>'::uuid, '<student_id>'::uuid, '<parent_profiles.id>'::uuid);
