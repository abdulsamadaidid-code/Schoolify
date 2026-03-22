-- Grade items: teacher/admin write policies + controlled RPCs

-- ---------------------------------------------------------------------------
-- Unique key: ensures upsert_grade_item is idempotent (no duplicate rows)
-- ---------------------------------------------------------------------------

alter table public.grade_items
  add constraint grade_items_unique_per_assignment
  unique (school_id, student_id, course_label, assignment_label);

-- ---------------------------------------------------------------------------
-- RLS write policies — teacher/admin only in-tenant
-- ---------------------------------------------------------------------------

create policy grade_items_insert_teacher_admin
  on public.grade_items
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = grade_items.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('teacher', 'admin')
    )
  );

create policy grade_items_update_teacher_admin
  on public.grade_items
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = grade_items.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('teacher', 'admin')
    )
  )
  with check (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = grade_items.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('teacher', 'admin')
    )
  );

create policy grade_items_delete_teacher_admin
  on public.grade_items
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = grade_items.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('teacher', 'admin')
    )
  );

-- ---------------------------------------------------------------------------
-- RPC: upsert grade item (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

create or replace function public.upsert_grade_item (
  school_id uuid,
  student_id uuid,
  course_label text,
  assignment_label text,
  score_label text
)
returns public.grade_items
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.grade_items;
begin
  if school_id is null or student_id is null then
    raise exception 'school_id and student_id are required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = upsert_grade_item.school_id
      and sm.user_id = auth.uid ()
      and sm.role in ('teacher', 'admin')
  ) then
    raise exception 'Not authorized to write grade items for this school';
  end if;

  if not exists (
    select 1
    from public.students s
    where s.id = upsert_grade_item.student_id
      and s.school_id = upsert_grade_item.school_id
  ) then
    raise exception 'Student does not belong to this school';
  end if;

  update public.grade_items gi
  set
    score_label = upsert_grade_item.score_label
  where gi.school_id = upsert_grade_item.school_id
    and gi.student_id = upsert_grade_item.student_id
    and gi.course_label = upsert_grade_item.course_label
    and gi.assignment_label = upsert_grade_item.assignment_label
  returning * into result;

  if result.id is null then
    insert into public.grade_items (
      school_id,
      student_id,
      teacher_id,
      course_label,
      assignment_label,
      score_label
    )
    values (
      upsert_grade_item.school_id,
      upsert_grade_item.student_id,
      auth.uid (),
      upsert_grade_item.course_label,
      upsert_grade_item.assignment_label,
      upsert_grade_item.score_label
    )
    returning * into result;
  end if;

  return result;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: delete grade item (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

create or replace function public.delete_grade_item (
  grade_item_id uuid,
  school_id uuid
)
returns public.grade_items
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_row public.grade_items;
begin
  if grade_item_id is null or school_id is null then
    raise exception 'grade_item_id and school_id are required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = delete_grade_item.school_id
      and sm.user_id = auth.uid ()
      and sm.role in ('teacher', 'admin')
  ) then
    raise exception 'Not authorized to delete grade items for this school';
  end if;

  delete from public.grade_items gi
  where gi.id = delete_grade_item.grade_item_id
    and gi.school_id = delete_grade_item.school_id
  returning * into deleted_row;

  if deleted_row.id is null then
    raise exception 'Grade item not found for this school';
  end if;

  return deleted_row;
end;
$$;

grant execute on function public.upsert_grade_item (uuid, uuid, text, text, text) to authenticated;
grant execute on function public.delete_grade_item (uuid, uuid) to authenticated;
