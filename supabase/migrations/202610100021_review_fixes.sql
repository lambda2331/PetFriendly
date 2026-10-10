-- Explicit grants also work when automatic public-schema exposure is disabled.
grant select on public.chat_attachments to service_role;

-- Global revocation must stop delivery to every previously registered device.
create or replace function public.revoke_my_sessions() returns void
language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_actor(); begin
  perform private.recent_auth();
  delete from public.device_tokens where user_id=actor;
  insert into private.revoked_sessions select id,user_id from auth.sessions
    where user_id=actor on conflict do nothing;
end $$;

-- Track independently edited venue fields separately from raw OSM provenance.
-- Moderated access evidence lives in its own table and is never imported.
create table private.place_import_overrides (
  place_id uuid primary key references public.places on delete cascade,
  fields text[] not null default '{}'
);
revoke all on private.place_import_overrides from public,anon,authenticated;

-- Preserve detectable legacy edits whose current value differs from source tags.
insert into private.place_import_overrides(place_id,fields)
select id,array_remove(array[
  case when name is distinct from left(trim(coalesce(source_tags->>'name:ru',
    source_tags->>'name',source_tags->>'name:be',name)),120) then 'name' end,
  case when pet_access is distinct from case when source_tags->>'dog' in
    ('yes','no','leashed') then source_tags->>'dog' else 'unknown' end then 'pet_access' end,
  case when category is distinct from case
    when source_tags->>'leisure'='park' then 'Парк'
    when source_tags->>'leisure'='dog_park' then 'Площадка'
    when source_tags->>'amenity'='veterinary' then 'Ветклиника'
    when source_tags->>'shop'='pet' then 'Зоомагазин' else category end then 'category' end
],null) from public.places where source='osm';

create function private.track_place_overrides() returns trigger
language plpgsql security definer set search_path='' as $$
declare changed text[]; begin
  if old.source<>'osm' or current_setting('petfriendly.catalog_import',true)='on'
    then return new; end if;
  changed:=array_remove(array[
    case when new.name is distinct from old.name then 'name' end,
    case when new.category is distinct from old.category then 'category' end,
    case when new.city is distinct from old.city then 'city' end,
    case when new.latitude is distinct from old.latitude then 'latitude' end,
    case when new.longitude is distinct from old.longitude then 'longitude' end,
    case when new.pet_access is distinct from old.pet_access then 'pet_access' end
  ],null);
  if cardinality(changed)>0 then
    insert into private.place_import_overrides values(new.id,changed)
    on conflict(place_id) do update set fields=(select array_agg(distinct f)
      from unnest(private.place_import_overrides.fields||excluded.fields) f);
  end if;
  return new;
end $$;
revoke all on function private.track_place_overrides() from public,anon,authenticated;
create trigger track_place_overrides before update on public.places
for each row execute function private.track_place_overrides();

-- A valid server-held lease authorizes bounded atomic import batches. Client
-- fields cannot publish hidden venues, rewrite IDs, or overwrite staff edits.
create function public.import_city_catalog(city_in text,lease_in uuid,records_in jsonb)
returns uuid[] language plpgsql security definer set search_path='' as $$
declare r record; p public.places; protected text[]; ids uuid[]:='{}';
  previous_flag text:=current_setting('petfriendly.catalog_import',true);
begin
  if jsonb_typeof(records_in) is distinct from 'array' or jsonb_array_length(records_in)>200
    then raise exception 'Invalid import batch'; end if;
  perform 1 from private.city_catalog where city_key=lower(trim(city_in))
    and lease=lease_in and status='fetching' and updated_at>now()-interval '2 minutes' for update;
  if not found then raise exception 'Import lease expired' using errcode='42501'; end if;
  perform set_config('petfriendly.catalog_import','on',true);
  for r in select * from jsonb_to_recordset(records_in) as x(
    source_id text,name text,category text,latitude double precision,
    longitude double precision,pet_access text,source_tags jsonb,source_updated_at timestamptz
  ) order by source_id loop
    if r.source_id is null or r.source_id !~ '^(node|way|relation)/[0-9]+$'
      or nullif(trim(r.name),'') is null or char_length(r.name)>120
      or r.category is null or r.category not in('Парк','Площадка','Зоомагазин','Ветклиника')
      or r.pet_access is null or r.pet_access not in('yes','no','leashed','unknown')
      or r.latitude is null or r.latitude not between -90 and 90
      or r.longitude is null or r.longitude not between -180 and 180
      or jsonb_typeof(r.source_tags) is distinct from 'object'
      or (r.source_updated_at is not null and not isfinite(r.source_updated_at))
      then raise exception 'Invalid OSM record'; end if;
    insert into public.places(source,source_id,name,category,city,latitude,longitude,
      pet_access,source_tags,source_updated_at)
    values('osm',r.source_id,r.name,r.category,trim(city_in),r.latitude,r.longitude,
      r.pet_access,r.source_tags,r.source_updated_at) on conflict(source_id) do nothing;
    select * into p from public.places where source_id=r.source_id for update;
    if p.source<>'osm' then raise exception 'Source collision'; end if;
    select fields into protected from private.place_import_overrides where place_id=p.id;
    protected:=coalesce(protected,'{}');
    -- An older or timestamp-less response cannot regress newer source data.
    if p.source_updated_at is null or r.source_updated_at>=p.source_updated_at then
      update public.places set
        name=case when 'name'=any(protected) then p.name else r.name end,
        category=case when 'category'=any(protected) then p.category else r.category end,
        latitude=case when 'latitude'=any(protected) then p.latitude else r.latitude end,
        longitude=case when 'longitude'=any(protected) then p.longitude else r.longitude end,
        pet_access=case when 'pet_access'=any(protected) then p.pet_access else r.pet_access end,
        source_tags=r.source_tags,source_updated_at=r.source_updated_at,imported_at=now()
      where id=p.id;
    end if;
    -- Preserve the venue's original/manual city; associate overlapping catalogs.
    insert into public.city_catalog_places values(lower(trim(city_in)),p.id)
      on conflict(city_key,place_id) do nothing;
    ids:=array_append(ids,p.id);
  end loop;
  perform set_config('petfriendly.catalog_import',coalesce(previous_flag,''),true);
  return ids;
end $$;
revoke all on function public.import_city_catalog(text,uuid,jsonb) from public,anon,authenticated;
grant execute on function public.import_city_catalog(text,uuid,jsonb) to service_role;
