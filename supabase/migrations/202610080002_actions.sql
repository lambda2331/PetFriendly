create function private.chat(kind_in text, context_in uuid, users uuid[]) returns uuid language plpgsql security definer set search_path='' as $$
declare cid uuid; uid uuid;
begin
  insert into public.conversations(kind,context_id) values(kind_in,context_in) on conflict(kind,context_id) do update set kind=excluded.kind returning id into cid;
  foreach uid in array users loop insert into public.conversation_members values(cid,uid) on conflict do nothing; end loop;
  return cid;
end $$;
create function public.open_direct(target uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); context uuid;
begin
  if target=actor or not private.public_account(target) or private.blocked(actor,target) then raise exception 'Conversation unavailable' using errcode='42501'; end if;
  context:=md5(least(actor::text,target::text)||greatest(actor::text,target::text))::uuid;
  return private.chat('direct',context,array[actor,target]);
end $$;
create function public.create_event(title_in text, city_in text, starts_in timestamptz, capacity_in integer, description_in text default '', place_in uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); eid uuid;
begin
  if starts_in<=now() then raise exception 'Choose a future time'; end if;
  insert into public.events(owner_id,title,city,starts_at,capacity,description,place_id) values(actor,title_in,city_in,starts_in,capacity_in,description_in,place_in) returning id into eid;
  insert into public.event_members values(eid,actor);
  perform private.chat('event',eid,array[actor]);
  return eid;
end $$;
create function public.join_event(event_in uuid) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.events;
begin
  select * into item from public.events where id=event_in for update;
  if not found or item.cancelled or item.starts_at<=now() or private.blocked(actor,item.owner_id) then raise exception 'Event unavailable'; end if;
  if exists(select 1 from public.event_members where event_id=event_in and user_id=actor) then return; end if;
  if (select count(*) from public.event_members where event_id=event_in)>=item.capacity then raise exception 'No free places'; end if;
  insert into public.event_members values(event_in,actor);
  perform private.chat('event',event_in,array[actor]);
  perform private.notify(item.owner_id,'event_join',event_in);
end $$;
create function public.leave_event(event_in uuid) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); begin
  if exists(select 1 from public.events where id=event_in and owner_id=actor) then raise exception 'Organizer cannot leave their event'; end if;
  delete from public.event_members where event_id=event_in and user_id=actor;
  delete from public.conversation_members where user_id=actor and conversation_id in(select id from public.conversations where kind='event' and context_id=event_in);
end $$;
create function public.create_walk(pet_in uuid, city_in text, starts_in timestamptz, duration_in integer, description_in text default '', instructions_in text default '') returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); rid uuid;
begin
  if not exists(select 1 from public.pets where id=pet_in and owner_id=actor) then raise exception 'Not your pet' using errcode='42501'; end if;
  if starts_in<=now() then raise exception 'Choose a future time'; end if;
  insert into public.walk_requests(owner_id,pet_id,city,starts_at,duration,description) values(actor,pet_in,city_in,starts_in,duration_in,description_in) returning id into rid;
  insert into public.walk_details values(rid,instructions_in);
  return rid;
end $$;
create function public.apply_walk(request_in uuid) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests;
begin
  select * into item from public.walk_requests where id=request_in for update;
  if not found or item.status<>'open' or item.owner_id=actor or private.blocked(actor,item.owner_id) or item.starts_at<=now() then raise exception 'Request unavailable'; end if;
  insert into public.walk_applications(request_id,helper_id) values(request_in,actor) on conflict do nothing;
  perform private.notify(item.owner_id,'walk_application',request_in);
end $$;
create function public.withdraw_walk(request_in uuid) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); begin
  if exists(select 1 from public.walk_requests where id=request_in and status='open') then delete from public.walk_applications where request_id=request_in and helper_id=actor; end if;
end $$;
create function public.assign_walk(request_in uuid, helper_in uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests; agreement uuid;
begin
  select * into item from public.walk_requests where id=request_in for update;
  if not found or item.owner_id<>actor then raise exception 'Not your request' using errcode='42501'; end if;
  select id into agreement from public.walk_agreements where request_id=request_in and helper_id=helper_in;
  if agreement is not null then return agreement; end if;
  if item.status<>'open' or helper_in=actor or not private.public_account(helper_in) or private.blocked(actor,helper_in) or not exists(select 1 from public.walk_applications where request_id=request_in and helper_id=helper_in) then raise exception 'Assignment unavailable'; end if;
  insert into public.walk_agreements(request_id,helper_id) values(request_in,helper_in) returning id into agreement;
  update public.walk_requests set status='assigned' where id=request_in;
  perform private.chat('walk',request_in,array[actor,helper_in]);
  perform private.notify(helper_in,'walk_assigned',request_in);
  return agreement;
end $$;
create function public.advance_walk(request_in uuid, next_status text) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests; helper uuid;
begin
  select * into item from public.walk_requests where id=request_in for update;
  select helper_id into helper from public.walk_agreements where request_id=request_in;
  if (item.status='assigned' and next_status='in_progress' and helper=actor)
    or (item.status='in_progress' and next_status='awaiting_confirmation' and helper=actor)
    or (item.status='awaiting_confirmation' and next_status='completed' and item.owner_id=actor)
    or (item.status='open' and next_status='cancelled' and item.owner_id=actor) then
    update public.walk_requests set status=next_status where id=request_in;
    if helper is not null then perform private.notify(case when actor=helper then item.owner_id else helper end,'walk_status',request_in); end if;
  else raise exception 'Transition not allowed' using errcode='42501'; end if;
end $$;
create function public.review_walk(request_in uuid, rating_in integer, body_in text default '') returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests; helper uuid;
begin
  select * into item from public.walk_requests where id=request_in;
  select helper_id into helper from public.walk_agreements where request_id=request_in;
  if item.owner_id<>actor or item.status<>'completed' or helper is null or helper=actor then raise exception 'Review not allowed' using errcode='42501'; end if;
  insert into public.walk_reviews(request_id,author_id,helper_id,rating,body) values(request_in,actor,helper,rating_in,body_in);
end $$;
create function public.send_message(conversation_in uuid, client_id uuid, body_in text) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.conversations; mid uuid; member uuid;
begin
  if not private.member(conversation_in) then raise exception 'Not a conversation member' using errcode='42501'; end if;
  perform private.rate_limit(actor,'message',30);
  select * into item from public.conversations where id=conversation_in;
  if item.kind in('direct','walk') and exists(select 1 from public.conversation_members where conversation_id=conversation_in and user_id<>actor and private.blocked(actor,user_id)) then raise exception 'Messaging blocked' using errcode='42501'; end if;
  select id into mid from public.messages where sender_id=actor and client_message_id=client_id;
  if mid is not null then
    if not exists(select 1 from public.messages where id=mid and conversation_id=conversation_in and body=body_in) then raise exception 'Idempotency key conflict'; end if;
    return mid;
  end if;
  insert into public.messages(conversation_id,sender_id,client_message_id,body) values(conversation_in,actor,client_id,body_in) returning id into mid;
  for member in select user_id from public.conversation_members where conversation_id=conversation_in and user_id<>actor loop perform private.notify(member,'message',conversation_in); end loop;
  return mid;
end $$;
create function public.revoke_my_sessions() returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); begin
  perform private.recent_auth();
  insert into private.revoked_sessions select id,user_id from auth.sessions where user_id=actor on conflict do nothing;
end $$;
create function public.request_account_deletion() returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); begin
  perform private.recent_auth();
  update private.accounts set deletion_requested_at=now() where id=actor;
  insert into private.revoked_sessions select id,user_id from auth.sessions where user_id=actor on conflict do nothing;
end $$;
create function public.export_my_data() returns jsonb language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); data jsonb; begin
  perform private.recent_auth();
  select jsonb_build_object('profile',(select to_jsonb(p) from public.profiles p where id=actor),'pets',(select coalesce(jsonb_agg(p),'[]') from public.pets p where owner_id=actor),'walk_requests',(select coalesce(jsonb_agg(p),'[]') from public.walk_requests p where owner_id=actor),'messages',(select coalesce(jsonb_agg(m),'[]') from public.messages m where sender_id=actor),'reviews',(select coalesce(jsonb_agg(r),'[]') from public.walk_reviews r where author_id=actor)) into data;
  return data;
end $$;
create view public.helper_ratings with (security_invoker=true) as select p.id,coalesce(r.review_count,0) as review_count,r.rating,coalesce(a.completed,0) as completed from public.profiles p left join(select helper_id,count(*) as review_count,avg(rating)::numeric as rating from public.walk_reviews where published group by helper_id) r on r.helper_id=p.id left join(select a.helper_id,count(*) as completed from public.walk_agreements a join public.walk_requests w on w.id=a.request_id where w.status='completed' group by a.helper_id) a on a.helper_id=p.id;
grant select on public.helper_ratings to authenticated;
-- Restrict helper execution and public RPC grants explicitly.
revoke all on all functions in schema private from public;
grant execute on function private.actor(),private.blocked(uuid,uuid),private.public_account(uuid),private.member(uuid) to authenticated;
do $$ declare f record; begin for f in select p.oid::regprocedure::text as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' loop execute 'revoke all on function '||f.signature||' from public,anon'; execute 'grant execute on function '||f.signature||' to authenticated'; end loop; end $$;
-- Notifications carry no private body. Realtime emits only non-sensitive IDs;
-- messages are fetched through RLS after each change and after reconnect.
alter publication supabase_realtime add table public.notifications;
