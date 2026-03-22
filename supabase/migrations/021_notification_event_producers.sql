-- Wire notification_events producers into existing RPCs (OneSignal worker consumes queue)

-- ---------------------------------------------------------------------------
-- send_message — notify other thread participants (migration 015)
-- ---------------------------------------------------------------------------

create or replace function public.send_message (
  thread_id uuid,
  body text
)
returns public.thread_messages
language plpgsql
security definer
set search_path = public
as $$
declare
  new_message public.thread_messages;
  sender_name text;
begin
  if thread_id is null then
    raise exception 'thread_id is required';
  end if;

  if body is null or length(trim(body)) = 0 then
    raise exception 'body is required';
  end if;

  if not public.is_thread_participant (send_message.thread_id, auth.uid ()) then
    raise exception 'Not authorized to send messages in this thread';
  end if;

  insert into public.thread_messages (thread_id, sender_id, body)
  values (send_message.thread_id, auth.uid (), trim(send_message.body))
  returning * into new_message;

  sender_name := coalesce(
    (select p.display_name from public.profiles p where p.id = auth.uid ()),
    'Someone'
  );

  insert into public.notification_events (
    school_id,
    target_user_id,
    event_type,
    entity_table,
    entity_id,
    title,
    body,
    dedupe_key
  )
  select
    mt.school_id,
    tp.user_id,
    'message_created',
    'thread_messages',
    new_message.id,
    sender_name || ' sent a message',
    left(new_message.body, 200),
    'message_created:' || new_message.id::text || ':' || tp.user_id::text
  from public.message_threads mt
  join public.thread_participants tp on tp.thread_id = mt.id
  where mt.id = new_message.thread_id
    and tp.user_id <> auth.uid ()
  on conflict (dedupe_key) where (dedupe_key is not null) do nothing;

  return new_message;
end;
$$;

-- ---------------------------------------------------------------------------
-- post_announcement — notify all school members except poster (migration 008)
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

  insert into public.notification_events (
    school_id,
    target_user_id,
    event_type,
    entity_table,
    entity_id,
    title,
    body,
    dedupe_key
  )
  select
    sm.school_id,
    sm.user_id,
    'announcement_posted',
    'announcements',
    result.id,
    'New announcement',
    left(coalesce(result.body, ''), 200),
    'announcement_posted:' || result.id::text || ':' || sm.user_id::text
  from public.school_members sm
  where sm.school_id = result.school_id
    and sm.user_id <> auth.uid ()
  on conflict (dedupe_key) where (dedupe_key is not null) do nothing;

  return result;
end;
$$;

-- ---------------------------------------------------------------------------
-- upsert_attendance_mark — notify linked parents for absent/late only (migration 004 + 005)
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

  if p_status is null or p_status not in ('present', 'absent', 'late') then
    raise exception 'p_status must be one of: present, absent, late';
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
  values (upsert_attendance_mark.school_id, upsert_attendance_mark.student_id, p_date, p_status)
  on conflict (school_id, student_id, date)
  do update set status = excluded.status
  returning * into result;

  insert into public.notification_events (
    school_id,
    target_user_id,
    event_type,
    entity_table,
    entity_id,
    title,
    body,
    dedupe_key
  )
  select
    result.school_id,
    sp.parent_user_id,
    'attendance_marked',
    'attendance_marks',
    result.id,
    'Attendance update',
    coalesce(st.display_name, 'Student') || ' was marked ' || result.status,
    'attendance_marked:' || result.id::text || ':' || sp.parent_user_id::text
  from public.student_parents sp
  join public.students st on st.id = sp.student_id and st.school_id = result.school_id
  where sp.student_id = result.student_id
    and sp.school_id = result.school_id
    and sp.parent_user_id <> auth.uid ()
    and result.status in ('absent', 'late')
  on conflict (dedupe_key) where (dedupe_key is not null) do nothing;

  return result;
end;
$$;
