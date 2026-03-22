-- Admin member role update RPC

create or replace function public.update_member_role (
  school_id uuid,
  profile_id uuid,
  new_role text
)
returns public.school_members
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_row public.school_members;
begin
  if school_id is null or profile_id is null then
    raise exception 'school_id and profile_id are required';
  end if;

  if new_role is null or new_role not in ('admin', 'teacher', 'parent') then
    raise exception 'new_role must be one of: admin, teacher, parent';
  end if;

  if not exists (
    select 1
    from public.school_members sm
    where sm.school_id = update_member_role.school_id
      and sm.user_id = auth.uid ()
      and sm.role = 'admin'
  ) then
    raise exception 'Not authorized to update member roles for this school';
  end if;

  if profile_id = auth.uid () then
    raise exception 'Admin cannot change own role';
  end if;

  update public.school_members sm
  set role = update_member_role.new_role
  where sm.school_id = update_member_role.school_id
    and sm.user_id = update_member_role.profile_id
  returning * into updated_row;

  if updated_row.id is null then
    raise exception 'Member not found for this school';
  end if;

  return updated_row;
end;
$$;

grant execute on function public.update_member_role (uuid, uuid, text) to authenticated;
