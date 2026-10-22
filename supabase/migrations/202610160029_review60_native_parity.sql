-- Review 60 native contracts. Previous RPCs remain compatible.
alter table public.events alter column capacity drop not null;
alter table public.events add column duration integer not null default 60 check(duration between 15 and 480 and duration % 15 = 0),
  add column group_id uuid references public.groups(id) on delete set null;

create function public.create_review60_event(title_in text, city_in text,
  starts_in timestamptz, capacity_in integer, timezone_in text,
  duration_in integer default 60, group_in uuid default null,
  description_in text default '', latitude_in double precision default null,
  longitude_in double precision default null, location_label_in text default '') returns uuid
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); eid uuid;
begin
  if not private.product_can(actor,'owner') then raise exception 'Owner role required' using errcode='42501'; end if;
  if group_in is not null and not exists(select 1 from public.group_members where group_id=group_in and user_id=actor) then
    raise exception 'Community membership required' using errcode='42501'; end if;
  if duration_in is null or duration_in not between 15 and 480 or duration_in % 15 <> 0 then raise exception 'Invalid duration'; end if;
  if (latitude_in is null) <> (longitude_in is null) or
    (latitude_in is not null and not(latitude_in between -90 and 90 and longitude_in between -180 and 180)) then
    raise exception 'Invalid public meeting point'; end if;
  if latitude_in is null and coalesce(trim(location_label_in),'')<>'' then raise exception 'Label requires a public point'; end if;
  eid:=public.create_event_at_zone(title_in,city_in,starts_in,capacity_in,timezone_in,description_in);
  update public.events set duration=duration_in,group_id=group_in,
    latitude=latitude_in,longitude=longitude_in,location_label=coalesce(trim(location_label_in),'') where id=eid and owner_id=actor;
  return eid;
end $$;
revoke all on function public.create_review60_event(text,text,timestamptz,integer,text,integer,uuid,text,double precision,double precision,text) from public,anon;
grant execute on function public.create_review60_event(text,text,timestamptz,integer,text,integer,uuid,text,double precision,double precision,text) to authenticated;

-- Keep actor checks, row locking and capacity enforcement in the existing join RPC.
-- PostgreSQL's comparison with NULL permits unlimited-capacity events.

alter table public.walk_requests add column started_at timestamptz,
  add column finished_at timestamptz;
create function private.walk_lifecycle_clock() returns trigger
language plpgsql set search_path='' as $$
begin
  new.started_at:=old.started_at; new.finished_at:=old.finished_at;
  if old.status='assigned' and new.status='in_progress' then new.started_at:=clock_timestamp(); end if;
  if old.status='in_progress' and new.status='awaiting_confirmation' then new.finished_at:=clock_timestamp(); end if;
  return new;
end $$;
revoke all on function private.walk_lifecycle_clock() from public,anon,authenticated;
create trigger walk_lifecycle_clock before update on public.walk_requests
for each row execute function private.walk_lifecycle_clock();

create or replace function private.walk_card(item public.walk_requests,actor uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare helper uuid; cid uuid; own boolean:=item.owner_id=actor; participating boolean;
  owner_profile jsonb; helper_profile jsonb; pet jsonb; result jsonb; allowed_actions text[]:='{}'::text[];
begin
  select helper_id into helper from public.walk_agreements where request_id=item.id;
  participating:=own or helper=actor;
  select jsonb_build_object('id',p.id,'name',p.name,'kind',p.kind,'age',p.age,'size',p.size,
    'temperament',p.temperament) into pet from public.pets p where p.id=item.pet_id;
  if private.public_account(item.owner_id) and not private.blocked(actor,item.owner_id) then
    select jsonb_build_object('id',p.id,'display_name',p.display_name,'district',p.district,
      'rating',(select avg(r.rating) from public.walk_owner_reviews r where r.owner_id=p.id and r.published),
      'review_count',(select count(*) from public.walk_owner_reviews r where r.owner_id=p.id and r.published))
      into owner_profile from public.profiles p where p.id=item.owner_id;
  end if;
  if participating and helper is not null and private.public_account(helper)
    and not private.blocked(actor,helper) then
    select jsonb_build_object('id',p.id,'display_name',p.display_name,'district',p.district)
      into helper_profile from public.profiles p where p.id=helper;
  end if;
  if participating then
    select c.id into cid from public.conversations c
      where c.kind='walk' and c.context_id=item.id and private.member(c.id);
  end if;
  if item.status='open' then
    if own then
      allowed_actions:=array['cancel'];
      if private.product_can(actor,'owner') then allowed_actions:=allowed_actions||'assign'::text; end if;
    elsif private.public_account(item.owner_id) and not private.blocked(actor,item.owner_id) then
      if exists(select 1 from public.walk_applications a where a.request_id=item.id and a.helper_id=actor) then
        allowed_actions:=array['withdraw'];
      elsif item.starts_at>now() and private.product_can(actor,'helper') then allowed_actions:=array['apply']; end if;
    end if;
  elsif helper=actor and item.status='assigned' then allowed_actions:=array['start'];
  elsif helper=actor and item.status='in_progress' then allowed_actions:=array['finish'];
  elsif own and item.status='awaiting_confirmation' then allowed_actions:=array['confirm'];
  elsif item.status='completed' and helper is not null and helper<>item.owner_id then
    if own and private.public_account(helper) and not private.blocked(actor,helper)
      and not exists(select 1 from public.walk_reviews r where r.request_id=item.id) then
      allowed_actions:=array['review_helper'];
    elsif helper=actor and owner_profile is not null
      and not exists(select 1 from public.walk_owner_reviews r where r.request_id=item.id) then
      allowed_actions:=array['review_owner']; end if;
  end if;
  result:=jsonb_build_object('id',item.id,'owner_id',item.owner_id,'pet_id',item.pet_id,
    'city',item.city,'district',item.district,'starts_at',item.starts_at,'duration',item.duration,
    'started_at',item.started_at,'finished_at',item.finished_at,'time_zone',item.time_zone,'description',item.description,'status',item.status,
    'pet',pet,'owner',owner_profile,'helper',helper_profile,
    'my_role',case when own then 'owner' when helper=actor then 'helper'
      when exists(select 1 from public.walk_applications a where a.request_id=item.id and a.helper_id=actor)
        then 'applicant' else 'viewer' end,
    'applied',exists(select 1 from public.walk_applications a where a.request_id=item.id and a.helper_id=actor),
    'conversation_id',cid,'allowed_actions',to_jsonb(allowed_actions),
    'helper_review_written',own and exists(select 1 from public.walk_reviews r where r.request_id=item.id),
    'owner_review_written',coalesce(helper=actor,false) and exists(select 1 from public.walk_owner_reviews r where r.request_id=item.id));
  return result;
end $$;
