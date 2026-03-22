-- Wave 5 Track B: per-token delivery log (OneSignal responses; worker-only writes)

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.notification_events (id) on delete cascade,
  token_id uuid not null references public.device_tokens (id) on delete cascade,
  status text not null check (status in ('sent', 'failed', 'invalid_token', 'skipped')),
  provider_message_id text,
  provider_response jsonb not null default '{}'::jsonb,
  error_code text,
  error_message text,
  attempted_at timestamptz not null default now()
);

create index notification_deliveries_event_id_idx
  on public.notification_deliveries (event_id);

create index notification_deliveries_token_id_idx
  on public.notification_deliveries (token_id);

create index notification_deliveries_attempted_at_idx
  on public.notification_deliveries (attempted_at desc);

-- ---------------------------------------------------------------------------
-- Row Level Security — no app-user access
-- ---------------------------------------------------------------------------

alter table public.notification_deliveries enable row level security;
