-- Public meeting venues chosen by the organizer, not user/device coordinates.
alter table public.events add column latitude double precision,
  add column longitude double precision,
  add column location_label text not null default '' check(char_length(location_label) <= 160),
  add constraint event_location_pair check (
    (latitude is null and longitude is null) or
    (latitude is not null and longitude is not null and
     latitude between -90 and 90 and longitude between -180 and 180)
  );

create function public.create_event_at_location(title_in text, city_in text,
  starts_in timestamptz, capacity_in integer, timezone_in text,
  latitude_in double precision, longitude_in double precision,
  location_label_in text default '', description_in text default '') returns uuid
language plpgsql security definer set search_path = '' as $$
declare actor uuid := private.require_actor(); eid uuid;
begin
  if latitude_in is null or longitude_in is null or
      not (latitude_in between -90 and 90 and longitude_in between -180 and 180) then
    raise exception 'Choose a valid public meeting point';
  end if;
  eid := public.create_event_at_zone(title_in,city_in,starts_in,capacity_in,
    timezone_in,description_in);
  update public.events set latitude = latitude_in, longitude = longitude_in,
    location_label = coalesce(trim(location_label_in),'') where id = eid and owner_id = actor;
  return eid;
end $$;
revoke all on function public.create_event_at_location(text,text,timestamptz,integer,text,double precision,double precision,text,text) from public, anon;
grant execute on function public.create_event_at_location(text,text,timestamptz,integer,text,double precision,double precision,text,text) to authenticated;
