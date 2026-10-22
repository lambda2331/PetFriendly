-- Isolated PostgreSQL contract smoke fixture; not a substitute for Supabase RLS tests.
create schema private;
create role anon;
create role authenticated;
create table public.groups(id uuid primary key);
create table public.group_members(group_id uuid references public.groups, user_id uuid);
create table public.events(id uuid primary key default gen_random_uuid(), owner_id uuid,
 title text, city text, starts_at timestamptz, time_zone text,
 capacity integer not null check(capacity between 2 and 100), description text,
 latitude double precision, longitude double precision, location_label text);
create table public.walk_requests(id uuid primary key, owner_id uuid, pet_id uuid,
 city text,district text,starts_at timestamptz,duration integer,time_zone text,description text,status text);
create function private.require_actor() returns uuid language sql as $$select current_setting('test.actor')::uuid$$;
create function private.product_can(uuid,text) returns boolean language sql as $$select current_setting('test.owner')='true'$$;
create function public.create_event_at_zone(text,text,timestamptz,integer,text,text default '',uuid default null) returns uuid language plpgsql as $$
declare eid uuid;
begin
 if $3<=now() then raise exception 'Future time required'; end if;
 if $5 not in ('Europe/Minsk','Europe/Warsaw') then raise exception 'Invalid zone'; end if;
 insert into public.events(owner_id,title,city,starts_at,capacity,time_zone,description) values(private.require_actor(),$1,$2,$3,$4,$5,$6) returning id into eid;
 return eid;
end$$;
