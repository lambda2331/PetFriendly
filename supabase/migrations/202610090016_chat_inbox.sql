-- Read cursors are private membership data. Clients cannot write them directly.
create table public.conversation_reads (
  conversation_id uuid not null,
  user_id uuid not null,
  last_read_at timestamptz not null,
  last_read_id uuid not null,
  primary key (conversation_id, user_id),
  foreign key (conversation_id, user_id)
    references public.conversation_members(conversation_id, user_id) on delete cascade
);
alter table public.conversation_reads enable row level security;
revoke all on public.conversation_reads from anon, authenticated;
grant select on public.conversation_reads to authenticated;
create policy own_conversation_reads on public.conversation_reads for select
  using (user_id = private.actor() and private.member(conversation_id));

-- One latest message and a count per requested conversation, never a history dump.
create function public.chat_inbox(conversation_ids uuid[])
returns table (conversation_id uuid, body text, sender_id uuid,
  created_at timestamptz, unread_count bigint)
language plpgsql stable security definer set search_path = '' as $$
declare actor uuid := private.require_actor();
begin
  if coalesce(cardinality(conversation_ids), 0) > 100 then
    raise exception 'Request at most 100 conversations';
  end if;
  return query
    select cm.conversation_id, latest.body, latest.sender_id, latest.created_at,
      (select count(*) from public.messages m
       where m.conversation_id = cm.conversation_id and m.sender_id <> actor
         and (r.last_read_at is null or
           (m.created_at, m.id) > (r.last_read_at, r.last_read_id)))
    from public.conversation_members cm
    left join public.conversation_reads r
      on r.conversation_id = cm.conversation_id and r.user_id = actor
    left join lateral (
      select m.body, m.sender_id, m.created_at from public.messages m
      where m.conversation_id = cm.conversation_id
      order by m.created_at desc, m.id desc limit 1
    ) latest on true
    where cm.user_id = actor and cm.conversation_id = any(conversation_ids);
end $$;

-- A concrete loaded message is the cursor. A concurrent later arrival stays unread.
create function public.mark_conversation_read(conversation_in uuid, message_in uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); stamp timestamptz;
begin
  if not private.member(conversation_in) then
    raise exception 'Conversation membership required' using errcode = '42501';
  end if;
  select m.created_at into stamp from public.messages m
    where m.id = message_in and m.conversation_id = conversation_in;
  if stamp is null then raise exception 'Message not found'; end if;
  insert into public.conversation_reads(conversation_id, user_id, last_read_at, last_read_id)
    values (conversation_in, actor, stamp, message_in)
  on conflict (conversation_id, user_id) do update
    set last_read_at = excluded.last_read_at, last_read_id = excluded.last_read_id
    where (conversation_reads.last_read_at, conversation_reads.last_read_id)
      < (excluded.last_read_at, excluded.last_read_id);
end $$;
revoke all on function public.chat_inbox(uuid[]),
  public.mark_conversation_read(uuid,uuid) from public, anon;
grant execute on function public.chat_inbox(uuid[]),
  public.mark_conversation_read(uuid,uuid) to authenticated;

-- Preserve the existing export contract and its recent-auth requirement.
alter function public.export_my_data() rename to export_my_data_before_inbox;
alter function public.export_my_data_before_inbox() set schema private;
revoke all on function private.export_my_data_before_inbox() from public, anon, authenticated;
create function public.export_my_data() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); data jsonb;
begin
  data := private.export_my_data_before_inbox();
  return data || jsonb_build_object('conversation_reads',
    (select coalesce(jsonb_agg(r), '[]'::jsonb) from public.conversation_reads r
      where r.user_id = actor));
end $$;
revoke all on function public.export_my_data() from public, anon;
grant execute on function public.export_my_data() to authenticated;
