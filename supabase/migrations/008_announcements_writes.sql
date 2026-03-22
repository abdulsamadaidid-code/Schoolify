-- Announcements: teacher/admin post + admin delete

-- ---------------------------------------------------------------------------
-- RLS write policies
-- ---------------------------------------------------------------------------

create policy announcements_insert_teacher_admin
  on public.announcements
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = announcements.school_id
        and sm.user_id = auth.uid ()
        and sm.role in ('teacher', 'admin')
    )
  );

create policy announcements_delete_admin
  on public.announcements
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.school_members sm
      where sm.school_id = announcements.school_id
        and sm.user_id = auth.uid ()
        and sm.role = 'admin'
    )
  );

-- ---------------------------------------------------------------------------
-- RPC: post announcement (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

create or replace function public.post_announcement (
  school_id uuid,
  title text,
  body text
)
returns public.announcements
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.announcements;
begin
  if school_id is null then
    raise exception 'school_id is required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = post_announcement.school_id
      and sm.user_id = auth.uid ()
      and sm.role in ('teacher', 'admin')
  ) then
    raise exception 'Not authorized to post announcements for this school';
  end if;

  insert into public.announcements (school_id, title, body, posted_at)
  values (post_announcement.school_id, post_announcement.title, post_announcement.body, now())
  returning * into result;

  return result;
end;
$$;

grant execute on function public.post_announcement (uuid, text, text) to authenticated;
