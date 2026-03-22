-- Atomic batch claim for send_push_notifications Edge Function (FOR UPDATE SKIP LOCKED)

create or replace function public.claim_notification_events_batch (p_batch_size int default 50)
returns setof public.notification_events
language plpgsql
security definer
set search_path = public
as $$
declare
  v_limit int;
  v_max_attempts int := 5;
begin
  v_limit := greatest(1, least(coalesce(p_batch_size, 50), 200));
  return query
  with cte as (
    select ne.id
    from public.notification_events ne
    where ne.status = 'pending'
      and ne.scheduled_for <= now()
      and ne.attempt_count < v_max_attempts
    order by ne.scheduled_for asc, ne.created_at asc
    for update skip locked
    limit v_limit
  )
  update public.notification_events e
  set
    status = 'processing'::text,
    attempt_count = e.attempt_count + 1,
    updated_at = now()
  from cte
  where e.id = cte.id
  returning e.*;
end;
$$;

revoke all on function public.claim_notification_events_batch (int) from public;
grant execute on function public.claim_notification_events_batch (int) to service_role;
