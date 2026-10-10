-- Hide imported eateries; community additions and existing reviews stay intact.
update public.places set published=false where source='osm' and category in ('Кафе','Ресторан');
create index if not exists places_city_id on public.places(city,id) where published;
create table private.city_catalog (
 city_key text primary key, city text not null, status text not null check(status in ('fetching','ready','error')),
 lease uuid not null, updated_at timestamptz not null default now()
);
create table private.catalog_import_gate (id boolean primary key default true check(id),requested_at timestamptz not null);
insert into private.catalog_import_gate values(true,now()-interval '1 day');
create table private.catalog_requests (
 user_id uuid primary key references auth.users on delete cascade,
 requested_at timestamptz not null default now()
);
revoke all on private.city_catalog,private.catalog_requests,private.catalog_import_gate from public,anon,authenticated;
create table public.city_catalog_places (
 city_key text not null, place_id uuid not null references public.places on delete cascade,
 primary key(city_key,place_id)
);
alter table public.city_catalog_places enable row level security;
create policy city_catalog_read on public.city_catalog_places for select using(exists(select 1 from public.places p where p.id=place_id and p.published));
revoke all on public.city_catalog_places from anon,authenticated;
grant select on public.city_catalog_places to anon,authenticated;
grant all on public.city_catalog_places to service_role;
-- Only Edge Functions can claim imports; authenticated clients cannot fake a result.
create function public.claim_city_catalog(user_in uuid,city_in text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare item private.city_catalog; key_in text:=lower(trim(city_in)); lease_in uuid:=gen_random_uuid();begin
 if nullif(key_in,'') is null or char_length(key_in)>120 then raise exception 'Invalid city';end if;
 perform pg_advisory_xact_lock(hashtextextended('petfriendly-catalog-global',0));
 select * into item from private.city_catalog where city_key=key_in;
 if item.status='ready' and item.updated_at>now()-interval '7 days' then return jsonb_build_object('status','ready','city',item.city);end if;
 if item.status='fetching' and item.updated_at>now()-interval '2 minutes' then return jsonb_build_object('status','busy');end if;
 if item.status='error' and item.updated_at>now()-interval '1 minute' then return jsonb_build_object('status','busy');end if;
 update private.catalog_import_gate set requested_at=now() where id and requested_at<now()-interval '2 seconds';
 if not found then return jsonb_build_object('status','busy');end if;
 insert into private.catalog_requests(user_id) values(user_in) on conflict(user_id) do update set requested_at=now() where private.catalog_requests.requested_at<now()-interval '30 seconds';
 if not found then return jsonb_build_object('status','busy');end if;
 insert into private.city_catalog(city_key,city,status,lease) values(key_in,trim(city_in),'fetching',lease_in)
 on conflict(city_key) do update set city=excluded.city,status='fetching',lease=excluded.lease,updated_at=now();
 return jsonb_build_object('status','fetch','lease',lease_in,'city',trim(city_in));
end $$;
create function public.finish_city_catalog(city_in text,lease_in uuid,success_in boolean) returns void
language sql security definer set search_path='' as $$
 update private.city_catalog set status=case when success_in then 'ready' else 'error' end,updated_at=now() where city_key=lower(trim(city_in)) and lease=lease_in;
$$;
revoke all on function public.claim_city_catalog(uuid,text),public.finish_city_catalog(text,uuid,boolean) from public,anon,authenticated;
grant execute on function public.claim_city_catalog(uuid,text),public.finish_city_catalog(text,uuid,boolean) to service_role;
create function public.catalog_actor() returns uuid language sql stable security definer set search_path='' as $$ select private.require_actor(); $$;
revoke all on function public.catalog_actor() from public,anon;
grant execute on function public.catalog_actor() to authenticated;
