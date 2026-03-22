-- Messaging helper RPC: list potential participants for new threads

create or replace function public.list_message_participants (
  school_id uuid
)
returns table (
  user_id uuid,
  display_name text,
  role text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if school_id is null then
    raise exception 'school_id is required';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = list_message_participants.school_id
      and sm.user_id = auth.uid ()
      and sm.role in ('admin', 'teacher')
  ) then
    raise exception 'Not authorized to list message participants for this school';
  end if;

  return query
  select
    sm.user_id,
    p.display_name,
    sm.role
  from public.school_members sm
  left join public.profiles p on p.id = sm.user_id
  where sm.school_id = list_message_participants.school_id
    and sm.user_id <> auth.uid ()
  order by p.display_name asc nulls last, sm.created_at asc;
end;
$$;

grant execute on function public.list_message_participants (uuid) to authenticated;
