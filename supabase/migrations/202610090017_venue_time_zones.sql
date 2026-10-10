-- Preserve the instant and the venue's IANA zone. Never infer it from a device.
alter table public.events add column time_zone text;
alter table public.walk_requests add column time_zone text;

create function private.launch_venue_zone(city_in text) returns text
language sql immutable set search_path = '' as $$
  select case when lower(btrim(city_in)) = any(array[
    'минск','мінск','minsk','гродно','гродна','grodno','hrodna','брест','brest',
    'гомель','gomel','homiel','витебск','віцебск','vitebsk','могилёв','могилев',
    'магілёў','mogilev','mahilioŭ','бобруйск','бабруйск','bobruisk','барановичи',
    'баранавічы','baranovichi','борисов','барысаў','borisov','пинск','pinsk',
    'орша','orsha','новополоцк','наваполацк','novopolotsk','лида','ліда','lida',
    'солигорск','салігорск','soligorsk','мозырь','мазыр','mozyr','полоцк','полацк',
    'polotsk','молодечно','маладзечна','molodechno','жлобин','жлобін','zhlobin',
    'речица','рэчыца','rechitsa','слуцк','slutsk','жодино','жодзіна','zhodino',
    'кобрин','кобрын','kobrin'
  ]) then 'Europe/Minsk' end;
$$;
revoke all on function private.launch_venue_zone(text) from public, anon, authenticated;
update public.events set time_zone = private.launch_venue_zone(city);
update public.walk_requests set time_zone = private.launch_venue_zone(city);

create function private.validate_venue_zone(city_in text, zone_in text) returns void
language plpgsql set search_path = '' as $$
declare expected text := private.launch_venue_zone(city_in);
begin
  if zone_in is null or not exists(select 1 from pg_catalog.pg_timezone_names where name = zone_in)
      or (expected is not null and zone_in <> expected) then
    raise exception 'Choose the venue time zone' using errcode = '22023';
  end if;
end $$;
revoke all on function private.validate_venue_zone(text,text) from public, anon, authenticated;

-- Old clients can still create launch-market records without a new parameter.
-- Unknown legacy venue zones stay null and are shown explicitly as unknown.
create function private.venue_zone_on_write() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.time_zone is null then new.time_zone := private.launch_venue_zone(new.city); end if;
  if new.time_zone is not null then perform private.validate_venue_zone(new.city,new.time_zone); end if;
  return new;
end $$;
create trigger event_venue_zone before insert or update of city,time_zone on public.events
  for each row execute function private.venue_zone_on_write();
create trigger walk_venue_zone before insert or update of city,time_zone on public.walk_requests
  for each row execute function private.venue_zone_on_write();

create function public.create_event_at_zone(title_in text, city_in text,
  starts_in timestamptz, capacity_in integer, timezone_in text,
  description_in text default '', place_in uuid default null) returns uuid
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); eid uuid;
begin
  perform private.validate_venue_zone(city_in,timezone_in);
  eid := public.create_event(title_in,city_in,starts_in,capacity_in,description_in,place_in);
  update public.events set time_zone = timezone_in where id = eid and owner_id = actor;
  return eid;
end $$;

create function public.create_walk_at_zone(pet_in uuid, city_in text,
  starts_in timestamptz, duration_in integer, timezone_in text,
  description_in text default '', instructions_in text default '') returns uuid
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); rid uuid;
begin
  perform private.validate_venue_zone(city_in,timezone_in);
  rid := public.create_walk(pet_in,city_in,starts_in,duration_in,description_in,instructions_in);
  update public.walk_requests set time_zone = timezone_in where id = rid and owner_id = actor;
  return rid;
end $$;
revoke all on function public.create_event_at_zone(text,text,timestamptz,integer,text,text,uuid),
  public.create_walk_at_zone(uuid,text,timestamptz,integer,text,text,text) from public, anon;
grant execute on function public.create_event_at_zone(text,text,timestamptz,integer,text,text,uuid),
  public.create_walk_at_zone(uuid,text,timestamptz,integer,text,text,text) to authenticated;
