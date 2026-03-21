-- Students: admin write policies + add_student RPC (pattern: create_school_with_admin in 001_baseline.sql)

-- ---------------------------------------------------------------------------
-- RLS write policies — school admins only
-- ---------------------------------------------------------------------------

create policy students_insert_admin
  on public.students
  for insert
  to authenticated
  with check (
    school_id in (select public.user_school_ids ())
    and exists (
      select 1
      from public.school_members sm
      where sm.school_id = school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  );

create policy students_update_admin
  on public.students
  for update
  to authenticated
  using (
    school_id in (select public.user_school_ids ())
    and exists (
      select 1
      from public.school_members sm
      where sm.school_id = school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  )
  with check (
    school_id in (select public.user_school_ids ())
    and exists (
      select 1
      from public.school_members sm
      where sm.school_id = school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  );

create policy students_delete_admin
  on public.students
  for delete
  to authenticated
  using (
    school_id in (select public.user_school_ids ())
    and exists (
      select 1
      from public.school_members sm
      where sm.school_id = school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- RPC: atomic insert with admin check (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

create or replace function public.add_student (
  school_id uuid,
  display_name text,
  homeroom_label text
)
returns public.students
language plpgsql
security definer
set search_path = public
as $$
declare
  new_row public.students;
begin
  if school_id is null then
    raise exception 'school_id required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = add_student.school_id
      and sm.user_id = auth.uid ()
      and sm.role = 'admin'
  ) then
    raise exception 'Not authorized to add students for this school';
  end if;

  insert into public.students (school_id, display_name, homeroom_label)
  values (add_student.school_id, add_student.display_name, add_student.homeroom_label)
  returning * into new_row;

  return new_row;
end;
$$;

grant execute on function public.add_student (uuid, text, text) to authenticated;
