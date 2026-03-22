-- Wave 5 Track B: OneSignal device tokens (Android active; iOS column/schema ready)
-- Users manage only their own rows; registration via upsert_device_token RPC.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  school_id uuid not null references public.schools (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  token text not null,
  device_label text,
  app_version text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint device_tokens_token_key unique (token)
);

create index device_tokens_user_school_idx
  on public.device_tokens (user_id, school_id);

create index device_tokens_last_seen_at_idx
  on public.device_tokens (last_seen_at desc);

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------

create or replace function public.tg_set_updated_at ()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger device_tokens_set_updated_at
  before update on public.device_tokens
  for each row
  execute function public.tg_set_updated_at ();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.device_tokens enable row level security;

create policy device_tokens_select_own
  on public.device_tokens
  for select
  to authenticated
  using (user_id = auth.uid ());

create policy device_tokens_insert_own
  on public.device_tokens
  for insert
  to authenticated
  with check (user_id = auth.uid ());

create policy device_tokens_update_own
  on public.device_tokens
  for update
  to authenticated
  using (user_id = auth.uid ())
  with check (user_id = auth.uid ());

create policy device_tokens_delete_own
  on public.device_tokens
  for delete
  to authenticated
  using (user_id = auth.uid ());

-- ---------------------------------------------------------------------------
-- RPC: upsert device token (SECURITY DEFINER)
-- ---------------------------------------------------------------------------

create or replace function public.upsert_device_token (
  p_school_id uuid,
  p_platform text,
  p_token text,
  p_device_label text default null,
  p_app_version text default null
)
returns public.device_tokens
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.device_tokens;
begin
  if p_school_id is null then
    raise exception 'p_school_id is required';
  end if;

  if p_token is null or length(trim(p_token)) = 0 then
    raise exception 'p_token is required';
  end if;

  if p_platform is null or p_platform not in ('ios', 'android') then
    raise exception 'p_platform must be ios or android';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = p_school_id
      and sm.user_id = auth.uid ()
  ) then
    raise exception 'Not a member of this school';
  end if;

  insert into public.device_tokens (
    user_id,
    school_id,
    platform,
    token,
    device_label,
    app_version,
    last_seen_at,
    updated_at
  )
  values (
    auth.uid (),
    p_school_id,
    p_platform,
    trim(p_token),
    p_device_label,
    p_app_version,
    now(),
    now()
  )
  on conflict (token) do update
  set
    user_id = auth.uid (),
    school_id = excluded.school_id,
    platform = excluded.platform,
    device_label = excluded.device_label,
    app_version = excluded.app_version,
    last_seen_at = now (),
    updated_at = now ()
  returning * into result;

  return result;
end;
$$;

grant execute on function public.upsert_device_token (uuid, text, text, text, text) to authenticated;
