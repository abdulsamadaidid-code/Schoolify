-- Wave 5 Track B: notification event queue (OneSignal worker consumes; no direct app writes)

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table public.notification_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  target_user_id uuid not null references auth.users (id) on delete cascade,
  event_type text not null,
  entity_table text,
  entity_id uuid,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'sent', 'failed', 'discarded')),
  scheduled_for timestamptz not null default now(),
  attempt_count int not null default 0,
  last_error text,
  dedupe_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  processed_at timestamptz
);

create unique index notification_events_dedupe_key_uidx
  on public.notification_events (dedupe_key)
  where dedupe_key is not null;

create index notification_events_worker_pickup_idx
  on public.notification_events (status, scheduled_for, created_at);

create index notification_events_target_user_created_idx
  on public.notification_events (target_user_id, created_at desc);

create trigger notification_events_set_updated_at
  before update on public.notification_events
  for each row
  execute function public.tg_set_updated_at ();

-- ---------------------------------------------------------------------------
-- Row Level Security — authenticated clients have no direct access
-- (Edge Function / service role bypasses RLS.)
-- ---------------------------------------------------------------------------

alter table public.notification_events enable row level security;
