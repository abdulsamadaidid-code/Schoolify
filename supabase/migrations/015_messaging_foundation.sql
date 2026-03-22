-- Messaging foundation: threads, participants, messages, RLS, realtime, and RPCs

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.message_threads (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  subject text not null,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now()
);

create table if not exists public.thread_participants (
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table if not exists public.thread_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  sender_id uuid not null references public.profiles (id),
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists thread_participants_user_id_idx
  on public.thread_participants (user_id);

create index if not exists thread_messages_thread_created_at_idx
  on public.thread_messages (thread_id, created_at);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.message_threads enable row level security;
alter table public.thread_participants enable row level security;
alter table public.thread_messages enable row level security;

-- ---------------------------------------------------------------------------
-- Helpers for RLS and RPC checks
-- ---------------------------------------------------------------------------

create or replace function public.is_thread_participant (
  p_thread_id uuid,
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.thread_participants tp
    where tp.thread_id = p_thread_id
      and tp.user_id = p_user_id
  );
$$;

grant execute on function public.is_thread_participant (uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Policies
-- ---------------------------------------------------------------------------

create policy message_threads_select_participants_in_school
  on public.message_threads
  for select
  to authenticated
  using (
    school_id in (select public.user_school_ids ())
    and public.is_thread_participant (id, auth.uid ())
  );

create policy thread_participants_select_same_thread_participants
  on public.thread_participants
  for select
  to authenticated
  using (public.is_thread_participant (thread_id, auth.uid ()));

create policy thread_messages_select_participants_only
  on public.thread_messages
  for select
  to authenticated
  using (public.is_thread_participant (thread_id, auth.uid ()));

create policy thread_messages_insert_participants_only
  on public.thread_messages
  for insert
  to authenticated
  with check (
    public.is_thread_participant (thread_id, auth.uid ())
    and sender_id = auth.uid ()
  );

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'thread_messages'
  ) then
    execute 'alter publication supabase_realtime add table public.thread_messages';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: create_message_thread (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

create or replace function public.create_message_thread (
  school_id uuid,
  subject text,
  participant_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_thread_id uuid;
begin
  if school_id is null then
    raise exception 'school_id is required';
  end if;

  if subject is null or length(trim(subject)) = 0 then
    raise exception 'subject is required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = create_message_thread.school_id
      and sm.user_id = auth.uid ()
      and sm.role in ('admin', 'teacher')
  ) then
    raise exception 'Not authorized to create threads for this school';
  end if;

  if exists (
    select 1
    from (
      select distinct pid
      from unnest(coalesce(create_message_thread.participant_ids, '{}'::uuid[])) as p(pid)
      where pid is not null
    ) participants
    where not exists (
      select 1
      from public.school_members sm
      where sm.school_id = create_message_thread.school_id
        and sm.user_id = participants.pid
    )
  ) then
    raise exception 'All participants must be members of the same school';
  end if;

  insert into public.message_threads (school_id, subject, created_by)
  values (create_message_thread.school_id, trim(create_message_thread.subject), auth.uid ())
  returning id into new_thread_id;

  insert into public.thread_participants (thread_id, user_id)
  select
    new_thread_id,
    all_participants.pid
  from (
    select distinct pid
    from (
      select unnest(coalesce(create_message_thread.participant_ids, '{}'::uuid[])) as pid
      union all
      select auth.uid () as pid
    ) raw_participants
    where pid is not null
  ) all_participants;

  return new_thread_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- RPC: send_message (SECURITY DEFINER)
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

  return new_message;
end;
$$;

grant execute on function public.create_message_thread (uuid, text, uuid[]) to authenticated;
grant execute on function public.send_message (uuid, text) to authenticated;
