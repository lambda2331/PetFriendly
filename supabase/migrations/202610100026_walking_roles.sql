-- Product roles are distinct from server-controlled moderator/admin privileges.
-- Legacy accounts keep both capabilities until an explicit onboarding choice.
create table private.product_roles (
  user_id uuid primary key references public.profiles on delete cascade,
  account_role text not null default 'both' check(account_role in ('owner','helper','both')),
  active_mode text not null default 'owner' check(active_mode in ('owner','helper')),
  selected_at timestamptz,
  check(account_role = 'both' or account_role = active_mode)
);
alter table private.product_roles enable row level security;
revoke all on private.product_roles from public,anon,authenticated;
-- Serialize signup against backfill + trigger installation: no account may
-- appear between the snapshot and the trigger without a product-role row.
lock table public.profiles in share row exclusive mode;
insert into private.product_roles(user_id) select id from public.profiles;

create function private.init_product_role() returns trigger
language plpgsql security definer set search_path='' as $$
begin insert into private.product_roles(user_id) values(new.id); return new; end $$;
revoke all on function private.init_product_role() from public,anon,authenticated;
create trigger init_product_role after insert on public.profiles
for each row execute function private.init_product_role();

create function private.product_can(user_in uuid, capability_in text) returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from private.product_roles r where r.user_id=user_in
    and (r.account_role='both' or r.account_role=capability_in))
$$;
revoke all on function private.product_can(uuid,text) from public,anon,authenticated;

create function public.my_account_mode() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); r private.product_roles;
begin
  select * into strict r from private.product_roles where user_id=actor;
  return jsonb_build_object('account_role',r.account_role,'active_mode',r.active_mode,
    'needs_role_selection',r.selected_at is null,'capabilities',jsonb_build_object(
      'create_walk',private.product_can(actor,'owner'),
      'apply_walk',private.product_can(actor,'helper'),
      'create_pet',private.product_can(actor,'owner'),
      'create_community',private.product_can(actor,'owner'),
      'create_meeting',private.product_can(actor,'owner'),
      'submit_place',private.product_can(actor,'owner')));
end $$;

create function public.set_account_role(role_in text, mode_in text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); current_mode text; next_mode text;
begin
  if role_in is null or role_in not in ('owner','helper','both') then
    raise exception 'Invalid product role' using errcode='22023'; end if;
  select active_mode into current_mode from private.product_roles where user_id=actor for update;
  next_mode:=coalesce(mode_in,case when role_in='both' then current_mode else role_in end);
  if next_mode is null or next_mode not in ('owner','helper')
    or (role_in<>'both' and next_mode<>role_in) then
    raise exception 'Mode does not belong to role' using errcode='22023'; end if;
  perform private.rate_limit(actor,'product_role',20);
  update private.product_roles set account_role=role_in,active_mode=next_mode,selected_at=now()
    where user_id=actor;
  return public.my_account_mode();
end $$;

create function public.switch_account_mode(mode_in text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); r private.product_roles;
begin
  select * into strict r from private.product_roles where user_id=actor for update;
  if mode_in is null or mode_in not in ('owner','helper')
    or (r.account_role<>'both' and mode_in<>r.account_role) then
    raise exception 'Mode unavailable' using errcode='42501'; end if;
  update private.product_roles set active_mode=mode_in where user_id=actor;
  return public.my_account_mode();
end $$;

-- Gate creation, not ownership of already existing data or agreements.
create function private.owner_feature_insert() returns trigger
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.actor();
begin
  if actor is not null and not private.product_can(actor,'owner') then
    raise exception 'Owner role required' using errcode='42501'; end if;
  return new;
end $$;
revoke all on function private.owner_feature_insert() from public,anon,authenticated;
create trigger owner_walk_insert before insert on public.walk_requests
for each row execute function private.owner_feature_insert();
create trigger owner_pet_insert before insert on public.pets
for each row execute function private.owner_feature_insert();
create trigger owner_group_insert before insert on public.groups
for each row execute function private.owner_feature_insert();
create trigger owner_event_insert before insert on public.events
for each row execute function private.owner_feature_insert();
create trigger owner_submission_insert before insert on public.place_submissions
for each row execute function private.owner_feature_insert();

create or replace function public.apply_walk(request_in uuid) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests;
begin
  if not private.product_can(actor,'helper') then
    raise exception 'Helper role required' using errcode='42501'; end if;
  select * into item from public.walk_requests where id=request_in for update;
  if not found or item.status<>'open' or item.owner_id=actor
    or not private.public_account(item.owner_id) or private.blocked(actor,item.owner_id)
    or item.starts_at<=now() then raise exception 'Request unavailable' using errcode='42501'; end if;
  insert into public.walk_applications(request_id,helper_id) values(request_in,actor)
    on conflict do nothing;
  if found then perform private.notify(item.owner_id,'walk_application',request_in); end if;
end $$;

create or replace function public.assign_walk(request_in uuid, helper_in uuid) returns uuid
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); item public.walk_requests; agreement uuid;
begin
  select * into item from public.walk_requests where id=request_in for update;
  if not found or item.owner_id<>actor then
    raise exception 'Not your request' using errcode='42501'; end if;
  select id into agreement from public.walk_agreements
    where request_id=request_in and helper_id=helper_in;
  if agreement is not null then return agreement; end if;
  if not private.product_can(actor,'owner') or not private.product_can(helper_in,'helper')
    or item.status<>'open' or helper_in=actor or not private.public_account(helper_in)
    or private.blocked(actor,helper_in) or not exists(select 1 from public.walk_applications
      where request_id=request_in and helper_id=helper_in) then
    raise exception 'Assignment unavailable' using errcode='42501'; end if;
  insert into public.walk_agreements(request_id,helper_id)
    values(request_in,helper_in) returning id into agreement;
  update public.walk_requests set status='assigned' where id=request_in;
  perform private.chat('walk',request_in,array[actor,helper_in]);
  perform private.notify(helper_in,'walk_assigned',request_in);
  return agreement;
end $$;

alter table public.pets add column size text check(size in ('small','medium','large'));
alter table public.walk_requests add column district text not null default ''
  check(char_length(district)<=100);
create index walks_owner_status on public.walk_requests(owner_id,status,starts_at,id);
create index walks_city_time on public.walk_requests(city,starts_at,id) where status='open';
create index agreements_helper on public.walk_agreements(helper_id,request_id);
create index applications_helper on public.walk_applications(helper_id,request_id);

create table public.walking_helper_profiles (
  user_id uuid primary key references public.profiles on delete cascade,
  city text not null check(char_length(city) between 1 and 120),
  district text not null default '' check(char_length(district)<=100),
  introduction text not null default '' check(char_length(introduction)<=1000),
  experience text not null default '' check(char_length(experience)<=1000),
  dog_sizes text[] not null default '{}' check(cardinality(dog_sizes)<=3
    and dog_sizes <@ array['small','medium','large']::text[]),
  service_districts text[] not null default '{}' check(cardinality(service_districts)<=10),
  time_zone text not null,
  availability jsonb not null default '[]' check(jsonb_typeof(availability)='array'),
  accepting_requests boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.walking_helper_profiles enable row level security;
revoke all on public.walking_helper_profiles from public,anon,authenticated;
grant select on public.walking_helper_profiles to authenticated;

create function private.helper_profile_visible(user_in uuid) returns boolean
language sql stable security definer set search_path='' as $$
  select private.actor() is not null and private.public_account(user_in)
    and not private.blocked(private.actor(),user_in)
    and (user_in=private.actor() or private.product_can(user_in,'helper'))
$$;
revoke all on function private.helper_profile_visible(uuid) from public,anon;
grant execute on function private.helper_profile_visible(uuid) to authenticated;
create policy helper_profile_read on public.walking_helper_profiles for select
  using(private.helper_profile_visible(user_id));

create function public.save_walking_helper_profile(city_in text, time_zone_in text,
  district_in text default '', introduction_in text default '', experience_in text default '',
  dog_sizes_in text[] default '{}', service_districts_in text[] default '{}',
  availability_in jsonb default '[]', accepting_in boolean default true) returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); slot jsonb; day_in integer; start_in integer;
  end_in integer; previous_slots jsonb:='[]'::jsonb; previous jsonb;
begin
  if not private.product_can(actor,'helper') then
    raise exception 'Helper role required' using errcode='42501'; end if;
  if city_in is null or char_length(trim(city_in)) not between 1 and 120
    or time_zone_in is null or not exists(select 1 from pg_catalog.pg_timezone_names where name=time_zone_in)
    or district_in is null or char_length(district_in)>100 or introduction_in is null
    or char_length(introduction_in)>1000 or experience_in is null or char_length(experience_in)>1000
    or dog_sizes_in is null or cardinality(dog_sizes_in)>3
    or not dog_sizes_in <@ array['small','medium','large']::text[]
    or array_position(dog_sizes_in,null) is not null
    or (select count(distinct s) from unnest(dog_sizes_in) s)<>cardinality(dog_sizes_in)
    or service_districts_in is null or cardinality(service_districts_in)>10
    or exists(select 1 from unnest(service_districts_in) s where s is null or char_length(trim(s)) not between 1 and 100)
    or accepting_in is null or jsonb_typeof(availability_in) is distinct from 'array' then
    raise exception 'Invalid helper profile' using errcode='22023'; end if;
  if jsonb_array_length(availability_in)>28 then
    raise exception 'Too many availability slots' using errcode='22023'; end if;
  for slot in select value from jsonb_array_elements(availability_in) loop
    if jsonb_typeof(slot) is distinct from 'object' or not slot ?& array['day','start','end']
      or exists(select 1 from jsonb_object_keys(slot) k where k not in ('day','start','end'))
      or jsonb_typeof(slot->'day') is distinct from 'number'
      or jsonb_typeof(slot->'start') is distinct from 'number'
      or jsonb_typeof(slot->'end') is distinct from 'number'
      or coalesce(slot->>'day','') !~ '^[0-6]$'
      or coalesce(slot->>'start','') !~ '^[0-9]{1,4}$'
      or coalesce(slot->>'end','') !~ '^[0-9]{1,4}$' then
      raise exception 'Invalid availability slot' using errcode='22023'; end if;
    day_in:=(slot->>'day')::integer; start_in:=(slot->>'start')::integer;
    end_in:=(slot->>'end')::integer;
    if start_in<0 or end_in>1440 or start_in>=end_in then
      raise exception 'Invalid availability time' using errcode='22023'; end if;
    for previous in select value from jsonb_array_elements(previous_slots) loop
      if (previous->>'day')::integer=day_in and start_in<(previous->>'end')::integer
        and end_in>(previous->>'start')::integer then
        raise exception 'Overlapping availability' using errcode='22023'; end if;
    end loop;
    previous_slots:=previous_slots||jsonb_build_array(slot);
  end loop;
  insert into public.walking_helper_profiles(user_id,city,district,introduction,experience,
    dog_sizes,service_districts,time_zone,availability,accepting_requests)
  values(actor,trim(city_in),trim(district_in),trim(introduction_in),trim(experience_in),
    dog_sizes_in,service_districts_in,time_zone_in,availability_in,accepting_in)
  on conflict(user_id) do update set city=excluded.city,district=excluded.district,
    introduction=excluded.introduction,experience=excluded.experience,dog_sizes=excluded.dog_sizes,
    service_districts=excluded.service_districts,time_zone=excluded.time_zone,
    availability=excluded.availability,accepting_requests=excluded.accepting_requests,updated_at=now();
end $$;

create function public.create_walk_request(pet_in uuid,city_in text,starts_in timestamptz,
  duration_in integer,timezone_in text,district_in text default '',
  description_in text default '',instructions_in text default '') returns uuid
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); rid uuid;
begin
  if district_in is null or char_length(district_in)>100 or city_in is null
    or char_length(trim(city_in)) not between 1 and 120 or starts_in is null
    or not isfinite(starts_in) then raise exception 'Invalid request' using errcode='22023'; end if;
  rid:=public.create_walk_at_zone(pet_in,trim(city_in),starts_in,duration_in,timezone_in,
    description_in,instructions_in);
  update public.walk_requests set district=trim(district_in) where id=rid and owner_id=actor;
  return rid;
end $$;

revoke all on function public.my_account_mode(),public.set_account_role(text,text),
  public.switch_account_mode(text),public.save_walking_helper_profile(text,text,text,text,text,text[],text[],jsonb,boolean),
  public.create_walk_request(uuid,text,timestamptz,integer,text,text,text,text) from public,anon;
grant execute on function public.my_account_mode(),public.set_account_role(text,text),
  public.switch_account_mode(text),public.save_walking_helper_profile(text,text,text,text,text,text[],text[],jsonb,boolean),
  public.create_walk_request(uuid,text,timestamptz,integer,text,text,text,text) to authenticated;
