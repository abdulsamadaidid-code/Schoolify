-- Attendance: unique (school, student, day) + teacher/admin upsert RPC (parents stay read-only on table)

-- ---------------------------------------------------------------------------
-- One mark per student per calendar day per school
-- ---------------------------------------------------------------------------

alter table public.attendance
  add constraint attendance_school_student_date_key
  unique (school_id, student_id, date);

-- ---------------------------------------------------------------------------
-- RPC: upsert attendance (SECURITY DEFINER) — only teacher/admin for that school
-- ---------------------------------------------------------------------------

create or replace function public.upsert_attendance_mark (
  school_id uuid,
  student_id uuid,
  p_date date,
  p_status text
)
returns public.attendance
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.attendance;
begin
  if school_id is null or student_id is null or p_date is null then
    raise exception 'school_id, student_id, and p_date are required';
  end if;

  if p_status is null
    or p_status not in ('present', 'absent', 'excused') then
    raise exception 'p_status must be one of: present, absent, excused';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = upsert_attendance_mark.school_id
      and sm.user_id = auth.uid ()
      and sm.role in ('teacher', 'admin')
  ) then
    raise exception 'Not authorized to record attendance for this school';
  end if;

  if not exists (
    select 1
    from public.students s
    where s.id = upsert_attendance_mark.student_id
      and s.school_id = upsert_attendance_mark.school_id
  ) then
    raise exception 'Student does not belong to this school';
  end if;

  insert into public.attendance (school_id, student_id, date, status)
  values (
    upsert_attendance_mark.school_id,
    upsert_attendance_mark.student_id,
    p_date,
    p_status
  )
  on conflict (school_id, student_id, date)
  do update set status = excluded.status
  returning * into result;

  return result;
end;
$$;

grant execute on function public.upsert_attendance_mark (uuid, uuid, date, text) to authenticated;
